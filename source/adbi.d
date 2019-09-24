
import std.path;
import common;

bool sys,user,silent,verbose;
string installDir;

private void installTools(){
	import std.zip,std.file,std.net.curl,std.conv : octal;

	version(Windows) string url="https://dl.google.com/android/repository/platform-tools-latest-windows.zip";
	version(OSX) string url="https://dl.google.com/android/repository/platform-tools-latest-darwin.zip"; // @suppress(dscanner.suspicious.label_var_same_name)
	version(linux) string url="https://dl.google.com/android/repository/platform-tools-latest-linux.zip"; // @suppress(dscanner.suspicious.label_var_same_name)
	log("Downloading "~url,VERBOSE);

	ubyte[] data;
	auto http=HTTP(url);
	http.onReceive=(ubyte[] response){
		data~=response;
		return response.length;
	};
	http.perform();
	log("Download complete");
	
	auto zip=new ZipArchive(data);
	foreach (x;zip.directory){
		auto path=buildNormalizedPath(installDir,x.name[15 .. $]);
		if(x.compressedSize!=0){
			if(!path.dirName.exists) path.dirName.mkdirRecurse();
			if(path.exists) path.remove();
			zip.expand(x);
			log("Extracting "~x.name,VERBOSE);
			write(path, x.expandedData);
			setAttributes(path,octal!775);
		} else {
			try if(path.isFile) {
				path.remove;
				path.mkdirRecurse;
			} catch (Exception e) path.mkdirRecurse;
		}
	}
	log("Extraction complete");
}

private void installPath(){
	import std.process : environment;
	import std.algorithm.searching : canFind;
	string path=environment.get("PATH");
	if(path.canFind(installDir)){
		"Install folder is already in PATH".log();
		return;
	}

	version(Windows){
		import std.windows.registry:Registry,Key,REGSAM;
		Key env;
		if(user){
			env=Registry.currentUser.getKey("Environment",REGSAM.KEY_ALL_ACCESS);
		}
		if(sys){
			env=Registry.localMachine.getKey("SYSTEM").getKey("CurrentControlSet")
				.getKey("Control").getKey("Session Manager").getKey("Environment",REGSAM.KEY_ALL_ACCESS);
		}
		path=env.getValue("Path").value_SZ;
		path~=pathSeparator~installDir;
		env.setValue("Path",path);
		//import core.sys.windows.winuser; SendNotifyMessageW(HWND_BROADCAST,WM_SETTINGCHANGE,cast(ulong)null,cast(long)"Environment");
	} else {
		import std.file : append;
		if(user) append("~/.profile".expandTilde,"\nexport PATH=$PATH"~pathSeparator~installDir);
		if(sys) append("/etc/profile","\nexport PATH=$PATH"~pathSeparator~installDir);
	}

	"Install folder was added to PATH".log();
	"logout/login or reboot to coplete install".log();
}

void install(){
	if(user) "Installing for current user".log();
	if(sys) "Installing for all users".log();
	("Installing to " ~ installDir).log(VERBOSE);
	try{
	installTools();
	installPath();
	} catch (Exception e){
		log(cast(string)e.message,ERROR);
	}
}

void start(string[] args){
	//foreach (string s;args) log(s,VERBOSE);
	import std.getopt: getopt,defaultGetoptPrinter;
	import common:userDir,allUsersDir,isUserDir;
	auto xargs=getopt(args,
	"all-users|a","Install for all users.",&sys,
	"user|u","Install for current user.",&user,
	"silent|s","Silent standard output.",&silent,
	"verbose|v","Verbose standard output.",&verbose,
	"install-dir|i","Install to specified directory",&installDir);

	if(sys && user) throw new Exception("--all-users and --user cannot be used together");
	if(sys && !installDir) installDir=allUsersDir;
	if(user && !installDir) installDir=userDir;
	if(installDir && !sys && !user) {
		if(installDir.isUserDir) user=true;
		else sys=true;
	}
	if(!installDir && !sys && !user) {
		defaultGetoptPrinter("Download platform-tools and add to PATH.",xargs.options);
		return;
	}
	install();
}