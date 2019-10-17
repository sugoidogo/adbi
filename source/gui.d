import tkd.tkdapplication, tkd.widget.widget;
import adbi;
import std.concurrency, std.parallelism, std.process, std.file, std.regex,
    std.path, std.string, std.algorithm.searching, std.stdio, std.uni;
import core.time;

string[] skip = ["temp"];

Widget packPreset(Widget w) {
    return w.pack(0, 0, GeometrySide.top, GeometryFill.both, AnchorPosition.center, true);
}

bool isWriteable(DirEntry d) {
    try
        File(d.name, "a").close();
    catch (Exception e)
        return false;
    return true;
}

bool isInstallable(DirEntry d) {
    if (!d.isWriteable)
        return false;
    foreach (s; skip) {
        if (d.name.toLower.canFind(s)) {
            return false;
        }
    }
    return true;
}

class Application : TkdApplication {

    private Label instructionLabel;
    private Label statusLabel;
    private Tid searchThread;

    enum {
        STATUS = LogLevel.max + 1,
        INSTRUCT,
        OPTION,
        KILL
    }

    static void search() {
        version (Windows) {
            skip ~= "recycle.bin";
            string regex = "(.*)(\\\\)(adb.exe|fastboot.exe)($)";
            string[] dirs = [
                "C:\\Program Files", "C:\\Program Files (x86)",
                "C:" ~ environment.get("HOMEPATH"), "C:\\"
            ];
        } else
            string regex = "(.*)(\\/)(adb|fastboot)($)";
        version (linux) string[] dirs = ["/usr", "/opt"];
        version (OSX) string[] dirs = ["/Library", "/Applications"];
        version (Posix) {
            dirs ~= ["~".expandTilde, "/"];
        }
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
                        if (!results.canFind(s) && d.isInstallable) {
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
        results ~= [defaultAllUsersDir, defaultUserDir, ""];
        foreach (string dir; dirs) {
            search(DirEntry(dir));
        }
        log("Search done");
    }

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
        } catch (immutable Exception e) {
            ownerTid.send(e);
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
            }).packPreset();
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

    private void receiveException(immutable Exception e) {
        throw e;
    }

    private void idleCommand(CommandArgs args) {
        this.mainWindow.setIdleCommand(&idleCommand);
        receiveTimeout(seconds(-1), &receiveString, &receiveInt, &receiveException);
    }

    private void exitCommand(CommandArgs args) {
        this.exit();
    }

    private void directoryDialog(CommandArgs args) {
        string dir = new DirectoryDialog().show().getResult();
        if (dir.isDir)
            spawn(&install, dir);
    }

    override protected void initInterface() {
        this.mainWindow.setMinSize(300, 0);
        instructionLabel = new Label("Please wait").pack();
        statusLabel = new Label("Loading").pack();
        new Button("Manually select folder").setCommand(&directoryDialog).packPreset();
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
