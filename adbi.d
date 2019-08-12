/+ dub.sdl:
dependency "vibe-d" version="~>0.8.5"
targetPath "bin/$PLATFORM/$ARCH"
+/

import std.stdio : writeln;
import std.path;

auto adb=" adb";
auto fastboot=" fastboot";

bool sys,user,silent,verbose;
string installDir;

int installTools(){

	version(Windows){auto url="https://dl.google.com/android/repository/platform-tools-latest-windows.zip";}
	version(OSX){auto url="https://dl.google.com/android/repository/platform-tools-latest-darwin.zip";}
	version(linux){auto url="https://dl.google.com/android/repository/platform-tools-latest-linux.zip";}
	
	import std.zip,std.file,vibe.stream.operations,vibe.inet.urltransfer;

	download(url, delegate(scope data){
		auto zip=new ZipArchive(data.readAll());
		foreach (x;zip.directory()){
			auto path=buildNormalizedPath(installDir,x.name[15 .. $]);
			if(x.fileAttributes.attrIsFile){
				if(!path.dirName.exists){
					path.dirName.mkdirRecurse;
				}
				zip.expand(x);
				write(path, x.expandedData);
			} else {
				if(!path.exists){
					path.mkdirRecurse;
				}
			}
		}
	});
	return 0;
}

int installPath(){return 1;}

int searchPath(){return 1;}

int searchTools(){return 1;}

int searchProcess(){return 1;}

int install(){
	return installTools();
}

int search(){return 1;}

int main(string[] args){

	import std.getopt : getopt,defaultGetoptPrinter;
	import std.process : environment;

	auto xargs=getopt(args,
	"all-users|a","Install for all users.",&sys,
	"user|u","Install for current user.",&user,
	"silent|s","Silent standard output.",&silent,
	"verbose|v","Verbose standard output.",&verbose,
	"install-dir|i","Path to install directory.",&installDir
	);

	if(installDir){
		return install();
	}

	if(user || sys){

	auto append=buildNormalizedPath("Android","SDK","platform-tools");

	if(user){
		version(Win64){
			installDir=buildNormalizedPath(environment.get("LocalAppData"),append);
		}
		return install();
	}

	if(sys){
		version(Win64){
			installDir=buildNormalizedPath(environment.get("ProgramFiles"),append);
		}
		return install();
	}
	}

	defaultGetoptPrinter("Download platform-tools and add to PATH.",xargs.options);
	return 0;
}
