package com.talestra.yume.formats

import com.soywiz.korio.stream.*
import com.talestra.rhcommon.lang.getu
import com.talestra.rhcommon.lang.invalidOp
import com.talestra.rhcommon.lang.mapWhile
import com.talestra.rhcommon.text.StrReader

object WSC {
	object Encryption {
		private fun ror2(v: Int): Int = (v shl 6) or (v ushr 2)
		private fun rol2(v: Int): Int = (v shl 2) or (v ushr 6)

		fun decryptStream2(data: SyncStream): SyncStream = decryptInline(data.readAll()).openSync("r")
		fun encryptStream2(data: SyncStream): SyncStream = encryptInline(data.readAll()).openSync("r")

		fun decrypt(data: ByteArray) = decryptInline(data.copyOf())
		fun encrypt(data: ByteArray) = encryptInline(data.copyOf())

		private fun decryptInline(data: ByteArray): ByteArray = data.apply {
			for (n in data.indices) data[n] = ror2(data.getu(n)).toByte()
		}

		private fun encryptInline(data: ByteArray): ByteArray = data.apply {
			for (n in data.indices) data[n] = rol2(data.getu(n)).toByte()
		}
	}

	enum class Opcode(val id: Int, val format: String) {
		JUMP_IF_NOT(0x01, "Of2l."),
		OPTION_SELECT(0x02, "C[2t22s]"),
		SET(0x03, "ofkF."),
		EXIT(0x04, ""),
		TIMER_WAIT(0x05, "1"),
		JUMP(0x06, "L1"),
		SCRIPT(0x07, "s"),
		TEXT_SIZE(0x08, "2"),
		SCRIPT_CALL(0x09, "s"),
		SCRIPT_RET(0x0A, "1"),
		TIMER_SET(0x0B, "2"),
		TIMER_DEC(0x0C, "21"),
		MUSIC_PLAY(0x21, "12s"),
		MUSIC_STOP(0x22, "121"),
		VOICE_PLAY(0x23, "1222s"),
		SOUND_PLAY(0x25, "111122s"),
		SOUND_STOP(0x26, "2"),
		UNK_28(0x28, "12"),
		TEXT(0x41, "21t"),
		TEXT_WITH_TITLE(0x42, "4tt"),
		ANIM_LOAD(0x43, "42s"),
		TABLE_ANIM_OBJECT_PUT(0x45, "121"),
		BACKGROUND(0x46, "22221s"),
		BG_BLACK(0x47, "11"),
		CHARA_PUT(0x48, "122221s"),
		CLEAR_L1(0x49, "2."),
		TRANSITION(0x4A, "12."),
		ANIMATE_ADD(0x4B, "1222221"),
		ANIMATE_PLAY(0x4C, "1"),
		EFFECT(0x4D, "1121"),
		TABLE_ANIM_OBJECT_UNPUT(0x4F, "121"),
		TABLE(0x50, "s"),
		TABLE_SELECT(0x51, "ff1"),
		SOUND_WAIT(0x52, "2"),
		TRANS_IMAGE(0x54, "s"),
		UNK_55(0x55, "1"),
		MOVIE(0x61, "1s"),
		UNK_64(0x64, "4"),
		UNK_68(0x68, "2221"),
		OBJ_PUT(0x73, "22221s"),
		OBJ_CLEAR(0x74, "2"),
		WAIT(0x82, "21"),
		RUN_LOAD(0x83, "1"),
		INGAME_SET(0x85, "2"),
		ANIMATE_START(0x86, "2"),
		UNK_89(0x89, "1"),
		RUN_CONFIG(0x8B, "1"),
		INGAME_SCRIPT_ID(0x8C, "3"),
		UNK_8E(0x8E, "1"),
		TEXT_ADD(0xB6, "2t"),
		CLEAR_L2(0xB8, "3"),
		RUN_QLOAD(0xE2, "1"),
		EOF(0xFF, "");

		companion object {
			val BY_ID = values().associateBy { it.id }
		}
	}

