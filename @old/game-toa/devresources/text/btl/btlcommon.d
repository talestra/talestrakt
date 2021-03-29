module btlcommon;

import std.stream, std.file;

Stream btlusu;

static this() {
	char[] fname = "../../BTL_USU.BIN";
	if (!std.file.exists(fname)) throw(new Exception(std.string.format("No existe el fichero '%s'", fname)));
	btlusu = new File(fname, FileMode.In | FileMode.Out);
}

Stream getBtlImageStream() {
	uint start, end;
	
	btlusu.position = 4;
	btlusu.read(start);
	btlusu.read(end);
	
	return new SliceStream(btlusu, start, end);	
}

Stream getBTSC(int n) {	
	uint start, end;
	
	btlusu.position = 15 * 4;
	btlusu.read(start);
	btlusu.read(end);
	
	Stream btscll = new SliceStream(btlusu, start, end);
	
	btscll.position = 4 + n * 4;
	btscll.read(start);
	btscll.read(end);
	
	return new SliceStream(btscll, start, end);
}
