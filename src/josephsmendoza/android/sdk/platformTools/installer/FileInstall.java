package josephsmendoza.android.sdk.platformTools.installer;

import java.io.File;
import java.io.FileOutputStream;
import java.net.URL;
import java.util.zip.ZipEntry;
import java.util.zip.ZipInputStream;

public class FileInstall implements Runnable {
	
	private String installPath;

	public FileInstall(String path) {
		installPath=path;
	}

	@Override
	public void run() {
		try {
			ZipInputStream ziStream=new ZipInputStream(new URL(getURL()).openStream());
			ZipEntry zEntry;
			while((zEntry=ziStream.getNextEntry())!=null) {
				File f=new File(installPath+zEntry.getName().replaceAll("platform-tools", ""));
				int size=(int) zEntry.getSize();
				if(size==0) {
					f.mkdirs();
					continue;
				}
				if(!f.exists()) {
					f.createNewFile();
				}
				FileOutputStream foStream=new FileOutputStream(f);
				foStream.write(ziStream.readNBytes(size));
				foStream.flush();
				foStream.close();
			}
			
			Common.FileInstallComplete=true;
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
	}

	private String getURL() {
		switch(Common.OS) {
		case "WIN":
			return "https://dl.google.com/android/repository/platform-tools-latest-windows.zip";
		}
		return null;
	}

}
