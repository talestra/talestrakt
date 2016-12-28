import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.stream.*
import com.talestra.rhcommon.lang.invalidOp

object BSCR { // Script?
	class Script(
		val name: String,
		val ver: Int,
		var strings: List<String>,
		val funcs: List<Func>
	) {
		fun gen(): ByteArray {
			val stroffsets = hashMapOf<String, Int>()
			val funcoffsets = hashMapOf<Int, Int>()

			fun genStrings(): ByteArray {
				val ss = MemorySyncStream()
				for (str in strings) {
					if (str !in stroffsets) {
						stroffsets[str] = ss.position.toInt()
					}
					ss.writeStringz(str, Charsets.UTF_8)
				}
				ss.write8(0)
				return ss.toByteArray()
			}

			fun genInstructions(): ByteArray {
				val ss = MemorySyncStream()
				for (func in funcs) {
					funcoffsets[func.id] = ss.position.toInt()
					//println(func.name + " : " + func.ins)
					for (i in func.ins) {
						//println(i)
						when (i) {
							is II.Generic -> {
								ss.writeBytes(i.data)
							}
							is II.PushString -> {
								ss.write32_be(0x1AF0F15A)
								ss.write32_le(stroffsets[i.str] ?: invalidOp("String '${i.str}' not found!"))
								ss.write32_be(0x5A5A5A5A)
								ss.write32_be(0x5A5A5A5A)
							}
						}
					}
				}

				return ss.toByteArray()
			}

			fun genFunctions(): ByteArray {
				val ss = MemorySyncStream()
				for (func in funcs) {
					ss.writeBytes(func.gen(funcoffsets[func.id]!!))
				}

				return ss.toByteArray()
			}

			//class Chunk(val name: String, val size: Int, val alignment: Int)

			//fun getAlignSize() {

			//}

			val stringsBytes = genStrings()
			val instructionsBytes = genInstructions()
			val functionBytes = genFunctions()

			val pos = StreamAllocator()
			val headerPos = pos.writeSize(0x40, alignment = 1)
			val functionsPos = pos.writeSize(functionBytes.size, alignment = 4)
			val stringsPos = pos.writeSize(stringsBytes.size, alignment = 4)
			val instructionsPos = pos.writeSize(instructionsBytes.size, alignment = 4)
			//val size = pos.writeSize(0, alignment = 0x100)
			val size = pos.position
			val endPos = pos.position

			val s = MemorySyncStream()
			s.position = headerPos
			s.writeStringz("bscr", 4)
			s.write16_le(ver)
			s.writeStringz(name, 30)
			s.write32_le(size)
			s.write32_le(funcs.size)
			s.write32_le(functionsPos)
			s.write32_le(strings.size)
			s.write32_le(stringsPos)
			s.write32_le(instructionsBytes.size)
			s.write32_le(instructionsPos)

			s.position = functionsPos
			s.writeBytes(functionBytes)

			s.position = stringsPos
			s.writeBytes(stringsBytes)

			s.position = instructionsPos
			s.writeBytes(instructionsBytes)

			//s.position = endPos
			s.length = endPos

			return s.toByteArray()
		}
	}

	class StreamAllocator {
		var position = 0L

		fun writeSize(size: Int, alignment: Int): Long {
			val start = position
			position += size
			while ((position % alignment) != 0L) position++
			return start
		}
	}

	class Func(val id: Int, val name: String, val unk: Int, val argcount: Int, val ins: List<II>) {
		fun gen(ptr: Int): ByteArray {
			val s = MemorySyncStream()
			s.write16_le(0x20 + 12 + argcount * 8)
			s.write16_le(unk)
			s.writeStringz(name, 0x20)
			s.write32_le(ptr)
			s.write32_le(argcount)
			for (n in 0 until argcount) {
				s.write32_le(0x81)
				s.write32_le(n)
			}
			return s.toByteArray()
		}
	}

	sealed class II {
		data class PushString(var str: String) : II()
		data class Generic(val data: ByteArray) : II()
	}

	fun check(s: SyncStream) = s.slice().readStringz(4) == "bscr"

