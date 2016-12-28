package com.talestra.tod

/*
class ScriptFile {
	SELFPAK pak;
	ubyte[] scriptData;
	string[] texts;

	this(Stream stream) {
		string readStringz(Stream s) {
			string r;
			ubyte c;
			while (!s.eof) {
				s.read(c); if (c == 0) break;
				switch (c) {
					default:
					r  ~= c;
					break;
				}
			}
			return r;
		}
		try {
			pak = SELFPAK(stream);
			auto streamScript = pak[0];
			ushort pos_h;
			streamScript.position = 4;
			streamScript.read(pos_h);

			streamScript.position = 0;
			scriptData = cast(ubyte[])streamScript.readString(pos_h * 2);
			scope streamTexts = new SliceStream(streamScript, pos_h * 2);


			uint[] textPositions;
			ushort textCount_2;
			streamTexts.read(textCount_2);
			streamTexts.position = 0;
			textPositions.length = textCount_2 / 2;
			for (int n = 0; n < textPositions.length; n++) {
				ushort position;
				streamTexts.read(position);
				textPositions[n] = position;
			}
			textPositions ~= streamTexts.size;

			texts = [];
			try {
				for (int n = 0; n < textPositions.length - 1; n++) {
					streamTexts.position = textPositions[n];

					static if (0) {
					texts ~= readStringz(streamTexts);
				} else {
					//writefln("%d, %d", textPositions[n + 1], textPositions[n]);
					assert(textPositions[n + 1] >= textPositions[n]);
					scope text = streamTexts.readString(textPositions[n + 1] - textPositions[n]);
					if (text.length >= 1) { assert (text[$ - 1] == 0); texts ~= text[0..$ - 1].dup; }
				}
				}
			} catch (Exception e) {
				throw(e);
			}
		} catch (Exception e) {
			writefln("warning! Exception reading file.");
			//throw(e);
		}
	}

	void update() {
		auto nstream = new MemoryStream();
		nstream.write(scriptData);
		uint position = texts.length * 2;
		foreach (n, text; texts) { nstream.write(cast(ushort)position); position += text.length + 1; }
		foreach (text; texts) { nstream.writeString(text ~ '\0'); }
		pak[0] = nstream;
	}

	void write(Stream stream) {
		update();
		pak.write(stream);
	}

	Stream stream() {
		auto stream = new MemoryStream;
		write(stream); stream.position = 0;
		return stream;
	}
}
*/
