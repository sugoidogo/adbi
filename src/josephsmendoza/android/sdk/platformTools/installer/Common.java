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
	public static volatile boolean FileSearchComplete=false;
	public static volatile boolean PathSearchComplete=false;
	public static volatile boolean FileInstallComplete=false;
	public static volatile boolean PathInstallComplete=false;
	public static volatile boolean SettingsInstallComplete=false;
	public static final String OS = System.getProperty("os.name").toUpperCase().substring(0, 3);
	public static final String adb=" adb";
	public static final String fastboot=" fastboot";

	public static void main(String[] args) {
		try {
			GUI gui = new GUI();
			initInstallPaths();
			executorService = Executors.newFixedThreadPool(Runtime.getRuntime().availableProcessors());
			executorService.execute(gui);
			executorService.execute(new FileSearch());
			executorService.execute(new PathSearch());
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
		executorService.execute(new FileInstall(path));
		executorService.execute(new PathInstall(path));
		executorService.execute(new AVFixInstall(path));
	}

}