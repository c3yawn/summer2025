package com.focusedai.caila_service;

public class PromptRequest {
    private String prompt;
    private String role; // "student" or "teacher"

    public String getPrompt() {
        return prompt;
    }

    public void setPrompt(String prompt) {
        this.prompt = prompt;
    }

    public String getRole() {
        return role;
    }

    public void setRole(String role) {
        this.role = role;
    }
}
