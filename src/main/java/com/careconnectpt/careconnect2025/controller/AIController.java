package com.careconnectpt.careconnect2025.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import com.careconnectpt.careconnect2025.dto.ChatRequest;
import com.careconnectpt.careconnect2025.dto.ChatResponse;
import com.careconnectpt.careconnect2025.service.ChatBotService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
//import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/v1/api/chat")
public class AIController {

    private final ChatBotService bot;

    @Autowired
    public AIController(ChatBotService bot) {
        this.bot = bot;
    }

    @PostMapping
    public ResponseEntity<ChatResponse> chat(
            @RequestHeader("X-Session-Id") String sessionId,
            @Valid @RequestBody ChatRequest request) {

        String answer = bot.ask(sessionId, request.getMessage());
        return ResponseEntity.ok(new ChatResponse(answer));
    }
    
    @PostMapping("/mood-detection")
    public ResponseEntity<String> detectMood() { return ResponseEntity.ok("Mood detected"); }
}