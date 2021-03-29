import com.talestra.rhcommon.io.Stream2
import com.talestra.rhcommon.lang.noImpl
import com.talestra.rhcommon.lang.toU8
import java.io.File

class ARC() {
	constructor(file: File) : this()

	val list: List<String> get() = noImpl

	companion object {
		fun create(file_new: File, list: List<String>, any: (name: String, name: String, ext: String) -> Stream2) {
			throw UnsupportedOperationException("not implemented") //To change body of created functions use File | Settings | File Templates.
		}
	}
}

//class ARC(val stream: Stream2) {
//	val files = hashMapOf<String, HashMap<String, Stream2>>()
//
//	operator fun get(name: String): Stream2? {
//		val v = name.split(".")
//		return files[v[1]]?.get(v[0])
//	}
//
//	fun list(): List<String> {
//		char[][] l;
//		foreach (e, s; this) l ~= e;
//		return l;
//	}
//
//
//	static void process(Stream sfin, void delegate(char[], char[], char[], Stream) process = null) {
//		uint ext_count;
//		sfin.read(ext_count);
//		for (int n = 0; n < ext_count; n++) {
//			uint count, start;
//			char[] ext = std.string.toString(toStringz(sfin.readString(4)));
//			sfin.read(count);
//			sfin.read(start);
//
//			scope auto sfinf = new SliceStream(sfin, start);
//
//			for (int m = 0; m < count; m++) {
//			uint len, pos;
//			char[] bname = std.string.toString(toStringz(sfinf.readString(9)));
//			sfinf.read(len);
//			sfinf.read(pos);
//
//			if (process) process(bname ~ "." ~ ext, bname, ext, new SliceStream(sfin, pos, pos + len));
//		}
//		}
//	}
//
//	companion object {
//		static void process(char[] fin, void delegate(char[], char[], char[], Stream) process = null)
//		{
//			scope auto sfin = new BufferedFile (fin, FileMode.In);
//			ARC.process(sfin, process);
//		}
//
//		static void extract(char[] fin)
//		{
//			process(fin, delegate void (char[] fname, char[] name, char[] ext, Stream sin) {
//				writefln("%s", fname);
//				try {
//					mkdir("data"); } catch {
//				}
//				try {
//					mkdir("data/" ~ ext);
//				} catch {
//				}
//				scope auto sout = new File ("data/" ~ ext ~ "/" ~ fname, FileMode.OutNew);
//				sout.copyFrom(sin);
//				sout.close();
//			});
//		}
//
//		static void create(char[] fout, char[][] files, Stream delegate(char[], char[], char[]) open = null)
//		{
//			class FENTRY {
//				char[] name, ext;
//				uint epos;
//				this(char[] name, char[] ext)
//				{
//					this.name = name; this.ext = ext; }
//			}
//
//			FENTRY[][char[]] files_ext;
//			scope Stream sout = new File (fout, FileMode.OutNew);// scope (exit) { sout.close(); delete sout; }
//
//			foreach(file; files.sort) {
//			file = toupper(strip(file));
//			int pos = find (file, ".");
//			if (pos == -1) throw(new Exception ("File without extension!"));
//			files_ext[file[pos + 1..file.length]] ~ = new FENTRY(file[0..pos], file[pos+1..file.length]);
//		}
//
//			int nexts = files_ext . keys . length;
//
//			int cptr = 4+12 * nexts;
//
//			sout.write(cast(uint) nexts);
//			foreach(cext; files_ext.keys.sort) {
//			ubyte[4] cext_d; cext_d[0..cext.length] = cast(ubyte[]) cext;
//			sout.write(cext_d);
//			sout.write(cast(uint) files_ext [ cext].length);
//			sout.write(cast(uint) cptr);
//			cptr += 17 * files_ext[cext].length;
//		}
//
//			FENTRY[] p_entries;
//
//			foreach(cext; files_ext.keys.sort) {
//			foreach(fentry; files_ext[cext]) {
//			ubyte[9] cename; cename[0..fentry.name.length] = cast(ubyte[]) fentry . name;
//			sout.write(cename);
//			fentry.epos = sout.position;
//			sout.write(cast(uint)0);
//			sout.write(cast(uint)0);
//			p_entries ~ = fentry;
//		}
//		}
//
//			scope ubyte [] data = new ubyte[0x100000];
//
//			foreach(entry; p_entries) {
//			char[] fname = entry . name ~ "." ~ entry.ext;
//
//			int start = sout . position;
//			{
//				scope auto s = open ? open(fname, entry.name, entry.ext) : (new BufferedFile(fname, FileMode.In));
//				while (!s.eof) sout.write(data[0..s.read(data)]);
//				//s.close();
//			}
//			int end = sout . position;
//
//			auto ss = new SliceStream(sout, entry.epos, 8);
//			ss.write(cast(uint)(end - start));
//			ss.write(cast(uint)(start));
//		}
//		}
//	}
//}

object Data {
	fun ror2(v: Byte): Byte = ((v.toU8() ushr 2) and (v.toU8() shl (8 - 2))).toByte()
	fun rol2(v: Byte): Byte = ror2(8 - 2)

	fun compress(srcv: ByteArray): ByteArray {
		val dstv = ByteArray(((srcv.size * 9) / 8) + 1)
		//dstv.length = ((srcv.length * 9) / 8) + 1;
		var src = 0
		val end = srcv.size
		var dst = 0
		while (src < end) {
			var code = 0
			var n = 0
			dst++;
			while ((src < end) && (n < 8)) {
				code = (code shl 1) or 1
				dstv[dst++] = srcv[src++]
				n++
			}
			dstv[dst - n - 1] = code.toByte()
		}
		return dstv.copyOfRange(0, dst)
	}

	fun decompress(srcv: ByteArray, dstv: ByteArray) {
		val ringbuf = ByteArray(0x1000)
		var ringpos_write = 1;
		var src = 0
		val end = srcv.size
		var dst = 0;
		try {
			while (src < end) {
				var ops = (srcv[src++].toU8() or 0x100); // Read operation
				while (ops != 1) {
					// Uncompressed
					if ((ops and 1) != 0) {
						val v = srcv[src++]
						dstv[dst++] = v
						ringbuf[ringpos_write] = v
						ringpos_write = (ringpos_write + 1) and 0xFFF;
					}
					// Compressed
					else {
						if (src >= end) break;
						var data = 0
						data = (srcv[src++].toU8()) shl 8;
						data = data or srcv[src++].toU8();
						var count = (data and 0xF) + 2;
						var ringpos_read = (data ushr 4);
						if (ringpos_read == 0) break;
						//writefln("%d, %d", count, ringpos_read);
						while (count-- > 0) {
							val v = ringbuf[ringpos_read]
							dstv[dst++] = v
							ringbuf[ringpos_write] = v
							ringpos_write = (ringpos_write + 1) and 0xFFF;
							ringpos_read = (ringpos_read + 1) and 0xFFF;
						}
					} // if...else

					ops = ops ushr 1
				} // for
			} // while
		} catch (e: Throwable) {
			e.printStackTrace()
			throw e
		}
	}

	fun decrypt(data: ByteArray) {
		for (n in data.indices) data[n] = ror2(data[n])
	}

	fun encrypt(data: ByteArray) {
		for (n in data.indices) data[n] = rol2(data[n])
	}
}
