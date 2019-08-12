/+ dub.sdl:
dependency "tkd" version="1.1.13"
targetPath "bin/$PLATFORM/$ARCH"
copyFiles \
	"$TCLTK_PACKAGE_DIR/dist/$ARCH/tcl86t.dll" \
	"$TCLTK_PACKAGE_DIR/dist/$ARCH/tk86t.dll" \
	"$TCLTK_PACKAGE_DIR/dist/library" \
	platform="windows"
+/

import tkd.tkdapplication;                               // Import Tkd.

class Application : TkdApplication                       // Extend TkdApplication.
{
	private void exitCommand(CommandArgs args)           // Create a callback.
	{
		this.exit();                                     // Exit the application.
	}

	override protected void initInterface()              // Initialise user interface.
	{
		auto frame = new Frame(2, ReliefStyle.groove)    // Create a frame.
			.pack(10);                                   // Place the frame.

		auto label = new Label(frame, "Hello World!")    // Create a label.
			.pack(10);                                   // Place the label.

		auto exitButton = new Button(frame, "Exit")      // Create a button.
			.setCommand(&this.exitCommand)               // Use the callback.
			.pack(10);                                   // Place the button.
	}
}

void main(string[] args)
{
	auto app = new Application();                        // Create the application.
	app.run();                                           // Run the application.
}
