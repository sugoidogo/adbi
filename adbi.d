/+ dub.sdl:
dependency "vibe-d" version="~>0.8.5"
targetPath "bin/$PLATFORM/$ARCH"
+/

import std.path;
import std.stdio : writeln;
import std.algorithm.searching : canFind;
import std.process : environment;

bool sys,user,silent,verbose;
string installDir;

int installTools(){
	import std.zip,std.file,vibe.stream.operations,vibe.inet.urltransfer,std.conv : octal;

	version(Windows) string url="https://dl.google.com/android/repository/platform-tools-latest-windows.zip";
	version(OSX) string url="https://dl.google.com/android/repository/platform-tools-latest-darwin.zip";
	version(linux) string url="https://dl.google.com/android/repository/platform-tools-latest-linux.zip";

	download(url, (scope data){
		auto zip=new ZipArchive(data.readAll());
		"Download complete".writeln();
		foreach (x;zip.directory){
			auto path=buildNormalizedPath(installDir,x.name[15 .. $]);
			if(x.compressedSize!=0){
				if(!path.dirName.exists) path.dirName.mkdirRecurse();
				if(path.exists) path.remove();
				zip.expand(x);
				write(path, x.expandedData);
				setAttributes(path,octal!775);
			} else {
				try if(path.isFile) path.remove;
				catch (Exception e) path.mkdirRecurse;
			}
		}
	});
	"Extraction complete".writeln();
	return 0;
}

int installPath(){
	string path=environment.get("PATH");
	if(path.canFind(installDir)){
		"Install folder is already in PATH".writeln;
		return 0;
	}

	version(Windows){
		import std.windows.registry;
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

	"Install folder was added to PATH".writeln();
	"logout/login or reboot to coplete install".writeln();
	return 0;
}

int install(){
	if(user) "Installing for current user".writeln();
	if(sys) "Installing for all users".writeln();
	("Installing to " ~ installDir).writeln();
	return installTools() + installPath();
}

int main(string[] args){

	import std.getopt : getopt,defaultGetoptPrinter;

	auto xargs=getopt(args,
	"all-users|a","Install for all users.",&sys,
	"user|u","Install for current user.",&user,
	//"silent|s","Silent standard output.",&silent,
	//"verbose|v","Verbose standard output.",&verbose,
	"install-dir|i","Install to specified directory",&installDir
	);

	if(installDir){
		installDir=installDir.buildNormalizedPath.absolutePath;
		if(!sys && !user){
			string allHome="~".expandTilde.dirName;
			if(!allHome.isRooted && installDir.canFind(allHome)) user=true;
			else sys=true;
		}
		return install();
	}

	if(user || sys){
		auto append=buildNormalizedPath("Android","SDK","platform-tools");

		if(user){
			version(Windows)installDir=buildNormalizedPath(environment.get("LocalAppData"),append);
			version(linux)installDir=buildNormalizedPath("~".expandTilde,append);
			version(OSX)installDir=buildNormalizedPath("~/Library".expandTilde,append);
			return install();
		}

		if(sys){
			version(Windows)installDir=buildNormalizedPath(environment.get("ProgramFiles"),append);
			version(linux)installDir=buildNormalizedPath("/opt",append);
			version(OSX)installDir=buildNormalizedPath("/Library",append);
			return install();
		}
	}

	defaultGetoptPrinter("Download platform-tools and add to PATH.",xargs.options);
	return 0;
}
