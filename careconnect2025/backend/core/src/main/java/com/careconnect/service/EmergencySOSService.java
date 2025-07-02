package com.careconnect.service;

import com.careconnect.model.SosRequest;
import com.careconnect.model.SosResponse;
import org.springframework.stereotype.Service;

@Service
public class EmergencySosService {

    public SosResponse processSosRequest(SosRequest request) {
        // Simulate processing the SOS alert (e.g., notify caregiver, log info)
        System.out.println("SOS triggered for user: " + request.getUserId());
        System.out.println("Location: " + request.getLocation());
        System.out.println("Message: " + request.getMessage());

        // Return response
        SosResponse response = new SosResponse();
        response.setStatus("SUCCESS");
        response.setMessage("SOS sent to caregiver for user " + request.getUserId());
        return response;
    }

    public SosResponse cancelSosRequest(SosRequest request) {
        // Simulate cancellation logic
        System.out.println("SOS cancelled by user: " + request.getUserId());

        SosResponse response = new SosResponse();
        response.setStatus("CANCELLED");
        response.setMessage("SOS cancelled for user " + request.getUserId());
        return response;
    }
}

