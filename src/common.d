/+ dub.sdl:
targetPath "../bin/$PLATFORM/$ARCH"
+/

import std.stdio,std.getopt,std.path,std.file,std.regex,std.string,std.process,std.algorithm.searching;

private string APPEND;

int main(string[] args){
    getopt(args,
    "all-users|a",&allUsers,
    "user|u",&user,
    "search|s",&search,
    "find-mode|f",&findMode);
    return 0;
}

private void findMode(string opt,string installDir){
    installDir=installDir.expandTilde.buildNormalizedPath.absolutePath;
    string allHome="~".expandTilde.dirName;
	if(allHome!=allHome.rootName && installDir.startsWith(allHome)) "--user".writeln;
	else "--all-users".writeln;
}

private string append(){
    if(!APPEND){
        APPEND=buildNormalizedPath("Android","SDK","platform-tools");
    }
    return APPEND;
}

private void allUsers(){
    version(Windows) string dir="/Program Files";
    version(linux) string dir="/opt";
    version(OSX) string dir="/Library";
    buildNormalizedPath(dir,append).writeln();
}

private void user(){
    version(Windows) string dir="~/AppData/Local";
    version(linux) string dir="~";
    version(OSX) string dir="~/Library";
    buildNormalizedPath(dir.expandTilde,append).writeln();
}

private void search(){
    version (Windows){
        string regex="(.*)(\\\\)(adb.exe|fastboot.exe)($)";
        string[] dirs=["\\Program Files","\\Program Files (x86)",environment.get("HOMEPATH"),"\\"];
    } else string regex="(.*)(\\/)(adb|fastboot)($)";
    version (linux) string[] dirs=["/usr","/opt"];
    version (OSX) string [] dirs=["/Library","/Applications"];
    version (Posix) dirs~=["~".expandTilde,"/"];

    string[] results;
    void search(DirEntry dir){
        try foreach(DirEntry d;dirEntries(dir.name,SpanMode.shallow)){
            if(d.isDir) search(d);
            else if(d.name.matchFirst(regex)){
                string s=d.name.dirName.strip;
                if(!results.canFind(s) && s!=""){
                    results~=s;
                    writeln(s);
                }
            }
        } catch (Exception e){
            std.stdio.stderr.writeln(e.message);
        }
    }

    foreach (string dir;dirs){
        search(DirEntry(dir));
    }
}