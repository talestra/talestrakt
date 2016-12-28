import std.file, std.stream, std.string, std.stdio, std.regexp, std.date;
import common;

string tempDir = "./temp";


Progress progress;

class SELFPAK {
	Stream[] slices;
	int _align = 4;
	
	this(Stream stream) {
		//this.stream = stream;
		readPointers(stream);
	}
	
	void readPointers(Stream stream) {
		uint[] positions;
		uint count, position;

		stream.read(count);
		for (int n = 0; n < count; n++) { stream.read(position); positions ~= position; }
		positions ~= stream.size;
		
		for (int n = 1; n < positions.length; n++) slices ~= new SliceStream(stream, positions[n - 1], positions[n]);
	}

	long nextBound(long v, int _align = 4) { if (v % _align) v += _align - (v % _align); return v; }

	void write(Stream stream) {
		stream.write(cast(uint)slices.length);
		uint position = 4 + slices.length * 4;
		foreach (slice; slices) { stream.write(cast(uint)position); position += nextBound(slice.size, _align); }
		foreach (slice; slices) { stream.copyFrom(slice); while (stream.position % _align) stream.write(cast(ubyte)0); }
	}

	Stream opIndex(uint index) { return new SliceStream(slices[index], 0, slices[index].size); }
	Stream opIndexAssign(Stream stream, uint index) { return slices[index] = new SliceStream(stream, 0, stream.size); }
	uint length() { return slices.length; }
	Stream stream() {
		auto stream = new MemoryStream();
		write(stream); stream.position = 0;
		return stream;
	}

	static SELFPAK opCall(Stream stream) { return new SELFPAK(stream); }
}

class SELFPAK_NoCount :  SELFPAK{
	this(Stream stream) {
		//this._align = 0x10;
		this._align = 4;
		super(stream);
	}

	void write(Stream stream) {
		uint position = slices.length * 4;
		uint[] pointers = new uint[slices.length];
		scope space = new ubyte[slices.length * 4];
		stream.position = 0;
		stream.write(space);
		stream.position = slices.length * 4;
		foreach (k, slice; slices) {
			while (stream.position % _align) stream.write(cast(ubyte)0);
			pointers[k] = stream.position;
			stream.copyFrom(slice);
		}
		stream.position = 0;
		foreach (pointer; pointers) stream.write(pointer);
	}

	void readPointers(Stream stream) {
		uint[] positions;
		uint count, position;

		stream.read(count);
		count /= 4;
		stream.position = stream.position - 4;
		for (int n = 0; n < count; n++) { stream.read(position); positions ~= position; }
		positions ~= stream.size;
		
		for (int n = 1; n < positions.length; n++) slices ~= new SliceStream(stream, positions[n - 1], positions[n]);
	}
}
