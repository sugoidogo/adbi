package josephsmendoza.android.sdk.platformTools.installer;

import java.awt.GridLayout;
import java.awt.image.BufferedImage;

import javax.swing.BoxLayout;
import javax.swing.JButton;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JPanel;
import javax.swing.SwingConstants;
import javax.swing.UIManager;
import javax.swing.UnsupportedLookAndFeelException;


public class GUI implements Runnable {
	
	JFrame frame;
	JPanel statusPanel;
	JLabel searchingLabel;
	JPanel selectionPanel;

	public GUI() throws ClassNotFoundException, InstantiationException, IllegalAccessException, UnsupportedLookAndFeelException {
		UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
		
		frame=new JFrame("ADB Installer");
		frame.setLayout(new BoxLayout(frame.getContentPane(),BoxLayout.Y_AXIS));
		frame.setIconImage(new BufferedImage(1, 1, BufferedImage.TYPE_INT_ARGB_PRE));
		frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
		
		
		statusPanel=new JPanel();
		statusPanel.setLayout(new GridLayout(0,1));
		frame.add(statusPanel);
		
		JLabel selectLabel=new JLabel("Select an install location");
		selectLabel.setHorizontalAlignment(SwingConstants.CENTER);
		statusPanel.add(selectLabel);
		
		searchingLabel=new JLabel("Searching for pre-existing files...");
		searchingLabel.setHorizontalAlignment(SwingConstants.CENTER);
		statusPanel.add(searchingLabel);
		
		selectionPanel=new JPanel();
		selectionPanel.setLayout(new GridLayout(0,1));
		frame.add(selectionPanel);
		
		frame.setLocationRelativeTo(null);
		frame.setVisible(true);
	}

	@Override
	public void run() {
		int lastSize=0;
		while (!Common.FileSearchComplete) {
			if(lastSize<Common.installPaths.size()) {
				update();
				lastSize=Common.installPaths.size();
			}
			try {
				Thread.sleep(100);
			} catch (InterruptedException e) {
				throw new RuntimeException(e);
			}
		}
		statusPanel.remove(searchingLabel);
		frame.pack();
		while(!Common.FileInstallComplete || !Common.PathInstallComplete) {
			try {
				Thread.sleep(100);
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
		}
		JLabel done=new JLabel("Done");
		done.setHorizontalAlignment(SwingConstants.CENTER);
		frame.setContentPane(done);
		frame.pack();
	}

	private void update() {
		selectionPanel.removeAll();
		for(String path:Common.installPaths) {
			JButton selectionButton=new JButton(path);
			selectionButton.setHorizontalAlignment(SwingConstants.LEFT);
			selectionButton.addActionListener(l -> install(path));
			selectionPanel.add(selectionButton);
		}
		frame.pack();
	}

	private void install(String path) {
		JLabel installing=new JLabel("Installing...");
		installing.setHorizontalAlignment(SwingConstants.CENTER);
		frame.setContentPane(installing);
		frame.pack();
		Common.install(path);
	}
}
