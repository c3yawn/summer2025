package com.focusedai.codecompiler;

import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;
import java.io.File;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.UUID;
import java.util.concurrent.TimeUnit;
import java.util.stream.Stream;

@RestController
@RequestMapping("/code")
public class CodeCompilerService {

    private static final String DOCKER_IMAGE = "java-compiler-runner";
    private static final long TIMEOUT_SECONDS = 30;

    /**
     * Accepts multiple Java source files as multipart/form-data and executes them in a Docker container.
     *
     * @param javaFiles An array of MultipartFile representing the Java source files.
     * @param mainClassName The name of the main class to compile and run (without .java extension).
     * @return A CodeExecutionResult containing status, compilation errors, and program output.
     */
    @PostMapping(value = "/execute", consumes = "multipart/form-data")
    public CodeExecutionResult executeJavaCode(
            @RequestParam("javaFiles") MultipartFile[] javaFiles,
            @RequestParam("mainClassName") String mainClassName) {

        Path tempHostDir = null; // Temporary directory on the Spring Boot host
        try {
            String uniqueId = UUID.randomUUID().toString();
            tempHostDir = Files.createTempDirectory("java_code_submission_" + uniqueId);

            for (MultipartFile file : javaFiles) {
                if (!file.isEmpty()) {
                    Path filePath = tempHostDir.resolve(file.getOriginalFilename());
                    Files.copy(file.getInputStream(), filePath);
                    System.out.println("Saved file: " + filePath);
                }
            }

            Path compilationErrorsFile = tempHostDir.resolve("compilation_errors.txt");
            Path programOutputAndErrorsFile = tempHostDir.resolve("program_output_and_errors.txt");

            // Docker commands

            // Override ENTRYPOINT to run /bin/sh for compilation
            String compileCommandString = String.format(
                "docker run --rm --entrypoint /bin/sh -v \"%s:/app\" %s -c \"javac *.java 2> /app/%s\"",
                tempHostDir.toAbsolutePath().toString(),
                DOCKER_IMAGE,
                compilationErrorsFile.getFileName().toString()
            );

            System.out.println("Compiling with command: " + compileCommandString); // Debugging
            Process compileProcess = Runtime.getRuntime().exec(compileCommandString);
            new Thread(() -> { try { compileProcess.getErrorStream().transferTo(System.err); } catch (IOException e) { System.err.println("Error consuming compile stderr: " + e.getMessage());} }).start();
            new Thread(() -> { try { compileProcess.getInputStream().transferTo(System.out); } catch (IOException e) { System.err.println("Error consuming compile stdout: " + e.getMessage());} }).start();

            boolean compileExited = compileProcess.waitFor(TIMEOUT_SECONDS, TimeUnit.SECONDS);

            if (!compileExited) {
                compileProcess.destroyForcibly();
                return new CodeExecutionResult("Compilation Timed Out", "", "", true);
            }
            if (compileProcess.exitValue() != 0) {
                String compilationErrors = Files.readString(compilationErrorsFile);
                return new CodeExecutionResult("Compilation Failed", compilationErrors, "", true);
            }

            // Override ENTRYPOINT to run /bin/sh for execution
            String runCommandString = String.format(
                "docker run --rm --entrypoint /bin/sh -v \"%s:/app\" %s -c \"java %s > /app/%s 2>&1\"",
                tempHostDir.toAbsolutePath().toString(),
                DOCKER_IMAGE,
                mainClassName,
                programOutputAndErrorsFile.getFileName().toString()
            );
            System.out.println("Running with command: " + runCommandString); // Debugging
            Process runProcess = Runtime.getRuntime().exec(runCommandString);
            new Thread(() -> { try { runProcess.getErrorStream().transferTo(System.err); } catch (IOException e) { System.err.println("Error consuming run stderr: " + e.getMessage());} }).start();
            new Thread(() -> { try { runProcess.getInputStream().transferTo(System.out); } catch (IOException e) { System.err.println("Error consuming run stdout: " + e.getMessage());} }).start();

            boolean runExited = runProcess.waitFor(TIMEOUT_SECONDS, TimeUnit.SECONDS);

            if (!runExited) {
                runProcess.destroyForcibly();
                return new CodeExecutionResult("Execution Timed Out", "", "", true);
            }

            String programOutput = Files.readString(programOutputAndErrorsFile);
            return new CodeExecutionResult("Success", "", programOutput, false);

        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
            return new CodeExecutionResult("Server Error", "", e.getMessage(), true);
        } finally {
            if (tempHostDir != null && Files.exists(tempHostDir)) {
                try (Stream<Path> walk = Files.walk(tempHostDir)) {
                    walk.sorted(java.util.Comparator.reverseOrder())
                        .map(Path::toFile)
                        .forEach(File::delete);
                } catch (IOException e) {
                    System.err.println("Failed to delete temp directory: " + tempHostDir + " " + e.getMessage());
                    e.printStackTrace();
                }
            }
        }
    }

    // Response fields
    static class CodeExecutionResult {
        public String status;
        public String compilationErrors;
        public String programOutput;
        public boolean hasError;

        public CodeExecutionResult(String status, String compilationErrors, String programOutput, boolean hasError) {
            this.status = status;
            this.compilationErrors = compilationErrors;
            this.programOutput = programOutput;
            this.hasError = hasError;
        }
    }
}