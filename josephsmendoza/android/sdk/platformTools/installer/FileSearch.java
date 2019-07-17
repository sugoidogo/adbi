package josephsmendoza.android.sdk.platformTools.installer;

import java.io.IOException;
import java.nio.file.FileVisitResult;
import java.nio.file.FileVisitor;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.nio.file.attribute.BasicFileAttributes;

public class FileSearch implements FileVisitor<Path>,Runnable {
	
	private String matchRegex=".*adb.exe|.*fastboot.exe";
	private String skipRegex=".*Recycle\\.Bin|.*Temp.*";
	private Path startPath=getRoot();

	private Path getRoot() {
		if(Common.OS=="WIN"){
			return Paths.get("C:\\");
		}
		return Paths.get("/");
	}

	@Override
	public FileVisitResult preVisitDirectory(Path dir, BasicFileAttributes attrs) throws IOException {
		if(dir.toAbsolutePath().toString().matches(skipRegex)) {
			return FileVisitResult.SKIP_SUBTREE;
		} else {
			return FileVisitResult.CONTINUE;
		}
	}

	@Override
	public FileVisitResult visitFile(Path file, BasicFileAttributes attrs) throws IOException {
		Path absolutePath=file.toAbsolutePath();
		if(absolutePath.toString().matches(matchRegex))Common.installPaths.add((absolutePath.getParent().toString()));
		return FileVisitResult.CONTINUE;
	}

	@Override
	public FileVisitResult visitFileFailed(Path file, IOException exc) throws IOException {
		return FileVisitResult.CONTINUE;
	}

	@Override
	public FileVisitResult postVisitDirectory(Path dir, IOException exc) throws IOException {
		return FileVisitResult.CONTINUE;
	}

	@Override
	public void run() {
		try {
			Files.walkFileTree(startPath, this);
		} catch (IOException e) {
			throw new RuntimeException(e);
		}
		Common.searchComplete=true;
	}

}
