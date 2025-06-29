// Updated WarmPoolService.java with better task lifecycle management

package com.focusedai.codecompiler;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.context.event.ContextRefreshedEvent;
import org.springframework.context.event.EventListener;
import org.springframework.beans.factory.DisposableBean;

import software.amazon.awssdk.services.ecs.EcsClient;
import software.amazon.awssdk.services.ecs.model.*;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import java.util.List;

@Service
public class WarmPoolService implements DisposableBean {

    private final EcsClient ecsClient;
    private final Map<String, String> warmTasks = new ConcurrentHashMap<>();
    private final ScheduledExecutorService scheduler = Executors.newScheduledThreadPool(2);

    @Value("${aws.ecs.cluster}")
    private String ecsCluster;

    @Value("${aws.vpc.subnets}")
    private String vpcSubnets;

    @Value("${aws.vpc.security-group}")
    private String securityGroup;

    // Task definitions mapping
    private static final Map<String, String> TASK_DEFINITIONS = Map.of(
        "java", "java-compiler-task",
        "python", "python-compiler-task", 
        "javascript", "javascript-compiler-task",
        "cpp", "cpp-compiler-task"
    );

    public WarmPoolService(EcsClient ecsClient) {
        this.ecsClient = ecsClient;
    }

    @EventListener(ContextRefreshedEvent.class)
    public void initializeWarmPool() {
        System.out.println("🔥 Initializing warm pool...");
        
        // Start warm containers for each language after a delay
        scheduler.schedule(() -> {
            for (String language : TASK_DEFINITIONS.keySet()) {
                try {
                    startWarmContainer(language);
                    Thread.sleep(10000); // 10 second delay between starts
                } catch (Exception e) {
                    System.err.println("❌ Failed to start warm container for " + language + ": " + e.getMessage());
                }
            }
        }, 30, TimeUnit.SECONDS);
        
        // Schedule periodic health checks
        scheduler.scheduleAtFixedRate(this::checkAndReplenishWarmPool, 2, 2, TimeUnit.MINUTES);
    }

    private void startWarmContainer(String language) {
        try {
            System.out.println("🔥 Starting warm container for " + language + "...");
            
            String taskDefinition = TASK_DEFINITIONS.get(language);
            if (taskDefinition == null) {
                throw new IllegalArgumentException("No task definition for language: " + language);
            }

            // Create container overrides for warm mode
            ContainerOverride containerOverride = ContainerOverride.builder()
                .name(language + "-compiler")
                .environment(
                    KeyValuePair.builder().name("MODE").value("WARM").build(),
                    KeyValuePair.builder().name("LANGUAGE").value(language).build(),
                    KeyValuePair.builder().name("WARM_TIMEOUT").value("3600").build(), // 1 hour
                    KeyValuePair.builder().name("AWS_DEFAULT_REGION").value("us-east-1").build()
                )
                .build();

            TaskOverride taskOverride = TaskOverride.builder()
                .containerOverrides(containerOverride)
                .build();

            // Network configuration
            NetworkConfiguration networkConfig = NetworkConfiguration.builder()
                .awsvpcConfiguration(AwsVpcConfiguration.builder()
                    .subnets(vpcSubnets.split(","))
                    .securityGroups(securityGroup)
                    .assignPublicIp(AssignPublicIp.ENABLED)
                    .build())
                .build();

            // Run the task
            RunTaskRequest runRequest = RunTaskRequest.builder()
                .cluster(ecsCluster)
                .taskDefinition(taskDefinition)
                .launchType(LaunchType.FARGATE)
                .networkConfiguration(networkConfig)
                .overrides(taskOverride)
                .count(1)
                .build();

            RunTaskResponse response = ecsClient.runTask(runRequest);
            
            if (!response.tasks().isEmpty()) {
                String taskArn = response.tasks().get(0).taskArn();
                String taskId = extractTaskId(taskArn);
                warmTasks.put(language, taskArn);
                System.out.println("✅ Warm container started for " + language + ": " + taskId);
            } else {
                System.err.println("❌ Failed to start warm container for " + language + ": No tasks created");
                if (!response.failures().isEmpty()) {
                    response.failures().forEach(failure -> 
                        System.err.println("❌ Task failure: " + failure.reason()));
                }
            }

        } catch (Exception e) {
            System.err.println("❌ Error starting warm container for " + language + ": " + e.getMessage());
            e.printStackTrace();
        }
    }

