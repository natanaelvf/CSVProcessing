import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.io.PrintWriter;

/**
* A classe ProcessWrapper é responsável por gerir a criação e término de processos UNIX, bem como
* por facilitar a comunicação com esse processo através de STDIN e STDOUT.
*/
public class ProcessWrapper {
	private Process p;
	private PrintWriter writer;
	private BufferedReader reader;

	private OutputStream out;
	private InputStream ins;
    
    /**
    * Este construtor inicia o processo pretendido.
    *
    * @param path O caminho do binário que pretendemos executar.
    */
	public ProcessWrapper(String path) {
		try {
			ProcessBuilder pb = new ProcessBuilder(".." + path);
			pb.redirectErrorStream(true);
			p = pb.start();
			ins = p.getInputStream();
			out = p.getOutputStream();
			writer = new PrintWriter(out);
			reader = new BufferedReader(new InputStreamReader(ins,"UTF-8"));
			
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
	}
    
    /**
    * O método write escreve uma nova linha no STDIN do processo.
    *
    * @param msg O conteúdo da linha a enviar, excluindo o \\n.
    */
	public void writeLine(String msg) {
		writer.write(msg + "\n");
		writer.flush();
	}
	
    /**
    * O método readLine devolve a primeira linha disponível no STDOUT do processo.
    *
    * De notar que este método é bloqueante.
    *
    * @return A primeira linha lida.
    */
	public String readLine() {
		try {
			return reader.readLine();
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
	}


    /**
    * Mata o processo.
    */
	public void kill() {
		p.destroy();
	}
}
