import adbi,common;

void main(string[] args){
	common.log=&cli.log;
	try start(args);
	catch (Exception e){
		(cast(string)e.message).log(ERROR);
	}
}

private void log(string message,int level=INFO){
	if((silent && level!=ERROR) || (!verbose && level==VERBOSE)) return;
	if(level==ERROR){
		import std.stdio : stderr;
		stderr.writeln(message);
		return;
	}
	import std.stdio : writeln;
	writeln(message);
}