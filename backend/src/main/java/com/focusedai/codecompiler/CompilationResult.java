package com.focusedai.codecompiler;

/**
 * Represents the result of a code compilation and execution
 */
public class CompilationResult {
    private boolean success;
    private String output;
    private String error;

    // Default constructor
    public CompilationResult() {}

    // Constructor with all fields
    public CompilationResult(boolean success, String output, String error) {
        this.success = success;
        this.output = output;
        this.error = error;
    }

    // Getters
    public boolean isSuccess() {
        return success;
    }

    public String getOutput() {
        return output;
    }

    public String getError() {
        return error;
    }

    // Setters
    public void setSuccess(boolean success) {
        this.success = success;
    }

    public void setOutput(String output) {
        this.output = output;
    }

    public void setError(String error) {
        this.error = error;
    }

    // Builder pattern
    public static Builder builder() {
        return new Builder();
    }

    public static class Builder {
        private boolean success;
        private String output = "";
        private String error = "";

        public Builder success(boolean success) {
            this.success = success;
            return this;
        }

        public Builder output(String output) {
            this.output = output != null ? output : "";
            return this;
        }

        public Builder error(String error) {
            this.error = error != null ? error : "";
            return this;
        }

        public CompilationResult build() {
            return new CompilationResult(success, output, error);
        }
    }

    @Override
    public String toString() {
        return "CompilationResult{" +
                "success=" + success +
                ", output='" + output + '\'' +
                ", error='" + error + '\'' +
                '}';
    }
}