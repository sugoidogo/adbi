import picocli.CommandLine;
import picocli.CommandLine.Command;
import picocli.CommandLine.Option;
import picocli.CommandLine.ParseResult;

@Command(name = "adbi", description = "install adb", mixinStandardHelpOptions = true, version = "beta")
public class cli implements Runnable {
    @Option(names = { "-i", "--install-dir" }, description = "directory to install to")
    String dir;
    @Option(names = { "-u", "--user-mode" }, description = "unpriveleged install, current user only")
    boolean user;
    @Option(names = { "-f", "--add-fastboot" }, description = "include fastboot")
    boolean fastboot;
    @Option(names = { "-a", "--add-all" }, description = "include everything")
    boolean all;
    @Option(names = { "-d", "--download-only" }, description = "do not try to add adb to PATH")
    boolean downloadOnly;

    public static void main(String[] args) {
        new cli(args).run();
    }

    public cli(String[] args) {
        CommandLine cli = new CommandLine(this);
        ParseResult argv = cli.parseArgs(args);
        if (argv.isUsageHelpRequested()) {
            cli.usage(System.err);
            System.exit(0);
        }
        if (argv.isVersionHelpRequested()) {
            cli.printVersionHelp(System.err);
            System.exit(0);
        }
    }

    @Override
    public void run() {
        int mode = 0;
        if (fastboot)
            mode += 1;
        if (all)
            mode += 2;
        try {
            adbi adbi = new adbi();
            if (dir == null)
                dir = adbi.getDefaultInstallPath(!user);
            else{
                if(!user && !adbi.isPathPrivileged(dir)){
                    user=true;
                    System.out.println("User directory specified, switching to user mode");
                }
            }
            dir = adbi.getCannonicalPath(dir);
            adbi.download(dir, mode);
            if (!downloadOnly) {
                adbi.install(dir, !user);
            }
        } catch (Exception e) {
            e.printStackTrace();
            System.exit(e.hashCode());
        }

    }
}