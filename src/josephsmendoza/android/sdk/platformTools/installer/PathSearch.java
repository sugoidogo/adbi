package josephsmendoza.android.sdk.platformTools.installer;

import java.io.File;

public class PathSearch implements Runnable{

	public PathSearch() {
		
	}

	@Override
	public void run() {
		try {
			File adb=new File(new String(Runtime.getRuntime().exec(adbGetCommand()).getInputStream().readAllBytes()));
			if(adb.canExecute()) {
				Common.installPaths.add(adb.getParentFile().getAbsolutePath());
			}
		} catch (Exception e) {
			// Not found
		}
		try {
			File fastboot=new File(new String(Runtime.getRuntime().exec(fastbootGetCommand()).getInputStream().readAllBytes()));
			if(fastboot.canExecute()) {
				Common.installPaths.add(fastboot.getParentFile().getAbsolutePath());
			}
		} catch (Exception e) {
			// Not found
		}
	}

	private String fastbootGetCommand() {
		return getCommand()+Common.fastboot;
	}

	private String adbGetCommand() {
		return getCommand()+Common.adb;
	}

	private String getCommand() {
		if(Common.OS=="WIN") {
			return "where";
		} else {
			return "which";
		}
	}

}
