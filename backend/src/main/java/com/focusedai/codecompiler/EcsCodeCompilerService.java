package com.focusedai.codecompiler;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.multipart.MultipartFile;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.services.ecs.EcsClient;
import software.amazon.awssdk.services.ecs.model.*;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

import java.io.IOException;
import java.time.Instant;
import java.util.*;
import java.util.concurrent.TimeUnit;

@Service
public class EcsCodeCompilerService {

    private final EcsClient ecsClient;
    private final S3Client s3Client;

    @Value("${aws.ecs.cluster}")
    private String ecsCluster;

    @Value("${aws.s3.bucket}")
    private String s3Bucket;

    @Value("${aws.vpc.subnets}")
    private String vpcSubnets;

    @Value("${aws.vpc.security-group}")
    private String securityGroup;

    @Value("${ecs.taskdef.java:java-compiler-task}")
    private String javaTaskDef;

    @Value("${ecs.taskdef.javascript:javascript-compiler-task}")
    private String javascriptTaskDef;

    @Value("${ecs.taskdef.python:python-compiler-task}")
    private String pythonTaskDef;

    @Value("${ecs.taskdef.cpp:cpp-compiler-task}")
    private String cppTaskDef;

    public EcsCodeCompilerService() {
        this.ecsClient = EcsClient.builder().build();
        this.s3Client = S3Client.builder().build();
    }

    public CompilationResult executeCode(String language, String mainClassName, List<MultipartFile> files) {
        String sessionId = generateSessionId();
        String inputPrefix = "temp/input/" + sessionId + "/";
        String outputKey = "temp/output/" + sessionId + "/result.json";

        try {
            // Step 1: Upload source files to S3
            uploadFilesToS3(files, inputPrefix);

            // Step 2: Run ECS task
            String taskArn = runCompilationTask(language, inputPrefix, outputKey);

            // Step 3: Wait for task completion
            waitForTaskCompletion(taskArn);

            // Step 4: Retrieve results from S3
            return getCompilationResult(outputKey);

        } catch (Exception e) {
            return CompilationResult.builder()
                    .success(false)
                    .output("")
                    .error("Internal error: " + e.getMessage())
                    .build();
        } finally {
            // Clean up S3 files (optional - lifecycle policy will handle this)
            cleanupS3Files(inputPrefix, outputKey);
        }
    }

    private void uploadFilesToS3(List<MultipartFile> files, String prefix) throws IOException {
        for (MultipartFile file : files) {
            if (file.isEmpty()) {
                throw new IllegalArgumentException("Empty file detected: " + file.getOriginalFilename());
            }

            String key = prefix + file.getOriginalFilename();
            PutObjectRequest putRequest = PutObjectRequest.builder()
                    .bucket(s3Bucket)
                    .key(key)
                    .contentType("text/plain")
                    .build();

            s3Client.putObject(putRequest, RequestBody.fromBytes(file.getBytes()));
        }
    }

    private String runCompilationTask(String language, String inputPrefix, String outputKey) {
        String taskDefinition = getTaskDefinitionForLanguage(language);
        
        // Prepare environment variables
        Map<String, String> environment = Map.of(
                "LANGUAGE", language.toLowerCase(),
                "S3_BUCKET", s3Bucket,
                "S3_INPUT_PREFIX", inputPrefix,
                "S3_OUTPUT_KEY", outputKey
        );

        // Convert environment map to ECS format
        List<KeyValuePair> envVars = environment.entrySet().stream()
                .map(entry -> KeyValuePair.builder()
                        .name(entry.getKey())
                        .value(entry.getValue())
                        .build())
                .toList();

        // Create container override
        ContainerOverride containerOverride = ContainerOverride.builder()
                .name(language + "-compiler")
                .environment(envVars)
                .build();

        TaskOverride taskOverride = TaskOverride.builder()
                .containerOverrides(containerOverride)
                .build();

        // Prepare network configuration
        List<String> subnetList = Arrays.asList(vpcSubnets.split(","));
        
        AwsVpcConfiguration vpcConfig = AwsVpcConfiguration.builder()
                .subnets(subnetList)
                .securityGroups(securityGroup)
                .assignPublicIp(AssignPublicIp.ENABLED)  // Needed for ECR pulls
                .build();

        NetworkConfiguration networkConfig = NetworkConfiguration.builder()
                .awsvpcConfiguration(vpcConfig)
                .build();

        // Run the task
        RunTaskRequest runRequest = RunTaskRequest.builder()
                .cluster(ecsCluster)
                .taskDefinition(taskDefinition)
                .launchType(LaunchType.FARGATE)
                .networkConfiguration(networkConfig)
                .overrides(taskOverride)
                .build();

        RunTaskResponse response = ecsClient.runTask(runRequest);
        
        if (response.failures().size() > 0) {
            String failureReason = response.failures().get(0).reason();
            throw new RuntimeException("Failed to start ECS task: " + failureReason);
        }

        return response.tasks().get(0).taskArn();
    }

