import java.io.IOException;
import java.io.InputStream;
import java.net.MalformedURLException;
import java.net.URL;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.StandardOpenOption;
import java.nio.file.attribute.PosixFilePermissions;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public class adbi {

    private final String os;

    public adbi() throws Exception {
        switch (System.getProperty("os.name").substring(0, 3).toLowerCase()) {
            case "win": {
                os = "windows";
                break;
            }
            case "mac": {
                os = "darwin";
                break;
            }
            case "lin": {
                os = "linux";
                break;
            }
            default: {
                throw new Exception("unknown os");
            }
        }

    }

    public String getHome() {
        if (os == "windows") {
            return System.getenv("HOMEPATH");
        } else {
            return System.getenv("HOME");
        }
    }

    public boolean isPathPrivileged(String path) {
        return path.startsWith(getHome());
    }

    public String getCannonicalPath(String path) {
        return Paths.get(path).toAbsolutePath().normalize().toString();
    }

    public String getDefaultInstallPath(boolean privileged) {
        String append = "/Android/SDK/platform-tools";
        if (privileged) {
            switch (os) {
                case "windows": {
                    return System.getenv("programfiles") + append;
                }
                case "darwin": {
                    return "/Library" + append;
                }
                default: {
                    return "/opt" + append;
                }
            }
        } else {
            switch (os) {
                case "windows": {
                    return System.getenv("localappdata") + append;
                }
                case "darwin": {
                    return System.getenv("HOME") + "/Library" + append;
                }
                default: {
                    return System.getenv("HOME") + append;
                }
            }
        }
    }

    private InputStream getUrlStream() throws MalformedURLException, IOException {
        return new URL("https://dl.google.com/android/repository/platform-tools-latest-" + os + ".zip").openStream();
    }

    private boolean isNeeded(String name, int mode) {
        switch (mode) {
            case (1): {
                if (name.startsWith("fastboot"))
                    return true;
            }
            case (0): {
                return name.toLowerCase().startsWith("adb");
            }
            default: {
                return true;
            }
        }
    }

    public void download(String dir, int mode) throws MalformedURLException, IOException {
        ZipInputStream zInputStream = new ZipInputStream(getUrlStream());
        ZipEntry zEntry = zInputStream.getNextEntry();
        while (zEntry != null) {
            String name = zEntry.getName().substring(15);
            if (isNeeded(name, mode) && zEntry.getSize() > 0) {
                Path dest = Paths.get(dir, name);
                Files.createDirectories(dest.getParent());
                Files.write(dest, zInputStream.readAllBytes());
                if (os != "windows") {
                    Files.setPosixFilePermissions(dest, PosixFilePermissions.fromString("755"));
                }
            }
            zEntry = zInputStream.getNextEntry();
        }
    }

    public void install(String dir, boolean privileged) throws Exception {
        if (System.getenv("PATH").contains(dir)) {
            return;
        }
        if (os == "windows") {
            installWindows(dir, privileged);
        } else {
            installPosix(dir, privileged);
        }
    }

    private void installPosix(String dir, boolean privileged) throws IOException {
        Path profile = getProfilePath(privileged);
        String path = "export PATH=$PATH:\"" + dir + "\"";
        if (Files.exists(profile) && Files.readAllLines(profile).add(path)) {
            Files.writeString(profile, "\n" + path, StandardOpenOption.APPEND);
        } else {
            Files.writeString(profile, path);
        }
    }

    private Path getProfilePath(boolean privileged) {
        if (privileged) {
            return Paths.get("/etc/profile");
        } else {
            Path home = Paths.get(System.getenv("HOME"));
            if (os == "darwin") {
                return home.resolve(".bash_profile");
            } else {
                return home.resolve(".bashrc");
            }
        }
    }

    private void installWindows(String dir, boolean privileged) throws Exception {
        String type = "REG_EXPAND_SZ";
        String valueName = "Path";
        String keyName = getKeyName(privileged);

        String path = regQuery(keyName, valueName, type);
        if (path.contains(dir)) {
            return;
        }
        regAdd(keyName, valueName, type, path + ";" + dir + ";");
    }

    private void regAdd(String keyName, String valueName, String type, String data) throws Exception {
        Process p = Runtime.getRuntime()
                .exec(new String[] { "reg", "add", keyName, "/v", valueName, "/t", type, "/d", data, "/f" });
        if (p.waitFor() != 0) {
            throw new Exception(new String(p.getErrorStream().readAllBytes()));
        }
    }

    private String regQuery(String keyName, String valueName, String type) throws Exception {
        Process p = Runtime.getRuntime().exec(new String[] { "reg", "query", keyName, "/v", valueName });
        if (p.waitFor() != 0) {
            throw new Exception(new String(p.getErrorStream().readAllBytes()));
        }
        return new String(p.getInputStream().readAllBytes()).replace(keyName, "").replace(valueName, "")
                .replace(type, "").trim();
    }

    private String getKeyName(boolean privileged) {
        if (privileged) {
            return "HKEY_LOCAL_MACHINE\\SYSTEM\\CurrentControlSet\\Control\\Session Manager\\Environment";
        } else {
            return "HKEY_CURRENT_USER\\Environment";
        }
    }
}