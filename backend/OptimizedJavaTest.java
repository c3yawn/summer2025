public class OptimizedJavaTest {
    public static void main(String[] args) {
        System.out.println("Testing optimized Java container!");
        System.out.println("This should start much faster now!");
        long startTime = System.nanoTime();
        for(int i = 0; i < 1000; i++) {
            Math.sqrt(i);
        }
        long endTime = System.nanoTime();
        System.out.println("Computation completed in: " + (endTime - startTime) + " nanoseconds");
    }
}
