import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.LayoutManager;
import java.io.File;

import javax.swing.ButtonGroup;
import javax.swing.JButton;
import javax.swing.JCheckBox;
import javax.swing.JComboBox;
import javax.swing.JFileChooser;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JRadioButton;
import javax.swing.UIManager;

public class gui extends JFrame {

    private static final long serialVersionUID = -2628083151723078126L;
    private final adbi adbi;
    private final gui gui = this;
    private final LayoutManager manager = new GridBagLayout();
    private final GridBagConstraints constraints = new GridBagConstraints();
    private final String title = "ADBi";
    private final JComboBox<String> installPath = new JComboBox<String>();
    private final JButton startButton = new JButton("Start");
    private final JRadioButton adb = new JRadioButton("adb");
    private final JRadioButton fastboot = new JRadioButton("adb and fastboot");
    private final JRadioButton all = new JRadioButton("everything");
    private final ButtonGroup components = new ButtonGroup();
    private final JLabel componentsLabel = new JLabel("From platform-tools, install:");
    private final JButton selectFolderButton = new JButton(UIManager.getIcon("FileView.directoryIcon"));
    private final JLabel installPathLabel = new JLabel("Install to:");
    private final JCheckBox download = new JCheckBox("Download/Update only, don't install");
    private JFileChooser fileChooser = new JFileChooser();

    public static void main(String[] args) {
        try {
            UIManager.setLookAndFeel(UIManager.getSystemLookAndFeelClassName());
            new gui();
        } catch (Exception e) {
            e.printStackTrace(System.err);
            JOptionPane.showMessageDialog(null, e.getMessage(), e.getClass().getSimpleName(), JOptionPane.ERROR_MESSAGE);
            System.exit(1);
        }
    }

    public gui() throws Exception {
        adbi = new adbi();
        setDefaultCloseOperation(EXIT_ON_CLOSE);
        setTitle(title);
        setLayout(manager);

        constraints.gridx = GridBagConstraints.RELATIVE;
        constraints.gridy = 1;
        constraints.fill = GridBagConstraints.HORIZONTAL;
        add(installPath, constraints);

        constraints.fill = GridBagConstraints.NONE;
        add(selectFolderButton, constraints);

        constraints.gridx = 0;
        constraints.gridy = 0;
        constraints.fill = GridBagConstraints.HORIZONTAL;
        constraints.gridwidth = GridBagConstraints.REMAINDER;
        add(installPathLabel, constraints);

        constraints.gridy = 2;
        add(componentsLabel, constraints);

        constraints.gridy = GridBagConstraints.RELATIVE;
        add(adb, constraints);
        add(fastboot, constraints);
        add(all, constraints);
        add(download, constraints);
        add(startButton, constraints);

        components.add(adb);
        components.add(fastboot);
        components.add(all);
        adb.setSelected(true);

        installPath.addItem(adbi.getDefaultInstallPath(true));
        installPath.addItem(adbi.getDefaultInstallPath(false));
        installPath.setSelectedIndex(0);
        installPath.setEditable(true);

        pack();
        selectFolderButton.addActionListener(l -> selectFolder());
        startButton.addActionListener(l -> start());
        setVisible(true);

        fileChooser.setFileSelectionMode(JFileChooser.DIRECTORIES_ONLY);
    }

    private void start() {
        JPanel statusPanel = new JPanel(manager);
        JLabel statusLabel = new JLabel("Setting up");
        statusPanel.add(statusLabel, constraints);
        gui.setContentPane(statusPanel);
        int x = 0;
        if (fastboot.isSelected())
            x += 1;
        if (all.isSelected())
            x += 2;
        final int mode = x;
        final String dir = adbi.getCannonicalPath((String) installPath.getSelectedItem());
        final boolean privileged = adbi.isPathPrivileged(dir);
        new Thread(() -> {
            try {
                statusLabel.setText("Downloading");
                adbi.download(dir, mode);
                if (!download.isSelected()) {
                    statusLabel.setText("Installing");
                    adbi.install(dir, privileged);
                }
                JOptionPane.showMessageDialog(gui, "Done", "ADBi", JOptionPane.INFORMATION_MESSAGE);
                System.exit(0);
            } catch (Exception e) {
                e.printStackTrace(System.err);
                JOptionPane.showMessageDialog(gui, e.getMessage() + "\n" + e.getClass().getSimpleName(),
                        "Install Failed", JOptionPane.ERROR_MESSAGE);
                System.exit(1);
            }
        }).start();
    }

    private void selectFolder() {
        fileChooser.showOpenDialog(gui);
        try{
        installPath.setSelectedItem(fileChooser.getSelectedFile().getAbsolutePath());
        }catch(NullPointerException e){
            //non-issue
        }
    }
}