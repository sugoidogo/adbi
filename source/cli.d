import adbi, std.getopt;

private void log(string message, int messageMode = INFO) {
	if (logLevel < messageMode)
		return;
	if (messageMode == ERROR) {
		import std.stdio : stderr;

		stderr.writeln(message);
	} else {
		import std.stdio : writeln;

		writeln(message);
	}
}

void main(string[] args) {
	adbi.log = &cli.log;
	string installDir;
	try {
		auto xargs = getopt(args,
				"user-mode|u", "Install for current user only instead of all users.", &userMode,
				"install-dir|i", "Path to install folder.", &installDir,
				"log-level|l", "silent, error, info, or verbose", &logLevel);
		if (xargs.helpWanted) {
			defaultGetoptPrinter("Install Android Platform Tools", xargs.options);
			return;
		}
		if (!installDir) {
			if (userMode)
				installDir = defaultUserDir;
			else
				installDir = defaultAllUsersDir;
		} else if (installDir.isUserDir)
			userMode = true;
		installTools(installDir);
		installPath(installDir);
	} catch (Exception e) {
		log(cast(string) e.message, ERROR);
	}
}
