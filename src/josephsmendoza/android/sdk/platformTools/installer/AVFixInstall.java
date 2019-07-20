package josephsmendoza.android.sdk.platformTools.installer;

import java.awt.Toolkit;
import java.awt.datatransfer.StringSelection;
import java.awt.image.BufferedImage;

import javax.swing.BoxLayout;
import javax.swing.JDialog;
import javax.swing.JLabel;

public class AVFixInstall implements Runnable {
	
	private String installPath;
	private String command;
	private String running;
	private String excludePath;
	private String excludeProcess;

	public AVFixInstall(String path) {
		installPath=path;
		command="sc query WinDefend";
		running="RUNNING";
		excludePath="powershell Add-MpPreference -ExclusionPath";
		excludeProcess="powershell Add-MpPreference -ExclusionProcess";
	}

	@Override
	public void run() {
		try {
			Runtime cmd=Runtime.getRuntime();
			String av=new String(cmd.exec(command).getInputStream().readAllBytes());
			if(av.contains(running)) {
				cmd.exec(excludePath+installPath);
				cmd.exec(excludeProcess+Common.adb);
				cmd.exec(excludeProcess+Common.fastboot);
			} else {
				JDialog frame=new JDialog();
				frame.setLayout(new BoxLayout(frame.getContentPane(),BoxLayout.Y_AXIS));
				frame.setIconImage(new BufferedImage(1, 1, BufferedImage.TYPE_INT_ARGB_PRE));
				frame.add(new JLabel("Windows Defender is not running!"));
				frame.add(new JLabel("Make exceptions in your antivirus for:"));
				frame.add(new JLabel("adb.exe"));
				frame.add(new JLabel("fastboot.exe"));
				frame.add(new JLabel(installPath));
				frame.add(new JLabel("The install path has been copied to your clipboard"));
				frame.setModal(true);
				frame.pack();
				frame.setLocationRelativeTo(null);
				Toolkit.getDefaultToolkit().getSystemClipboard().setContents(new StringSelection(installPath), null);
				frame.setVisible(true);
			}
		} catch (Exception e) {
			throw new RuntimeException(e);
		}
	}

}
