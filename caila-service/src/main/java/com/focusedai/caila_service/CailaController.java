package com.focusedai.caila_service;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@CrossOrigin(origins = "*")
@RestController
@RequestMapping("/api/caila")
public class CailaController {

    private final CailaService cailaService;

    public CailaController(CailaService cailaService) {
        this.cailaService = cailaService;
    }

    @PostMapping("/chat")
    public ResponseEntity<ApiResponse<Map<String, String>>> chat(@RequestBody CailaRequest request) {
        // 🔧 Wrap in ResponseEntity
        ApiResponse<Map<String, String>> result = cailaService.chatWithCaila(request);
        return ResponseEntity.ok(result);
    }

    @PostMapping("/generate")
    public ResponseEntity<ApiResponse<Map<String, String>>> generateRubric(@RequestBody PromptRequest request) {
        // 🔧 Wrap in ResponseEntity
        ApiResponse<Map<String, String>> result = cailaService.generateRubric(request);
        return ResponseEntity.ok(result);
    }
}
