package util

import com.talestra.rhcommon.io.Stream2
import com.talestra.rhcommon.util.BitRead

class ScriptReader {
	lateinit var s: Stream2
	lateinit var fname: String
	lateinit var s_acme: Stream2

	val script_links = hashMapOf<String, Boolean>()
	lateinit var saveto: String

	companion object {
		val opcodes = hashMapOf<Int, String>()

		init {
			fun opcode_info(n: Int, name: String, format: String) {
				opcodes[n] = name
			}
			opcode_info(0x01, "JUMP_IF", "Of2l.")
			opcode_info(0x02, "OPTION_SELECT", "C[2t4s]")
			opcode_info(0x03, "SET", "ofkF.")
			opcode_info(0x04, "EXIT", "")
			opcode_info(0x05, "TIMER_WAIT", "1")
			opcode_info(0x06, "JUMP", "L1")
			opcode_info(0x07, "SCRIPT", "s")
			opcode_info(0x08, "TEXT_SIZE", "2")
			opcode_info(0x09, "SCRIPT_CALL", "s")
			opcode_info(0x0A, "SCRIPT_RET", "1")
			opcode_info(0x0B, "TIMER_SET", "2")
			opcode_info(0x0C, "TIMER_GET", "21")
			opcode_info(0x21, "MUSIC_PLAY", "12s")
			opcode_info(0x22, "MUSIC_STOP", "121")
			opcode_info(0x23, "VOICE_PLAY", "1222s")
			opcode_info(0x25, "SOUND_PLAY", "111122s")
			opcode_info(0x26, "SOUND_STOP", "2")
			opcode_info(0x28, "", "12")
			opcode_info(0x41, "TEXT", "21t")
			opcode_info(0x42, "TEXT2", "4tt")
			opcode_info(0x43, "ANIM_LOAD", "42s")
			opcode_info(0x45, "ANIM_PUT", "121")
			opcode_info(0x46, "BACKGROUND", "22221s")
			opcode_info(0x47, "BG_BLACK", "11")
			opcode_info(0x48, "CHARA_PUT", "122221s")
			opcode_info(0x49, "CLEAR_L1", "2.")
			opcode_info(0x4A, "TRANSITION", "12.")
			opcode_info(0x4B, "ANIMATE_ADD", "1222221")
			opcode_info(0x4C, "ANIMATE_PLAY", "1")
			opcode_info(0x4D, "EFFECT", "1121")
			opcode_info(0x4F, "ANIM_UNPUT", "121")
			opcode_info(0x50, "TABLE", "s")
			opcode_info(0x51, "TABLE_SELECT", "ff1")
			opcode_info(0x52, "SOUND_WAIT", "2")
			opcode_info(0x54, "TRANS_IMAGE", "s")
			opcode_info(0x55, "", "1")
			opcode_info(0x61, "MOVIE", "1s")
			opcode_info(0x64, "", "4")
			opcode_info(0x68, "", "2221")
			opcode_info(0x73, "OBJ_PUT", "22221s")
			opcode_info(0x74, "OBJ_CLEAR", "2"); //?
			opcode_info(0x82, "WAIT", "21")
			opcode_info(0x83, "RUN_LOAD", "1")
			opcode_info(0x85, "", "2")
			opcode_info(0x86, "", "2")
			opcode_info(0x89, "", "1")
			opcode_info(0x8B, "RUN_CONFIG", "1")
			opcode_info(0x8C, "", "21")
			opcode_info(0x8E, "", "1")
			opcode_info(0xB6, "TEXT_ADD", "2t")
			opcode_info(0xB8, "CLEAR_L2", "2.")
			opcode_info(0xE2, "RUN_QLOAD", "1")
			opcode_info(0xFF, "EOF", "")
		}
	}

	this(Stream s, char[] fname = "Unknown")
	{
		this.s = new DecryptStream (s)
		this.fname = fname
		//process()
	}

	this(char[] s)
	{
		//s_acme = new File("SRC/" ~ s[0..s.length - 4] ~ ".txt", FileMode.OutNew)
		this(new BufferedFile ("DATA/WSC/" ~ s, FileMode.In), s)
	}

	var ctext = 0

	fun addText(pos: Int, text: String) {
		if (s_acme) s_acme.writeString("## POINTER %d\n".format(ctext++) + text.replace("\\n", "\n") + "\n\n")
	}

