package com.focusedai.codecompiler.model;

public class CodeFile {
    private String filename;
    private String content;
    
    // Default constructor
    public CodeFile() {
    }
    
    // Constructor with parameters
    public CodeFile(String filename, String content) {
        this.filename = filename;
        this.content = content;
    }
    
    // Getters and setters
    public String getFilename() {
        return filename;
    }
    
    public void setFilename(String filename) {
        this.filename = filename;
    }
    
    public String getContent() {
        return content;
    }
    
    public void setContent(String content) {
        this.content = content;
    }
    
    @Override
    public String toString() {
        return "CodeFile{" +
                "filename='" + filename + '\'' +
                ", content='" + content + '\'' +
                '}';
    }
}
