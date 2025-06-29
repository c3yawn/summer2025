package com.focusedai.codecompiler;

import org.springframework.beans.factory.annotation.Autowired;
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
import software.amazon.awssdk.core.sync.RequestBody;

@Service
public class EcsCodeCompilerService {

    private final EcsClient ecsClient;
    private final S3Client s3Client;

    @Autowired
    private CompilationCacheService cacheService;

    @Autowired
    private FastExecutionService fastExecutionService;

    @Autowired
    private WarmPoolService warmPoolService;

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

    public EcsCodeCompilerService(EcsClient ecsClient, S3Client s3Client) {
        this.ecsClient = ecsClient;
        this.s3Client = s3Client;
    }


        public CompilationResult executeCode(String language, String mainClassName, List<MultipartFile> files) {
        long startTime = System.currentTimeMillis();
        String inputPrefix = null;
        String outputKey = null;
        
        try {
            // Step 1: Check cache first
            CompilationResult cachedResult = cacheService.getCachedResult(language, files);
            if (cachedResult != null) {
                long duration = System.currentTimeMillis() - startTime;
                System.out.println("🚀 Cache hit! Returned result in " + duration + "ms");
                return cachedResult;
            }

            // Step 2: Try fast execution for simple code
            if (fastExecutionService.canExecuteFast(language, files)) {
                System.out.println("⚡ Using fast execution path for " + language);
                CompilationResult result = fastExecutionService.executeFast(language, files.get(0));
                cacheService.cacheResult(language, files, result);
                long duration = System.currentTimeMillis() - startTime;
                System.out.println("✅ Fast execution completed in " + duration + "ms");
                return result;
            }

            // Step 3: Use optimized ECS execution (simplified warm pool)
            System.out.println("🐳 Using optimized ECS execution for " + language);
            
            String sessionId = generateSessionId();
            inputPrefix = "temp/input/" + sessionId + "/";
            outputKey = "temp/output/" + sessionId + "/result.json";

            // Upload source files to S3
            uploadFilesToS3(files, inputPrefix);

            // Run optimized ECS task (these start faster due to optimized containers)
            String taskArn = runOptimizedCompilationTask(language, inputPrefix, outputKey);

            // Wait for task completion with shorter timeout since containers are optimized
            waitForTaskCompletionOptimized(taskArn);

            // Retrieve results from S3
            CompilationResult result = getCompilationResult(outputKey);
            
            // Cache the result
            cacheService.cacheResult(language, files, result);
            
            long duration = System.currentTimeMillis() - startTime;
            System.out.println("✅ Optimized ECS execution completed in " + duration + "ms");
            
            return result;

        } catch (Exception e) {
            long duration = System.currentTimeMillis() - startTime;
            System.err.println("❌ Execution failed after " + duration + "ms: " + e.getMessage());
            
            return CompilationResult.builder()
                    .success(false)
                    .output("")
                    .error("Internal error: " + e.getMessage())
                    .build();
        } finally {
            // Clean up S3 files
            if (inputPrefix != null && outputKey != null) {
                cleanupS3Files(inputPrefix, outputKey);
            }
        }
    }

    private String runOptimizedCompilationTask(String language, String inputPrefix, String outputKey) {
        try {
            String taskDefinition = getTaskDefinitionForLanguage(language);
            
            // Container overrides with execution environment  
            ContainerOverride containerOverride = ContainerOverride.builder()
                .name(language + "-compiler")
                .environment(
                    KeyValuePair.builder().name("LANGUAGE").value(language).build(),
                    KeyValuePair.builder().name("S3_BUCKET").value(s3Bucket).build(),
                    KeyValuePair.builder().name("S3_INPUT_PREFIX").value(inputPrefix).build(),
                    KeyValuePair.builder().name("S3_OUTPUT_KEY").value(outputKey).build(),
                    KeyValuePair.builder().name("AWS_DEFAULT_REGION").value("us-east-1").build()
                )
                .build();

            TaskOverride taskOverride = TaskOverride.builder()
                .containerOverrides(containerOverride)
                .build();

            NetworkConfiguration networkConfig = NetworkConfiguration.builder()
                .awsvpcConfiguration(AwsVpcConfiguration.builder()
                    .subnets(vpcSubnets.split(","))
                    .securityGroups(securityGroup)
                    .assignPublicIp(AssignPublicIp.ENABLED)
                    .build())
                .build();

            RunTaskRequest runRequest = RunTaskRequest.builder()
                .cluster(ecsCluster)
                .taskDefinition(taskDefinition)
                .launchType(LaunchType.FARGATE)
                .networkConfiguration(networkConfig)
                .overrides(taskOverride)
                .count(1)
                .build();

            System.out.println("🚀 Starting optimized task for " + language);
            RunTaskResponse response = ecsClient.runTask(runRequest);
            
            if (!response.tasks().isEmpty()) {
                String taskArn = response.tasks().get(0).taskArn();
                System.out.println("✅ Optimized task started: " + extractTaskId(taskArn));
                return taskArn;
            } else {
                throw new RuntimeException("Failed to start task: " + response.failures());
            }

        } catch (Exception e) {
            throw new RuntimeException("Error starting optimized compilation task: " + e.getMessage(), e);
        }
    }



