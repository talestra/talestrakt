module tales.scont.directory;

import tales.scont.generic, tales.common;
private import std.file, std.string, std.stdio, std.path, std.regexp, std.stream, std.intrinsic;

class FS_Entry : ContainerEntryWithStream {
}

class FS_Directory : FS_Entry {
	this(char[] path) {
		path = std.string.replace(path, "/", "\\");
		name = getBaseName(path);
		
		foreach (file; listdir(path)) {
			char[] rfile = path ~ "/" ~ file;
			if (isdir(rfile)) {
				add(new FS_Directory(rfile));
			} else {
				add(new FS_File(rfile));
			}			
		}
	}
}

class FS_File : FS_Entry {	
	char[] file;
	
	this(char[] file) {
		file = std.string.replace(file, "/", "\\");
		this.file = file;
		this.name = getBaseName(file);
	}
	
	protected Stream realopen(bool limited = true) {
		return new File(file);
	}
}
