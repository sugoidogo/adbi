import tkd.tkdapplication;
import adbi;
import std.concurrency, std.parallelism, std.process, std.file, std.regex,
    std.path, std.string, std.algorithm.searching;
import core.time;

class Application : TkdApplication {

    enum {
        STATUS = LogLevel.max + 1,
        INSTRUCT,
        OPTION,
        KILL
    }

    static void search() {
        version (Windows) {
            string regex = "(.*)(\\\\)(adb.exe|fastboot.exe)($)";
            string[] dirs = [
                "C:\\Program Files", "C:\\Program Files (x86)",
                environment.get("HOMEPATH"), "C:\\"
            ];
        } else
            string regex = "(.*)(\\/)(adb|fastboot)($)";
        version (linux) string[] dirs = ["/usr", "/opt"];
        version (OSX) string[] dirs = ["/Library", "/Applications"];
        version (Posix)
            dirs ~= ["~".expandTilde, "/"];
        adbi.log = &Application.log;
        string[] results;
        void search(DirEntry dir) {
            try {
                foreach (DirEntry d; dirEntries(dir.name, SpanMode.shallow)) {
                    receiveTimeout(seconds(-1), delegate(int i) {
                        if (i != KILL) {
                            log("Unsupported signal received by search thread", ERROR);
                            return;
                        } else
                            return;
                    });
                    if (d.isDir)
                        search(d);
                    else if (d.name.matchFirst(regex)) {
                        string s = d.name.dirName.strip;
                        if (!results.canFind(s) && s != "") {
                            results ~= s;
                            log(s, OPTION);
                        }
                    }
                }
            } catch (Exception e) {
                log(cast(string) e.message, ERROR);
            }
        }

        log("Searching for install locations");
        log(defaultAllUsersDir, OPTION);
        log(defaultUserDir, OPTION);
        log("Select install location", INSTRUCT);
        results ~= [defaultAllUsersDir, defaultUserDir];
        foreach (string dir; dirs) {
            search(DirEntry(dir));
        }
    }

    private Frame frame;
    private Label instructionLabel;
    private Label statusLabel;
    private Tid searchThread;

    static void log(string message, int messageMode = INFO) {
        ownerTid.send(messageMode);
        ownerTid.send(message);
    }

    int mode;

    private void receiveInt(int i) {
        mode = i;
    }

    static void install(string dir) {
        adbi.log = &Application.log;
        if (dir.isUserDir)
            adbi.userMode = true;
        try {
            log("Please Wait", INSTRUCT);
            adbi.installTools(dir);
            adbi.installPath(dir);
            log("You can close this window", INSTRUCT);
        } catch (Exception e) {
            log(cast(string) e.message, ERROR);
        }
    }

    private void receiveString(string message) {
        switch (mode) {
        case INFO:
        case STATUS:
            statusLabel.setText(message);
            break;
        case INSTRUCT:
            instructionLabel.setText(message);
            break;
        case OPTION:
            new Button(message).setCommand(delegate(CommandArgs args) {
                spawn(&install, message);
            }).pack();
            break;
        case ERROR:
            import std.stdio;

            stderr.writeln(message);
            break;
        default:
            break;
        }
        mode = INFO;
    }

    private void idleCommand(CommandArgs args) {
        this.mainWindow.setIdleCommand(&idleCommand);
        receiveTimeout(seconds(-1), &receiveString, &receiveInt);
    }

    private void exitCommand(CommandArgs args) {
        this.exit();
    }

    override protected void initInterface() {
        frame = new Frame().pack();
        instructionLabel = new Label(frame, "Please wait").pack();
        statusLabel = new Label(frame, "Loading").pack();
        this.mainWindow.setIdleCommand(&idleCommand);
        this.mainWindow.setProtocolCommand(WindowProtocol.deleteWindow, &exitCommand);
        searchThread = spawn(&search);
    }
}

void main() {
    adbi.log = &Application.log;
    auto app = new Application();
    app.run();
}
