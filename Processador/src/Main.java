import java.io.IOException;
import java.nio.file.FileSystems;
import java.nio.file.Files;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.stream.Collectors;
import java.util.stream.Stream;

/**
 * Este programa le um ficheiro CSV (dataset.csv no exemplo abaixo) 
 * e cria varios agregadores, um para cada metrica.
 * 
 * @date   07/01
 * @author Natanael Ferreira no52678
 */
public class Main {
    public static void main(String[] args) {

        String haskellFile = "/Agregador/Main.exe";
        String metricsFile = "/metrics.txt";
        String csvFile     = "/dataset.csv";

        ProcessWrapper readerWritter = new ProcessWrapper(haskellFile);

        try(Stream<String> lines = Files.lines(FileSystems.getDefault().getPath("..", csvFile));){
            List<List<String>> dataset = lines.map(line -> Arrays.asList(line.split(","))).collect(Collectors.toList());

            // Read file into stream, using try
            try (Stream<String> metricsStream = Files.lines(FileSystems.getDefault().getPath("..", metricsFile))) {

                List<String> metrics = metricsStream.collect(Collectors.toList());

                List<ProcessWrapper> listOfPWs = new ArrayList<>();

                // Loop metrics, criating a ProcessWrapper for each
                for (int i = 0; i < metrics.size(); i++) {

                    listOfPWs.add(new ProcessWrapper(haskellFile));

                    // Write metrics
                    listOfPWs.get(i).writeLine(metrics.get(i));
                }

                // Loop transactions
                for(int j = 0; j < dataset.size(); j++) {
                    String transaction = String.join(" ", dataset.get(j));

                    for(int k = 0; k < listOfPWs.size(); k++) {
                        listOfPWs.get(k).writeLine(transaction);
                        String output = listOfPWs.get(k).readLine();
                        System.out.print(output + (k < listOfPWs.size() - 1 ? "," : "\n"));
                    }
                }
                // Write exit
                readerWritter.writeLine("exit");

            } catch (IOException e) {
                e.printStackTrace();
            }
        } catch (IOException e) {
            e.printStackTrace();
        }
    }
}

