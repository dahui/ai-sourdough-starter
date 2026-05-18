package {{ java_package }};

import java.util.Objects;

/** Sample value-producing class shipped with the starter. Replace once real code lives here. */
public final class Hello {

    private Hello() {
        // utility class
    }

    /**
     * Returns a greeting for the given name.
     *
     * @param name target of the greeting; must be non-null and non-blank
     * @return formatted greeting
     * @throws NullPointerException if {@code name} is null
     * @throws IllegalArgumentException if {@code name} is blank
     */
    public static String greet(String name) {
        Objects.requireNonNull(name, "name");
        String trimmed = name.strip();
        if (trimmed.isEmpty()) {
            throw new IllegalArgumentException("name must not be blank");
        }
        return "Hello, " + trimmed + "!";
    }
}
