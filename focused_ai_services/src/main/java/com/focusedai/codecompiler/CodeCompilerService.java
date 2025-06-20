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

    private static final String JAVA_DOCKER_IMAGE = "java-compiler-runner";
    private static final String JS_DOCKER_IMAGE = "js-compiler-runner";
    private static final long TIMEOUT_SECONDS = 30;

    @PostMapping(value = "/execute", consumes = "multipart/form-data")
    public CodeExecutionResult executeCode(
            @RequestParam("javaFiles") MultipartFile[] codeFiles,
            @RequestParam("mainClassName") String mainClassName,
            @RequestParam("language") String language) {

        Path tempHostDir = null;

        try {
            String uniqueId = UUID.randomUUID().toString();
            tempHostDir = Files.createTempDirectory("code_submission_" + uniqueId);

            for (MultipartFile file : codeFiles) {
                if (!file.isEmpty()) {
                    Path filePath = tempHostDir.resolve(file.getOriginalFilename());
                    Files.copy(file.getInputStream(), filePath);
                    System.out.println("Saved file: " + filePath);
                }
            }

            if ("java".equalsIgnoreCase(language)) {
                return executeJava(tempHostDir, mainClassName);
            } else if ("javascript".equalsIgnoreCase(language)) {
                return executeJavaScript(tempHostDir, mainClassName);
            } else if ("python".equalsIgnoreCase(language)) {
                return executePython(tempHostDir, mainClassName);
            }
              else {
                return new CodeExecutionResult("Unsupported Language", "", "Language not supported: " + language, true);
            }

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
                }
            }
        }
    }

    private CodeExecutionResult executeJava(Path tempDir, String mainClassName) throws IOException, InterruptedException {
        Path compilationErrorsFile = tempDir.resolve("compilation_errors.txt");
        Path outputFile = tempDir.resolve("program_output.txt");

        String compileCmd = String.format(
                "docker run --rm --entrypoint /bin/sh -v \"%s:/app\" %s -c \"javac *.java 2> /app/%s\"",
                tempDir.toAbsolutePath(),
                JAVA_DOCKER_IMAGE,
                compilationErrorsFile.getFileName()
        );

        Process compileProcess = Runtime.getRuntime().exec(compileCmd);
        boolean compileExited = compileProcess.waitFor(TIMEOUT_SECONDS, TimeUnit.SECONDS);

        if (!compileExited) {
            compileProcess.destroyForcibly();
            return new CodeExecutionResult("Compilation Timed Out", "", "", true);
        }

        String compileErrors = Files.readString(compilationErrorsFile);
        if (compileProcess.exitValue() != 0) {
            return new CodeExecutionResult("Compilation Failed", compileErrors, "", true);
        }

        String runCmd = String.format(
                "docker run --rm --entrypoint /bin/sh -v \"%s:/app\" %s -c \"java %s > /app/%s 2>&1\"",
                tempDir.toAbsolutePath(),
                JAVA_DOCKER_IMAGE,
                mainClassName,
                outputFile.getFileName()
        );

        return runDockerCommand(runCmd, outputFile, "Java Execution Failed");
    }

    private CodeExecutionResult executeJavaScript(Path tempDir, String mainClassName) throws IOException, InterruptedException {
        Path outputFile = tempDir.resolve("program_output.txt");
        String mainFileName = mainClassName.toLowerCase().endsWith(".js") ? mainClassName : mainClassName + ".js";

        String runCmd = String.format(
                "docker run --rm --entrypoint /bin/sh -v \"%s:/app\" %s -c \"node %s > /app/%s 2>&1\"",
                tempDir.toAbsolutePath(),
                JS_DOCKER_IMAGE,
                mainFileName,
                outputFile.getFileName()
        );

        return runDockerCommand(runCmd, outputFile, "JavaScript Execution Failed");
    }

    private CodeExecutionResult runDockerCommand(String command, Path outputFile, String errorStatus)
            throws IOException, InterruptedException {
        try {
            Process process = Runtime.getRuntime().exec(command);
            boolean finished = process.waitFor(TIMEOUT_SECONDS, TimeUnit.SECONDS);

            if (!finished) {
                process.destroyForcibly();
                return new CodeExecutionResult("Execution Timed Out", "", "", true);
            }

            int exitCode = process.exitValue();
            String output = Files.exists(outputFile) ? Files.readString(outputFile) : getProcessOutput(process);

            if (exitCode != 0) {
                return new CodeExecutionResult(errorStatus, "", output, true);
            }

            return new CodeExecutionResult("Success", "", output, false);

        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
            return new CodeExecutionResult("Server Error", "", e.getMessage(), true);
        }
    }

    private CodeExecutionResult executePython(Path tempDir, String mainFileName) throws IOException, InterruptedException {
        Path outputFile = tempDir.resolve("program_output.txt");
        String pythonFileName = mainFileName.toLowerCase().endsWith(".py") ? mainFileName : mainFileName + ".py";

        String runCmd = String.format(
            "docker run --rm --entrypoint /bin/sh -v \"%s:/app\" %s -c \"python %s > /app/%s 2>&1\"",
            tempDir.toAbsolutePath(),
            "python-compiler-runner",
            pythonFileName,
            outputFile.getFileName()
        );

        return runDockerCommand(runCmd, outputFile, "Python Execution Failed");
    }

    private String getProcessOutput(Process process) throws IOException {
        String stdout = new String(process.getInputStream().readAllBytes());
        String stderr = new String(process.getErrorStream().readAllBytes());
        return stdout + "\n" + stderr;
    }

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