	data class Instruction(val script: String, val offset: Int, val op: Opcode, val params: List<Any>)

	annotation class Action(val opcode: Opcode)

	fun SyncStream.readOpcode(): Opcode {
		val id = this.readU8()
		return Opcode.BY_ID[id] ?: invalidOp("Unknown opcode $id")
	}

	fun SyncStream._readInstruction(script: String): Instruction {
		val offset = this.position.toInt()
		val op = readOpcode()
		val i = Instruction(script = script, offset = offset, op = op, params = readParams(offset, op, StrReader(op.format)))
		return i
	}

	data class Text(val raw: String) {
		val str = raw.replace("\\n", "\n")
	}

	enum class OpsSet(val id: Int, val str: String) {
		INVALID(-1, "INVALID"),
		RANGE(0, "RANGE"),
		ASSIGN(1, "="),
		INC(2, "+"),
		DEC(3, "-"),
		REF(4, "ref"),
		REM(5, "%"),
		RAND(6, "rand")
		;

		companion object {
			val BY_ID = OpsSet.values().associateBy { it.id }
		}
	}

	enum class OpsJump(val id: Int, val str: String, val check: (Int, Int) -> Boolean) {
		INVALID(-1, "invalid!", { a, b -> false }),
		NONE(0, "", { a, b -> false }),
		GE(1, ">=", { a, b -> a >= b }),
		LE(2, "<=", { a, b -> a <= b }),
		EQ(3, "==", { a, b -> a == b }),
		NE(4, "!=", { a, b -> a != b }),
		GT(5, ">", { a, b -> a > b }),
		LT(6, "<", { a, b -> a < b });

		companion object {
			val BY_ID = values().associateBy { it.id }
		}
	}

	data class Flag(val id: Int) {
		override fun toString(): String = "@%d".format(id)
	}

	data class Address(val address: Int) {
		override fun toString(): String = "Address(0x%08X)".format(address)
	}

	fun SyncStream.readParams(offset: Int, op: Opcode, format: StrReader): List<Any> {
		val out = arrayListOf<Any>()
		var lastCount = 0
		read@ while (!format.eof) {
			val f = format.read()
			when (f) {
				'1' -> out += readU8()
				'.' -> {
					val v = readU8()
					if (v != 0) invalidOp("Expected ignored parameter to be 0!")
				}
				'3' -> out += readU24_le()
				'2' -> out += readS16_le()
				'f' -> out += Flag(readU16_le())
				'F' -> out += readU16_le()
				'O' -> {
					val jumpop = readU8()
					out += OpsJump.BY_ID[jumpop and 0x7] ?: OpsJump.INVALID
					out += (jumpop ushr 4)
				}
				'o' -> {
					val setop = readU8()
					out += OpsSet.BY_ID[setop] ?: OpsSet.INVALID
				}
				'k' -> out += readU8()
				'l' -> out += Address(readS32_le() + this.position.toInt() + 1)
				'L' -> out += Address(readS32_le())
				'4' -> out += readS32_le()
				's' -> out += readStringz()
				't' -> out += Text(readStringz(Charsets.ISO_8859_1))
				'C' -> {
					// @CHECK
					lastCount = readU16_le()
					//lastCount = readU8()
					//out += lastCount
				}
				'[' -> {
					//println("lastCount: $lastCount")
					val format2 = format.clone()
					var format3 = format2
					out.add((0 until lastCount).map {
						format3 = format2.clone()
						readParams(offset, op, format3)
					} as Any)
					format.offset = format3.offset
				}
				']' -> break@read
				else -> throw RuntimeException("Not supported '$f'")
			}
		}
		return out
	}

	fun SyncStream._readInstructions(script: String): List<Instruction> = mapWhile({ !eof }) { _readInstruction(script) }

	fun parse(s: SyncStream, script: String): List<Instruction> = s._readInstructions(script)

	fun readInstruction(s: SyncStream, script: String): Instruction = s._readInstruction(script)
	fun readInstructions(s: SyncStream, script: String): List<Instruction> = s._readInstructions(script)
}