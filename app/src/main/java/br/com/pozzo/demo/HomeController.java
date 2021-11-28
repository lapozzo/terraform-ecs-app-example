package br.com.pozzo.demo;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HomeController {
	Logger logger = LoggerFactory.getLogger(HomeController.class);

	@RequestMapping("/")
	public ResponseEntity<String> get() {
		logger.info("Hello World Logging...");
		return new ResponseEntity<String>("{\"message\":\"Hello World!\"}", HttpStatus.OK);
	}
}