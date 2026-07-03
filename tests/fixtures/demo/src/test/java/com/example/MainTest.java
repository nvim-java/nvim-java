package com.example;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;

import org.junit.jupiter.api.Test;

class MainTest {
	@Test
	void greetReturnsGreeting() {
		assertEquals("Hello from nvim-java", Main.greet());
	}

	@Test
	void greetIsNotEmpty() {
		assertTrue(Main.greet().length() > 0);
	}
}