	fun process() {
		var op: Int
		var op_pos: Int = 0

		val lines = hashMapOf<Int, List<String>>()
		val labels = hashMapOf<Int, String>()
		var params = arrayListOf<String>()

		fun param_out(data: ByteArray) {
			var param = ""
			param += "[";
			for (c in data) param += "%02X".format(c)
			param += "]"
			params += param
		}

		fun ignore(len: Int) {
			val data = s.readBytes(len)
			param_out(data)
		}

		fun read1(): Int {
			val v = s.readU8()
			params += "%d".format(v)
			return v
		}

		fun read2(): Int {
			val bytes = s.readBytes(2)
			val v = BitRead.readU16_le(bytes, 0)
			//params ~= std.string.format("%d", v)
			param_out(bytes)
			return v
		}

		fun readLocation(): Int {
			val v = s.readS32()
			params += "%d".format(v)
			return v
		}

		fun readLocationAbsolute(): Int {
			val v = s.readS32()
			params += "/%d".format(v)
			return v
		}

		fun quote(s: String): String {
			var r = ""
			for (c in s) {
				//if (c == '"') throw(new Exception("Invalid character (1) : '\"'"))
				r += if (c == '"') "\\\"" else "$c"
			}
			return r
		}

		fun quote2(s: String): String {
			var r = ""
			for (c in s) {
				if (c == '@') throw RuntimeException("Invalid character (2) : '@'")
				r += c
			}
			return r
		}

		fun readString(): String {
			// @TODO: Encoding!!
			var r = ""

			do {
				val c = s.readU8()
				if (c == 0) break
				r += c
			} while (c != 0)

			//params ~= std.string.format("@%s@", quote2(r))
			params += '@' + quote2(r) + '@'

			return r
		}

		fun readText(): String {
			var r = ""

			do {
				val c = s.readU8()
				if (c == 0) break
				r += c
			} while (c != 0)

			addText(op_pos, r)

			//params ~= std.string.format("\"%s\"", quote(r))
			params += '"' + quote(r) + '"'

			return r
		}

		try {
			while (!s.eof) {
				params = arrayListOf()

				op_pos = s.position.toInt()

				op = s.readU8()

				when (op) {
					0x01 -> { // JUMP_IF
						ignore(1)
						ignore(2)
						ignore(2)
						readLocation()
						ignore(1)
						//read1()
					}
				// SELECT?
					0x02 -> { // ?
						val count = read2()
						for (n in 0 until count) {
							ignore(2)
							readText()
							ignore(4)
							script_links[readString()] = true
						}
					}
					0x03 -> {
						ignore(1)
						ignore(2)
						ignore(1)
						ignore(2)
						ignore(1)

						//ignore(7)
						//op(1) variable(2) kind(1) variable/value(2)
					} // SET
					0x04 -> {
						Unit
					} // ?
					0x05 -> {
						ignore(1)
					} // ?
					0x06 -> {
						readLocationAbsolute(); ignore(1); /*ignore(5);*/
					} // JUMP
					0x07 -> {
						script_links[readString()] = true; } // SCRIPT
					0x08 -> {
						ignore(2); } // ??
					0x09 -> {
						script_links[readString()] = true; } // TRACE? SCRIPT2?
					0x0A -> {
						ignore(1); } // ?
					0x0B -> {
						ignore(2); } // ?
					0x0C -> {
						ignore(3); } // ?
					0x21 -> {
						ignore(3); readString(); }// MUSIC? (ogg)
					0x22 -> {
						ignore(4); } // ?
					0x23 -> {
						ignore(8); readString(); } // ?
					0x25 -> {
						ignore(8); readString(); } // PLAY_OGG
					0x26 -> {
						ignore(2); } // ?
					0x28 -> {
						ignore(3); } // ?
					0x41 -> {
						ignore(3); readText(); } // TEXT?
					0x42 -> {
						ignore(4); readText(); readText(); } // TEXT_WITH_TITLE
					0x43 -> {
						ignore(6); readString(); } // ? ANM
					0x45 -> {
						ignore(4); } // ?
					0x46 -> {
						ignore(9); readString(); } // BACKGROUND
					0x47 -> {
						ignore(2); } // ?
					0x48 -> {
						ignore(10); readString(); } // ? WIP
					0x49 -> {
						ignore(3); } // ?
					0x4A -> {
						ignore(4); } // ?
					0x4B -> {
						ignore(12); } // ?
					0x4C -> {
						ignore(1); } // ?
					0x4D -> {
						ignore(5); } // ?
					0x4F -> {
						ignore(4); } // ?
					0x50 -> {
						readString(); } // ? TBL
					0x51 -> {
						ignore(5); } // ?
					0x52 -> {
						ignore(2); } // ?
					0x54 -> {
						readString(); } // ? MSK
					0x55 -> {
						ignore(1); } // ?
					0x61 -> {
						ignore(1); readString(); } // VIDEO
					0x64 -> {
						ignore(4); } // ?
					0x68 -> {
						ignore(7); } // ?
					0x73 -> {
						ignore(9); readString(); } // ? WIP
					0x74 -> {
						ignore(2); } // ?
					0x82 -> {
						ignore(3); } // ?
					0x83 -> {
						ignore(1); } // ?
					0x85 -> {
						ignore(2); } // ?
					0x86 -> {
						ignore(2); } // ?
					0x89 -> {
						ignore(1); } // ?
					0x8B -> {
						ignore(1); } // ?
					0x8C -> {
						ignore(3); } // ?
					0x8E -> {
						ignore(1); } // ?
					0xB6 -> {
						ignore(2); readString(); } // ? TEXT ??
					0xB8 -> {
						ignore(3); } // ?
					0xE2 -> {
						ignore(1); } // ?
					0xFF -> {
						ignore(0); } // GAME_END
					else -> throw RuntimeException("Unknown (%02X) at %s : 0x%04X\n".format(op, fname, s.position - 1))
				}

				for (n in 0 until params.size) {
					val param = params[n]
					if (param.length > 0) {
						when (param[0]) {
							'#' -> {
								val pos = s.position.toInt() + param.substring(1, param.length).toInt()
								params[n] = "#label_%04X".format(pos)
								labels[pos] = "label_%04X".format(pos)
							}
							'/' -> {
								val pos = param.substring(1, param.length).toInt()
								params[n] = "#label_%04X".format(pos)
								labels[pos] = "label_%04X".format(pos)
							}
							else -> Unit
						}
					}
				}

				var op_name = "%02X".format(op)

				if (op in opcodes) {
					op_name += "." + opcodes[op]
				}

				lines[op_pos] = listOf(op_name) + params
			}
		} catch (e: Throwable) {
			println("ERROR: %s at %s".format(e.toString(), fname))
			throw(e)
		}

		if (saveto.length > 0) {
			//auto sout = new File("WS/" ~ fname[0..fname.length - 1], FileMode.OutNew)
			val sout = File(saveto, FileMode.OutNew)
			val out_lines: String = ""
			val put_labels: Int

			for (k in lines.keys.sort) {
				val line = lines[k]

				var out_line: String = ""

				if ((k in labels) !is null) {
					//writefln("\n:%s", labels[k])
					out_line += "\n:" + labels[k] + "\n"
					put_labels++
				}

				//printf(" %s ", toStringz(line[0]))
				out_line += " "
				out_line += line[0]
				out_line += " "
				for (n in 1 until line.size) {
					if (n > 1) {
						//printf(", ")
						out_line += ", "
					}
					//printf("%s", toStringz(line[n]))
					out_line += line[n]
				}
				//printf("\n")

				out_lines += out_line + "\n"
			}

			sout.writeString(out_lines)
			sout.close()

			if (put_labels != labels.length) {
				println("Can't put all labels")
			}
		}
	}
}

/*

-------------------------------------------------------------------

01:10           - JUMP_IF
                  1 >=
				  2 <=
				  3 ==
				  4 !=
				  5 >
				  6 <
03:7            - SET (=+-) op(1) variable(2) kind(1) variable/value(2)
                  0 ?
                  1 =
				  2 +=
				  3 -=
				  4 = REF =
				  5 %=
				  6 RAND % X

07:string       - SCRIPT

0C:variable = (dword_47DC6C != 0)

22:4            - ?
25:8byte,string - PLAY_OGG?
26:2            - ?

49:3            - ?

85:2            - ?
89:1            - ?

FF:             - GAME_END

-------------------------------------------------------------------

JUMP_IF
	1BYTE  - operacion: & 0x10 --> variable | inmediato
	2BYTES - var1
	2BYTES - var2 / valor
	4BYTES - salto relativo al final de la instruccion

-------------------------------------------------------------------

*/

// BRAND -> Selector
// MAINMENU
// START
