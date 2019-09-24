
import std.stdio,std.concurrency,std.path,std.file,std.regex,std.string,std.process,std.algorithm.searching;
import core.time;

private string APPEND;
private string ALL_USER_DIR;
private string USER_DIR;
version (Windows) string ENV_HOME="HOMEPATH";
version (Posix) string ENV_HOME="HOME";
enum {NONE,INFO,VERBOSE,ERROR};
void function(string,int=INFO) log;

bool isUserDir(string installDir){
    string allHome=environment.get(ENV_HOME).dirName;
	if(allHome!=allHome.rootName && installDir.startsWith(allHome)) return true;
	else return false;
}

private string append(){
    if(!APPEND){
        APPEND=buildNormalizedPath("Android","SDK","platform-tools");
    }
    return APPEND;
}

string allUsersDir(){
    version(Windows) string dir="/Program Files";
    version(linux) string dir="/opt";
    version(OSX) string dir="/Library";
    return buildNormalizedPath(dir,append);
}

string userDir(){
    version(Windows) string dir=environment.get(ENV_HOME)~"/AppData/Local";
    version(linux) string dir="~";
    version(OSX) string dir="~/Library";
    return buildNormalizedPath(dir.expandTilde,append);
}

void search(Tid parent){
    version (Windows){
        string regex="(.*)(\\\\)(adb.exe|fastboot.exe)($)";
        string[] dirs=["\\Program Files","\\Program Files (x86)",environment.get("HOMEPATH"),"\\"];
    } else string regex="(.*)(\\/)(adb|fastboot)($)";
    version (linux) string[] dirs=["/usr","/opt"];
    version (OSX) string [] dirs=["/Library","/Applications"];
    version (Posix) dirs~=["~".expandTilde,"/"];

    string[] results;
    bool stop;
    void search(DirEntry dir){
        try foreach(DirEntry d;dirEntries(dir.name,SpanMode.shallow)){
            receiveTimeout(seconds(-1),
                delegate(int i){
                    if(i!=NONE) throw new Exception("Unsupported signal received by search thread");
                    else stop=true;
                }
            );
            if(stop) break;
            if(d.isDir) search(d);
            else if(d.name.matchFirst(regex)){
                string s=d.name.dirName.strip;
                if(!results.canFind(s) && s!=""){
                    results~=s;
                    parent.send(s);
                }
            }
        } catch (Exception e){
            std.stdio.stderr.writeln(e.message);
        }
    }
    parent.send(allUsersDir);
    parent.send(userDir);
    results~=[allUsersDir,userDir];
    foreach (string dir;dirs){
        search(DirEntry(dir));
    }
    parent.send(NONE);
}