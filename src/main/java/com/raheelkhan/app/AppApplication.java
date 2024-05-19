package com.raheelkhan.app;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.bind.annotation.RequestMapping;

@RestController
@SpringBootApplication
public class AppApplication {

	@RequestMapping("/")
	public String hello() {
		return "Hello, Rak!";
	}

	public static void main(String[] args) {
		SpringApplication.run(AppApplication.class, args);
	}

}
