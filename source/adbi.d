import std.path, std.process, std.algorithm.searching, std.stdio;

private string APPEND;
bool userMode;
version (Windows) string HOME = "HOMEPATH";
version (Posix) string HOME = "HOME";
enum LogLevel {
	SILENT,
	silent = SILENT,
	s = SILENT,
	ERROR,
	error = ERROR,
	e = ERROR,
	INFO,
	info = INFO,
	i = INFO,
	VERBOSE,
	verbose = VERBOSE,
	v = VERBOSE
}

alias SILENT = LogLevel.SILENT;
alias ERROR = LogLevel.ERROR;
alias INFO = LogLevel.INFO;
alias VERBOSE = LogLevel.VERBOSE;
LogLevel logLevel = INFO;

void function(string message, int messageMode = INFO) log;

private string append() {
	if (!APPEND)
		APPEND = buildNormalizedPath("Android", "SDK", "platform-tools");
	return APPEND;
}

string defaultUserDir() {
	version (Windows) string dir = "C:/" ~ environment.get(HOME) ~ "/AppData/Local";
	version (linux) string dir = "~";
	version (OSX) string dir = "~/Library";
	return buildNormalizedPath(dir.expandTilde, append);
}

string defaultAllUsersDir() {
	version (Windows) string dir = "C:/Program Files";
	version (linux) string dir = "/opt";
	version (OSX) string dir = "/Library";
	return buildNormalizedPath(dir, append);
}

bool isUserDir(string installDir) {
	return installDir.canFind(environment.get(HOME));
}

void installTools(string installDir) {
	import std.zip, std.file, std.net.curl, std.conv;

	version (Windows) string url = "https://dl.google.com/android/repository/platform-tools-latest-windows.zip";
	version (OSX) string url = "https://dl.google.com/android/repository/platform-tools-latest-darwin.zip";
	version (linux) string url = "https://dl.google.com/android/repository/platform-tools-latest-linux.zip";

	log("Downloading");
	log(url, VERBOSE);

	ubyte[] data;
	auto http = HTTP(url);
	http.onReceive = (ubyte[] response) {
		data ~= response;
		return response.length;
	};
	http.perform();

	log("Extracting");
	log(installDir, VERBOSE);

	auto zip = new ZipArchive(data);
	foreach (zipEntry; zip.directory) {
		auto extractPath = buildNormalizedPath(installDir, zipEntry.name[15 .. $]);
		if (zipEntry.compressedSize != 0) {
			log(zipEntry.name, VERBOSE);
			if (extractPath.exists && extractPath.isDir) {
				rmdirRecurse(extractPath);
			} else if (!extractPath.dirName.exists)
				mkdirRecurse(extractPath.dirName);
			zip.expand(zipEntry);
			extractPath.write(zipEntry.expandedData);
			version (Posix)
				setAttributes(extractPath, octal!775);
		} else {
			if (extractPath.exists) {
				if (extractPath.isFile) {
					extractPath.remove();
					extractPath.mkdir();
				}
			} else
				extractPath.mkdirRecurse();
		}
	}
}

void installPath(string installDir) {
	import std.process : environment;

	log("Adding to PATH");
	string path = environment.get("PATH");
	if (path.canFind(installDir)) {
		log("Install folder is already in PATH");
		return;
	}

	version (Windows) {
		import std.windows.registry : Registry, Key, REGSAM;

		Key env;
		if (userMode) {
			env = Registry.currentUser.getKey("Environment", REGSAM.KEY_ALL_ACCESS);
		} else {
			env = Registry.localMachine.getKey("SYSTEM").getKey("CurrentControlSet").getKey("Control")
				.getKey("Session Manager").getKey("Environment", REGSAM.KEY_ALL_ACCESS);
		}
		path = env.getValue("Path").value_SZ;
		path ~= pathSeparator ~ installDir;
		env.setValue("Path", path);
		//import core.sys.windows.winuser; SendNotifyMessageW(HWND_BROADCAST,WM_SETTINGCHANGE,cast(ulong)null,cast(long)"Environment");
	} else {
		import std.file : exists,append,write;

		string profile;
		string installProfile = "\nexport PATH=$PATH" ~ pathSeparator ~ installDir;
		if (userMode)
			profile = "~/.profile".expandTilde;
		else
			profile = "/etc/profile";
		if (profile.exists)
			append(profile, installProfile);
		else {
			write(profile, installProfile);
		}
	}

	log("logout or reboot to finish install");
}
