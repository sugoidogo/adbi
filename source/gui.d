import tkd.tkdapplication;
import std.concurrency;
import std.stdio;
import core.time;
import common,adbi;

private Label userAction;
private Label status;
private Tid guiTid;

private void log(string s,int level=INFO){
    if((silent) || (!verbose && level==VERBOSE)) return;
    guiTid.send(level);
    guiTid.send(s);
}

private void install(Tid parent,string dir){
    common.log=&gui.log;
    guiTid=parent;
    adbi.installDir=dir;
    parent.send(NONE);
    adbi.start([]);
}
class GUI : TkdApplication {

    private Tid workTid;
    private int mode;
    private Frame frame;

    private void select(CommandArgs args){
        workTid.send(NONE);
        userAction.setText("Please wait");
        string s=(cast(Button)args.element).getText;
        workTid=spawn(&install,thisTid,s);
    }

    private void receiveString(string s){
        switch(mode){
            case NONE:
                new Button(frame,s).setCommand(&select).pack();
                return;
            case INFO:
                status.setText(s);
                break;
            default:
                throw new Exception("Ungrecognized signal received by gui thread:"~mode.stringof~":"~s);
        }
        mode=NONE;
    }

    private void receiveMode(int i){
        if(i==NONE) userAction.setText("Please Wait");
        mode=i;
    }

    private void idleCommand(CommandArgs args){
        while(receiveTimeout(seconds(-1),&receiveString,&receiveMode)){}
        this.mainWindow.setIdleCommand(&idleCommand,16);
    }

    override protected void initInterface(){
        frame=new Frame().pack();
        userAction=new Label(frame,"Select an install location").pack();
        status=new Label(frame,"Searching for pre-existing files...").pack();
        this.mainWindow.setIdleCommand(&idleCommand);
        workTid=spawn(&search,thisTid);
        this.mainWindow.setProtocolCommand(WindowProtocol.deleteWindow, delegate(CommandArgs args){
            workTid.send(NONE);
            this.exit();
        });
        this.mainWindow.setTitle("ADB Installer");
    }
}

void main(){
    common.log=&gui.log;
    guiTid=thisTid;
    new GUI().run();
}