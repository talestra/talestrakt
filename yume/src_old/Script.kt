/*
object Script {
	fun regenerate() {
		ubyte[][char[]] files;
		char[][int][char[]] script;

		ARC.process("Rio.en.arc", delegate void(char[] fname, char[] name, char[] ext, Stream s) {
			script[name] = null;
		});

		{
			auto s = archive["text/es.bin"].open;
			while (!s.eof) {
				char[] name;
				uint count;
				s.read(name);
				s.read(count);
				for (int n = 0; n < count; n++) {
					uint id;
					char[] text;
					s.read(id);
					s.read(text);
					script[name][id] = text;
				}
			}
		}


		foreach (bname; script.keys.sort) {
			auto texts = script[bname];

			//writefln(texts);

			writefln("rewriting...", bname);

			//script_t[bname] = getTexts(cast(char[])zip.expand(e));
			auto data = recompile(archive["script/" ~ bname ~ ".WS"].open, delegate char[](char[] text, int count, int line, int ppos, int ppos_max) {
			if (ppos_max > 1) {
				auto ttexts = explode("\n", texts[count - ppos], ppos_max);
				char[] r;
				try {
					r = ttexts[ppos].replace("\r\n", "\n").replace("\r", "").replace("\n", "\\n");
				} catch (Exception e) {
					writefln("text:'%s' count:%d, line:%d, ppos:%d, ppos_max:%d, zz:%d", text, count, line, ppos, ppos_max, ttexts.length);
					//throw(e);
				}
				return r;
			} else {
				return texts[count].replace("\r", "").replace("\n", "\\n");
			}
		}, bname ~ ".WS");

			Data.encrypt(data);

			files[bname ~ ".WSC"] = data;
		}

		ARC.create("Rio.arc", files.keys.sort, delegate Stream(char[] fname, char[] name, char[] ext) {
			return new MemoryStream(files[fname]);
		});

		files = null;
	}

	fun recompile(char[] s, char[] delegate(char[], int, int, int, int) gettext = null): ByteArray {
		scope auto f = new BufferedFile(s, FileMode.In); scope (exit) f.close();
		return recompile(f, gettext, s);
	}

	fun recompile(Stream s, char[] delegate(char[], int, int, int, int) gettext = null, char[] ws_name = "unknown.ws"): ByteArray {
		int ntext = 0;
		ubyte[] ret;

		struct patch_s {
			int patch_pos;
			int relative;
			char[] label;
			int is_absolute_pos;
		}

		patch_s[][char[]] label_patches;
		int[char[]] labels;
		int line_n, line2_n;
		while (!s.eof) {
			line_n++;
			char[] line = strip(s.readLine());
			if (!line.length) continue;

			if (line[0] == ':') {
				labels[line[1..line.length]] = ret.length;
				writefln("LABEL: %s:$d", line[1..line.length], ret.length);
				continue;
			}

			line2_n++;

			//printf("'%s'\n", toStringz(line));
			char[][] f = explode(" ", line, 2);
			int op = hex2dec(explode(".", f[0])[0]);
			while (f.length < 2) f ~= "";
			char[] params = f[1];
			ret ~= cast(ubyte)op;

			patch_s[] patches;

			int param_text_count = 0;

			int param_text_count_max = 0;

			for (int n = 0; n < params.length; n++) {
				switch (params[n]) {
					case '[':
					for (n++; n < params.length; n += 2) if (params[n] == ']') break;
					break;
					case '@':
					for (n++; n < params.length; n++) if (params[n] == '@') break;
					break;
					case '"': {
					for (n++; n < params.length; n++) {
					if (params[n] == '"') break;
					if (params[n] == '\\' && params[n + 1] == '"') {
						n++;
						continue;
					}
				}
					param_text_count_max++;
				} break;
					case '#':
					for (n++; n < params.length; n++) if (params[n] == ',') break;
					break;
					case ',': case ' ': case '\t': case '\r': case '\n': break;
					default:
					throw(new Exception(std.string.format("Invalid character '%s' at %d", params[n], line_n, ws_name)));
					break;
				}
			}

			for (int n = 0; n < params.length; n++) {
				switch (params[n]) {
					case '[':
					for (n++; n < params.length; n += 2) {
					if (params[n] == ']') break;
					ret ~= cast(ubyte)hex2dec(params[n..n + 2]);
				}
					break;
					case '@': {
					char[] cs;
					for (n++; n < params.length; n++) {
					if (params[n] == '@') break;
					cs ~= cast(ubyte)params[n];
				}

					if (op == 0xB6) {
						switch (cs) {
							case " Kouhei!":
							cs = " \xA1Kouhei!";
							break;
							case "Whoah!?":
							cs = " \xA1Guau!";
							break;
						}
					}

					ret ~= cast(ubyte[])(cs ~ '\0');
				} break;
					case '"': {
					char[] cs;
					for (n++; n < params.length; n++) {
					if (params[n] == '"') break;
					if (params[n] == '\\' && params[n + 1] == '"') {
						cs ~= cast(ubyte)'"';
						n++;
						continue;
					}
					//writefln(params[n]);
					cs ~= cast(ubyte)params[n];
				}
					if (gettext) cs = gettext(cs, ntext++, line2_n, param_text_count++, param_text_count_max);
					ret ~= cast(ubyte[])(cs ~ '\0');
				} break;
					case '#':
					char[] clabel;
					for (n++; n < params.length; n++) {
					if (params[n] == ',') break;
					clabel ~= params[n];
				}
					patches ~= patch_s(ret.length, 0, strip(clabel), (op != 1));
					//label_patches[strip(clabel)] ~= sout.position;
					ret ~= cast(ubyte[])"\0\0\0\0";
					break;
					case ',': case ' ': case '\t': case '\r': case '\n': break;
					default:
					throw(new Exception(std.string.format("Invalid character '%s' at %d", params[n], line_n)));
					break;
				}
			}

			foreach (cpatch; patches) {
				cpatch.relative = ret.length;
				label_patches[cpatch.label] ~= cpatch;
			}
		}

		foreach (label_name, label_pos; labels) {
			if ((label_name in label_patches) !is null) {
				foreach (patch; label_patches[label_name]) {
					*cast(uint *)&ret[patch.patch_pos] = patch.is_absolute_pos ? label_pos : (label_pos - patch.relative);
				}
			} else {
				//throw(new Exception(std.string.format("Ooops! Invalid label '%s' at '%s'!!\n\n\n%s", label_name, ws_name, label_patches.keys)));
			}
		}

		return ret;
	}
}
	*/
