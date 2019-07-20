package josephsmendoza.android.sdk.platformTools.installer;

import java.io.File;

import com.sun.jna.platform.win32.Advapi32Util;
import com.sun.jna.platform.win32.WinReg;

public class PathInstall implements Runnable {

	private String dir;
	private String sysKey;
	private String userKey;
	private String value;
	//private Advapi32Util winReg;

	public PathInstall(String installPath) {
		dir = installPath;
		sysKey = "System\\CurrentControlSet\\Control\\Session Manager\\Environment";
		userKey = "Environment";
		value = "PATH";
	}

	@Override
	public void run() {
		if (dir.contains(System.getProperty("user.home"))) {
			install(userKey);
		} else {
			install(sysKey);
		}
	}
	
	private void install(String key){
		try {
			final String PATH = Advapi32Util.registryGetStringValue(WinReg.HKEY_LOCAL_MACHINE, sysKey, value);
			if (!PATH.contains(dir)) {
				Advapi32Util.registrySetStringValue(WinReg.HKEY_LOCAL_MACHINE, key, value,
						PATH + File.pathSeparatorChar + dir);
			}
			Common.PathInstallComplete = true;
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
	}

}
