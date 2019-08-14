/+ dub.sdl:
dependency "tkd" version="1.1.13"
targetPath "bin/$PLATFORM/$ARCH"
copyFiles \
	"$TCLTK_PACKAGE_DIR/dist/$ARCH/tcl86t.dll" \
	"$TCLTK_PACKAGE_DIR/dist/$ARCH/tk86t.dll" \
	"$TCLTK_PACKAGE_DIR/dist/library" \
	platform="windows"
+/

import tkd.tkdapplication;                               

class GUI : TkdApplication                       
{
	override protected void initInterface()              
	{
		auto frame = new Frame().pack(5);
		new Label(frame, "Select an install location").pack(0);
		auto searchLabel=new Label(frame,"Searching for pre-existing files...").pack(0);
		new Button(frame, "System").pack(0);
		new Button(frame, "User").pack(0);
		new Button(frame, "Mixed").pack(0);
	}
}

void main(string[] args)
{
	auto gui = new GUI();
	gui.run();
}