	fun read(s: SyncStream): Script {
		val TRACE = false
		if (s.readStringz(4) != "bscr") invalidOp("Not a bscr file")
		//println(magic)
		val ver = s.readS16_le()
		val name = s.readStringz(30)
		val size = s.readS32_le()
		val functionCount = s.readS32_le()
		val functionPtr = s.readS32_le()
		val strCount = s.readS32_le()
		val strPtr = s.readS32_le()
		val instructionSize = s.readS32_le()
		val instructionPtr = s.readS32_le()
		//println("%08X".format(strPtr))
		// 29DC
		// 8F00

		if (TRACE) println("$name: size=$size, functionCount=$functionCount, functionPtr=$functionPtr, strCount=$strCount, strPtr=$strPtr, instructionSize=$instructionSize, instructionPtr=$instructionPtr")

		val strings = arrayListOf<String>()
		val sstream = s.sliceWithStart(strPtr.toLong())
		while (true) {
			val t = sstream.readStringz()
			if (t.isEmpty()) break
			strings += t
		}
		//println()
		val istream = s.slice(instructionPtr until instructionPtr + instructionSize)
		val fstream = s.sliceWithStart(functionPtr.toLong())
		val functions = (0 until functionCount).map { readFunction(it, fstream, istream) }
		//println(functions)

		if (TRACE) println("  - STR_COUNT:${strings.size}")
		if (TRACE) println("  - INSTRUCTION_COUNT:${functions.size}")

		val funcptrs = functions.map { it.ptr } + listOf(istream.length.toInt())

		//for ((n, f) in functions.withIndex()) println("%04X:\"%s\"".format(n, f))
		//for (s in strings.withIndex()) println("%04X:\"%s\"".format(s.index, s.value.escape()))

		for ((n, f) in functions.withIndex()) {
			//funcptrs
			val range = funcptrs[n] until funcptrs[n + 1]
			f.data = istream.slice(range)
		}

		/*
		for ((n, f) in functions.withIndex()) {
			//funcptrs
			val range = funcptrs[n] until funcptrs[n + 1]
			f.data = istream.slice(range)
			println("${f.name}:            ---  ($f)")
			val instructions = f.getAllInstructions()
			for (i in instructions) {
				//println(i)
				when (i.op) {
					Opcodes.PUSH_TEXT -> {
						//val str = strings.getOrElse(i.args[1], { "" })
						val str = sstream.slice(i.args[1]).readStringz()
						println(" - TEXT:'" + str.escape() + "'")
					}
					Opcodes.PUSH_ARG_INT -> {
						println(" - PUSH_ARG_INT:${i.args[1]}")
					}
					Opcodes.PUSH_INT -> {
						println(" - INT:${i.args[1]}")
					}
					Opcodes.PUSH_ID -> {
						println(" - ID:${i.args[1]}")
					}
					Opcodes.JUMP_IF_REL -> {
						println(" - JUMP_IF_REL:0x%08X".format(i.args[1] / 16))
					}
					Opcodes.INVOKE -> {
						val id = i.data.getu(1)
						when (id) {
							0x6E -> println(" - INVOKE:TEXT_DIALOG(IIITT)")
							0x3C -> println(" - INVOKE:SELECT_DIALOG")
							0x0E -> println(" - INVOKE:WAIT_BUTTON(I)")
							0x69 -> println(" - INVOKE:VOICE(I)")
							else -> println(" - INVOKE:0x%02X".format(id))
						}
					}
					else -> {
						println(" - %s(0x%02X)".format(i.op.toString(), i.opId))
						//println(" - $i")
					}
				}
			}
		}
		*/

		//for (text in strings) println(text.escape())

		return Script(
			name = name,
			ver = ver,
			strings = strings,
			funcs = functions.map {
				Func(
					id = it.id,
					name = it.name,
					unk = it.unk,
					argcount = it.args.size,
					ins = it.getAllInstructions().map {
						if (it.op == Opcodes.PUSH_TEXT) {
							val str = sstream.sliceWithStart(it.args[1].toLong()).readStringz()
							II.PushString(str)
						} else {
							II.Generic(it.data)
						}
					}
				)
			}
		)
	}

	data class Function(val id: Int, val name: String, val unk: Int, val ptr: Int, val args: List<Arg>) {
		var data: SyncStream? = null

		fun getAllInstructions(): List<Instruction> {
			val out = arrayListOf<Instruction>()
			if (data != null) {
				val s = data!!.slice()
				while (!s.eof) out += readInstruction(s)
			}
			return out
		}
	}

	data class Arg(val kind: Int, val index: Int)

	data class Instruction(val opId: Int, val op: Opcodes, val args: List<Int>, val data: ByteArray)

	enum class Opcodes(val id: Int) {
		UNKNOWN(-1),

		PUSH_UNK02(0x02),

		//JUMP_IF(0x13), // ????
		PUSH_ARG_INT(0x13), // 13 F6 F2 5A
		PUSH_INT(0x18), // 18 F0 5A 5A
		PUSH_TEXT(0x1A), // 1A F0 F1 5A

		GET_STRING(0x1B), // Converts an integer into an string from the string pool?
		// 82 6E text dialog (82 6E F3 5A)
		// 82 3C select dialog (82 3C F3 5A) (4 options) 4str + 2int

		PUSH_ID(0x74),

		BINOP(0x80),
		UNKUNOP(0x81),
		INVOKE(0x82),
		JUMP_IF_REL(0x84),
		//TEXT_UNK(0x74),
		RET(0x83), // 83 5A 5A 5A
		;

		companion object {
			val BY_ID = values().associateBy { it.id }
		}
	}

	fun readInstruction(s: SyncStream): Instruction {
		val data = s.readBytes(0x10)
		val ss = data.openSync("r")
		val args = ss.readIntArray_le(4).toList()
		val opid = data[0].toInt() and 0xFF
		return Instruction(opid, Opcodes.BY_ID[opid] ?: Opcodes.UNKNOWN, args, data)
	}

	fun readFunction(id: Int, func: SyncStream, instructions: SyncStream): Function {
		val size = func.readS16_le()
		val unk = func.readS16_le()
		val s = func.readStream(size - 4)
		val name = s.readStringz(0x20)

		val ptr = s.readS32_le()
		val count = s.readS32_le()

		val args = (0 until count).map { Arg(s.readS32_le(), s.readS32_le()) }

		//val args = s.readIntArray_le(s.available.toInt() / 4).toList()

		/*
		println("$name:$size:$unk : $args")
		when (name) {
			"monologue_start", "monologue_w_start", "monologue_end", "monologue_w_end" -> {
				val p1 = s.readS32_le()
				val p2 = s.readS32_le()
				val p3 = s.readS32_le()
				val p4 = s.readS32_le()
				println("   - ${"0x%08X".format(p1)}, $p2, $p3, $p4")
			}
			"put_portal" -> {
				val args = s.readIntArray_le(8).toList()
				println("   - $args")
			}
			"event_start1" -> {
				val args = s.readIntArray_le(8).toList()
				println("   - $args")
			}
			"event_start2" -> {
				val args = s.readIntArray_le(6).toList()
				println("   - $args")
			}
		}
		*/

		return Function(id, name, unk, ptr, args)
	}
}