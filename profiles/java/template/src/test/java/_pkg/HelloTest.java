package {{ java_package }};

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertThrows;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

class HelloTest {

  @Test
  @DisplayName("greet returns formatted greeting for a plain name")
  void greetReturnsGreeting() {
    assertEquals("Hello, world!", Hello.greet("world"));
  }

  @Test
  @DisplayName("greet strips leading and trailing whitespace")
  void greetStripsWhitespace() {
    assertEquals("Hello, Ada!", Hello.greet("  Ada  "));
  }

  @Test
  @DisplayName("greet rejects null name")
  void greetRejectsNull() {
    assertThrows(NullPointerException.class, () -> Hello.greet(null));
  }

  @Test
  @DisplayName("greet rejects empty name")
  void greetRejectsEmpty() {
    assertThrows(IllegalArgumentException.class, () -> Hello.greet(""));
  }

  @Test
  @DisplayName("greet rejects whitespace-only name")
  void greetRejectsWhitespace() {
    assertThrows(IllegalArgumentException.class, () -> Hello.greet("   \t\n"));
  }
}
