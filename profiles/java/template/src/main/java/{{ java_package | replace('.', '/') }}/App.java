package {{ java_package }};

/** Application entry point. */
public final class App {

    private App() {
        // entry point
    }

    public static void main(String[] args) {
        System.out.println(Hello.greet("world"));
    }
}