    private CompilationResult executeWithWarmTask(String taskArn, String language, String mainClassName, 
                                            List<MultipartFile> files, long startTime) {
        String sessionId = generateSessionId();
        String inputPrefix = "temp/input/" + sessionId + "/";
        String outputKey = "temp/output/" + sessionId + "/result.json";

        try {
            // Upload source files to S3
            uploadFilesToS3(files, inputPrefix);

            // Update the existing warm task with new environment variables
            updateTaskEnvironment(taskArn, language, inputPrefix, outputKey);

            // Wait for task completion (should be much faster)
            waitForTaskCompletionOptimized(taskArn);

            // Retrieve results from S3
            CompilationResult result = getCompilationResult(outputKey);
            
            long duration = System.currentTimeMillis() - startTime;
            System.out.println("✅ Warm pool execution completed in " + duration + "ms");
            
            return result;

        } finally {
            // Clean up S3 files
            cleanupS3Files(inputPrefix, outputKey);
        }
    }

    private void updateTaskEnvironment(String taskArn, String language, String inputPrefix, String outputKey) {
        // For warm pool, we'll need to trigger the task to switch from WARM to EXECUTE mode
        // This is a simplified approach - in production you might use ECS Exec or other mechanisms
        System.out.println("🔄 Updating warm task environment for execution");
        
        // The warm task will need to be signaled to process the new job
        // For now, we'll use a simple approach where the task polls S3 for work
    }

    private void uploadFilesToS3(List<MultipartFile> files, String prefix) {
        try {
            for (MultipartFile file : files) {
                if (file.isEmpty()) {
                    throw new RuntimeException("Empty file detected: " + file.getOriginalFilename());
                }

                String key = prefix + file.getOriginalFilename();
                PutObjectRequest putRequest = PutObjectRequest.builder()
                        .bucket(s3Bucket)
                        .key(key)
                        .contentType("text/plain")
                        .build();

                s3Client.putObject(putRequest, RequestBody.fromBytes(file.getBytes()));
            }
        } catch (IOException e) {
            throw new RuntimeException("Failed to upload files to S3: " + e.getMessage(), e);
        } catch (Exception e) {
            throw new RuntimeException("S3 upload error: " + e.getMessage(), e);
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

    private void waitForTaskCompletionOptimized(String taskArn) {
        try {
            System.out.println("⏳ Waiting for optimized task completion: " + extractTaskId(taskArn));
            
            // Reduced timeout since optimized containers should be faster
            int maxWaitTimeSeconds = 120; // 2 minutes instead of 5
            int checkIntervalSeconds = 5;
            int maxChecks = maxWaitTimeSeconds / checkIntervalSeconds;
            
            for (int i = 0; i < maxChecks; i++) {
                DescribeTasksRequest request = DescribeTasksRequest.builder()
                    .cluster(ecsCluster)
                    .tasks(taskArn)
                    .build();

                DescribeTasksResponse response = ecsClient.describeTasks(request);
                
                if (!response.tasks().isEmpty()) {
                    Task task = response.tasks().get(0);
                    String status = task.lastStatus();
                    
                    System.out.println("📊 Task status: " + status + " (check " + (i + 1) + "/" + maxChecks + ")");
                    
                    if ("STOPPED".equals(status)) {
                        System.out.println("✅ Task completed");
                        return;
                    }
                }
                
                Thread.sleep(checkIntervalSeconds * 1000);
            }
            
            throw new RuntimeException("Task execution timed out after " + maxWaitTimeSeconds + " seconds");
            
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
            throw new RuntimeException("Task wait interrupted", e);
        } catch (Exception e) {
            throw new RuntimeException("Error waiting for task completion: " + e.getMessage(), e);
        }
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
        switch (language.toLowerCase()) {
            case "java": return "java-compiler-task";
            case "python": return "python-compiler-task";
            case "javascript": return "javascript-compiler-task";
            case "cpp": return "cpp-compiler-task";
            default: throw new IllegalArgumentException("Unknown language: " + language);
        }
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
            health.put("service", "ECS Code Compiler with Warm Pool");
            health.put("cluster", ecsCluster);
            health.put("cluster_active", clusterActive);
            
            // Add performance tier statistics
            health.put("cache", cacheService.getCacheStats());
            health.put("fast_execution", fastExecutionService.getFastExecutionStats());
            health.put("warm_pool", warmPoolService.getWarmPoolStatus());
            health.put("warm_task_count", warmPoolService.getWarmTaskCount());
            
        } catch (Exception e) {
            health.put("status", "unhealthy");
            health.put("service", "ECS Code Compiler with Warm Pool");
            health.put("error", e.getMessage());
        }
        
        return health;
    }

    public Map<String, Object> getWarmPoolStatus() {
        return warmPoolService.getWarmPoolStatus();
    }

    public int getWarmTaskCount() {
        return warmPoolService.getWarmTaskCount();
    }

    public Map<String, Object> getFastExecutionStats() {
        return fastExecutionService.getFastExecutionStats();
    }

    public boolean canExecuteFast(String language, List<MultipartFile> files) {
        return fastExecutionService.canExecuteFast(language, files);
    }

    /**
     * Get cache statistics for monitoring
     */
    public Map<String, Object> getCacheStats() {
        return cacheService.getCacheStats();
    }

    /**
     * Clear the compilation cache (useful for testing/debugging)
     */
    public void clearCache() {
        cacheService.clearCache();
    }

    private String extractTaskId(String taskArn) {
        if (taskArn == null) return null;
        return taskArn.substring(taskArn.lastIndexOf("/") + 1);
    }

}