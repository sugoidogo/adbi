package josephsmendoza.android.sdk.platformTools.installer;

import java.nio.file.Paths;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

public class Common {

	private static ExecutorService executorService;
	public static final Set<String> installPaths = Collections.synchronizedSet(new HashSet<String>());
	public static volatile boolean searchComplete = false;
	public static volatile boolean installComplete = false;
	public static final String OS = System.getProperty("os.name").toUpperCase().substring(0, 3);

	public static void main(String[] args) {
		try {
			GUI gui = new GUI();
			initInstallPaths();
			executorService = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());
			executorService.execute(gui);
			executorService.execute(new FileSearch());
			while(!installComplete) {
				Thread.sleep(200);
			}
			System.exit(0);
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
	}

	private static void initInstallPaths() {
		final String append = Paths.get("Android", "SDK", "platform-tools").toString();
		switch (OS) {
		case "WIN":
			installPaths.add(Paths.get(System.getenv("LocalAppData"), append).toString());
			installPaths.add(Paths.get(System.getenv("ProgramFiles"), append).toString());
			break;
		}

	}

	public static void install(String path) {
		executorService.execute(new Install(path));
	}

}