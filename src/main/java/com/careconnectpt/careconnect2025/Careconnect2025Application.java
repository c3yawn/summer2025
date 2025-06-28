package com.careconnectpt.careconnect2025;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;


@SpringBootApplication
@EnableAsync
public class Careconnect2025Application {

	public static void main(String[] args) {
		SpringApplication.run(Careconnect2025Application.class, args);
	}

}