    private void waitForTaskCompletion(String taskArn) {
        int maxWaitTime = 300; // 5 minutes
        int pollInterval = 5;  // 5 seconds
        int waited = 0;

        while (waited < maxWaitTime) {
            DescribeTasksRequest request = DescribeTasksRequest.builder()
                    .cluster(ecsCluster)
                    .tasks(taskArn)
                    .build();

            DescribeTasksResponse response = ecsClient.describeTasks(request);
            
            if (response.tasks().isEmpty()) {
                throw new RuntimeException("Task not found: " + taskArn);
            }

            Task task = response.tasks().get(0);
            String status = task.lastStatus();

            if ("STOPPED".equals(status)) {
                // Task completed
                return;
            }

            // Wait before polling again
            try {
                TimeUnit.SECONDS.sleep(pollInterval);
                waited += pollInterval;
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                throw new RuntimeException("Interrupted while waiting for task completion");
            }
        }

        // Task didn't complete in time
        stopTask(taskArn);
        throw new RuntimeException("Task execution timed out");
    }

    private void stopTask(String taskArn) {
        try {
            StopTaskRequest stopRequest = StopTaskRequest.builder()
                    .cluster(ecsCluster)
                    .task(taskArn)
                    .reason("Timeout")
                    .build();
            
            ecsClient.stopTask(stopRequest);
        } catch (Exception e) {
            // Log error but don't fail the main operation
            System.err.println("Failed to stop task: " + e.getMessage());
        }
    }

    private CompilationResult getCompilationResult(String outputKey) {
        try {
            GetObjectRequest getRequest = GetObjectRequest.builder()
                    .bucket(s3Bucket)
                    .key(outputKey)
                    .build();

            String resultJson = s3Client.getObjectAsBytes(getRequest).asUtf8String();
            
            // Parse JSON result (you might want to use a JSON library like Jackson)
            return parseCompilationResult(resultJson);
            
        } catch (Exception e) {
            return CompilationResult.builder()
                    .success(false)
                    .output("")
                    .error("Failed to retrieve compilation results: " + e.getMessage())
                    .build();
        }
    }

    private CompilationResult parseCompilationResult(String json) {
        // Simple JSON parsing - you might want to use Jackson ObjectMapper
        try {
            boolean success = json.contains("\"success\": true");
            
            String output = extractJsonField(json, "output");
            String error = extractJsonField(json, "error");
            
            return CompilationResult.builder()
                    .success(success)
                    .output(output)
                    .error(error)
                    .build();
                    
        } catch (Exception e) {
            return CompilationResult.builder()
                    .success(false)
                    .output("")
                    .error("Failed to parse compilation results")
                    .build();
        }
    }

    private String extractJsonField(String json, String fieldName) {
        try {
            String pattern = "\"" + fieldName + "\": \"";
            int startIndex = json.indexOf(pattern);
            if (startIndex == -1) return "";
            
            startIndex += pattern.length();
            int endIndex = json.indexOf("\"", startIndex);
            if (endIndex == -1) return "";
            
            return json.substring(startIndex, endIndex)
                    .replace("\\n", "\n")
                    .replace("\\t", "\t")
                    .replace("\\\"", "\"");
        } catch (Exception e) {
            return "";
        }
    }

    private void cleanupS3Files(String inputPrefix, String outputKey) {
        try {
            // Delete input files
            s3Client.deleteObject(builder -> builder.bucket(s3Bucket).key(inputPrefix));
            
            // Delete output file
            s3Client.deleteObject(builder -> builder.bucket(s3Bucket).key(outputKey));
            
        } catch (Exception e) {
            // Log error but don't fail the main operation
            System.err.println("Failed to cleanup S3 files: " + e.getMessage());
        }
    }

    private String getTaskDefinitionForLanguage(String language) {
        return switch (language.toLowerCase()) {
            case "java" -> javaTaskDef;
            case "javascript" -> javascriptTaskDef;
            case "python" -> pythonTaskDef;
            case "cpp" -> cppTaskDef;
            default -> throw new IllegalArgumentException("Unsupported language: " + language);
        };
    }

    private String generateSessionId() {
        return "session-" + Instant.now().toEpochMilli() + "-" + 
               UUID.randomUUID().toString().substring(0, 8);
    }

    // Health check method
    public Map<String, Object> getHealthStatus() {
        Map<String, Object> health = new HashMap<>();
        
        try {
            // Check ECS cluster
            DescribeClustersRequest request = DescribeClustersRequest.builder()
                    .clusters(ecsCluster)
                    .build();
            
            DescribeClustersResponse response = ecsClient.describeClusters(request);
            boolean clusterActive = response.clusters().stream()
                    .anyMatch(cluster -> "ACTIVE".equals(cluster.status()));
            
            health.put("status", clusterActive ? "healthy" : "unhealthy");
            health.put("service", "ECS Code Compiler");
            health.put("cluster", ecsCluster);
            health.put("cluster_active", clusterActive);
            
        } catch (Exception e) {
            health.put("status", "unhealthy");
            health.put("service", "ECS Code Compiler");
            health.put("error", e.getMessage());
        }
        
        return health;
    }
}