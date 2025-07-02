package com.careconnect.controller;

import com.careconnect.model.SosRequest;
import com.careconnect.model.SosResponse;
import com.careconnect.service.EmergencySosService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/sos")
public class EmergencySosController {

    @Autowired
    private EmergencySosService emergencySosService;

    @PostMapping("/trigger")
    public SosResponse triggerSos(@RequestBody SosRequest sosRequest) {
        return emergencySosService.processSosRequest(sosRequest);
    }

    @PostMapping("/cancel")
    public SosResponse cancelSos(@RequestBody SosRequest sosRequest) {
        return emergencySosService.cancelSosRequest(sosRequest);
    }
}
