package com.tieuluan.backend;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class SrcBackendApplication {

	public static void main(String[] args) {
		SpringApplication.run(SrcBackendApplication.class, args);
	}

}
