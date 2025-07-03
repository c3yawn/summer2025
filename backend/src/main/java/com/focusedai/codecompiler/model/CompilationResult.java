package com.focusedai.codecompiler.model;

public class CompilationResult {
    private boolean success;
    private String output;
    private String error;
    
    // Default constructor
    public CompilationResult() {
    }
    
    // Constructor with parameters
    public CompilationResult(boolean success, String output, String error) {
        this.success = success;
        this.output = output;
        this.error = error;
    }
    
    // Getters and setters
    public boolean isSuccess() {
        return success;
    }
    
    public void setSuccess(boolean success) {
        this.success = success;
    }
    
    public String getOutput() {
        return output;
    }
    
    public void setOutput(String output) {
        this.output = output;
    }
    
    public String getError() {
        return error;
    }
    
    public void setError(String error) {
        this.error = error;
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