    private void checkAndReplenishWarmPool() {
        System.out.println("🔍 Checking warm pool health...");
        
        for (String language : TASK_DEFINITIONS.keySet()) {
            String taskArn = warmTasks.get(language);
            if (taskArn == null || !isTaskRunning(taskArn)) {
                System.out.println("🔄 Replenishing warm container for " + language);
                warmTasks.remove(language); // Remove dead task
                startWarmContainer(language); // Start new one
            }
        }
    }

    private boolean isTaskRunning(String taskArn) {
        try {
            DescribeTasksRequest request = DescribeTasksRequest.builder()
                .cluster(ecsCluster)
                .tasks(taskArn)
                .build();

            DescribeTasksResponse response = ecsClient.describeTasks(request);
            
            if (!response.tasks().isEmpty()) {
                Task task = response.tasks().get(0);
                String status = task.lastStatus();
                System.out.println("📊 Task " + extractTaskId(taskArn) + " status: " + status);
                return "RUNNING".equals(status);
            }
            
            return false;
        } catch (Exception e) {
            System.err.println("❌ Error checking task status: " + e.getMessage());
            return false;
        }
    }

    public String getWarmTask(String language) {
        String taskArn = warmTasks.get(language);
        if (taskArn != null && isTaskRunning(taskArn)) {
            System.out.println("🔥 Found warm task for " + language + ": " + extractTaskId(taskArn));
            return taskArn;
        } else {
            System.out.println("❄️ No warm task available for " + language);
            return null;
        }
    }

    public Map<String, Object> getWarmPoolStatus() {
        Map<String, Object> status = new ConcurrentHashMap<>();
        
        for (String language : TASK_DEFINITIONS.keySet()) {
            String taskArn = warmTasks.get(language);
            Map<String, Object> languageStatus = new ConcurrentHashMap<>();
            
            if (taskArn != null) {
                languageStatus.put("has_warm_task", true);
                languageStatus.put("task_id", extractTaskId(taskArn));
                languageStatus.put("is_running", isTaskRunning(taskArn));
                languageStatus.put("task_arn", taskArn); // Add full ARN for debugging
            } else {
                languageStatus.put("has_warm_task", false);
                languageStatus.put("task_id", null);
                languageStatus.put("is_running", false);
            }
            
            status.put(language, languageStatus);
        }
        
        return status;
    }

    public int getWarmTaskCount() {
        int count = 0;
        for (String language : TASK_DEFINITIONS.keySet()) {
            String taskArn = warmTasks.get(language);
            if (taskArn != null && isTaskRunning(taskArn)) {
                count++;
            }
        }
        return count;
    }

    private String extractTaskId(String taskArn) {
        if (taskArn == null) return null;
        return taskArn.substring(taskArn.lastIndexOf("/") + 1);
    }

    private void stopTask(String taskArn) {
        try {
            if (taskArn != null) {
                StopTaskRequest request = StopTaskRequest.builder()
                    .cluster(ecsCluster)
                    .task(taskArn)
                    .reason("Warm pool shutdown")
                    .build();
                
                ecsClient.stopTask(request);
                System.out.println("🛑 Stopped warm task: " + extractTaskId(taskArn));
            }
        } catch (Exception e) {
            System.err.println("❌ Error stopping task: " + e.getMessage());
        }
    }

    @Override
    public void destroy() {
        System.out.println("🛑 Shutting down warm pool...");
        
        // Stop all warm tasks
        for (String taskArn : warmTasks.values()) {
            stopTask(taskArn);
        }
        
        // Shutdown scheduler
        scheduler.shutdown();
        try {
            if (!scheduler.awaitTermination(30, TimeUnit.SECONDS)) {
                scheduler.shutdownNow();
            }
        } catch (InterruptedException e) {
            scheduler.shutdownNow();
        }
    }
}