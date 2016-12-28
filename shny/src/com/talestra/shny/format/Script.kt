package com.talestra.shny.format

import com.soywiz.korio.stream.*
import com.talestra.rhcommon.lang.invalidOp
import java.nio.charset.Charset

object Script {
	private fun SyncStream.readStringLen2(): String {
		val len = readU16_le()
		return readStringz(len, Charset.forName("SHIFT-JIS"))
	}

	private fun SyncStream.readText(): String {
		return readStringLen2()
	}

	enum class FlagSetOp(val id: Int, val str: String) {
		ASSIGN(0, "="),
		ADD(1, "+="),
		SUB(2, "-="),
		MUL(3, "*="),
		DIV(4, "/="),
		REM(5, "%="),
		AND(6, "&="),
		OR(7, "|=");

		companion object {
			val BY_ID = values().associateBy { it.id }
		}
	}

	enum class Opcode(val id: Int, val reader: SyncStream.() -> List<Any>) {
		INVALID(-1, reader = { listOf() }),
		EOF(0x00, reader = { listOf() }),
		TEXT(0x01, reader = { listOf(readText()) }),
		VOICE(0x03, reader = { listOf(readStringLen2()) }),
		UNK5D(0x5D, reader = {
			val kind = readU8()
			val p1 = if (kind != 3) readU16_le() else 0
			val p2 = if (kind < 2) readU16_le() else 0
			val p3 = if (kind < 2) readU16_le() else 0
			listOf(kind, p1, p2, p3)
		}),

		UNK73(0x73, reader = { listOf(readU8()) }),
		UNK63(0x63, reader = { listOf(readU16_le()) }),
		UNK7B(0x7B, reader = { listOf() }),
		UNK7D(0x7D, reader = { listOf() }),
		UNK7E(0x7E, reader = { listOf() }),
		UNK40(0x40, reader = {
			val kind = readU8()
			val p1 = readU16_le()
			val p2 = if (kind == 0) readU16_le() else 0
			listOf(kind, p1, p2)
		}),
		OPTION_ADD(0x11, reader = {
			val kind = readU8()
			val optionId = readU16_le()
			val p2 = if (kind != 0) readU16_le() else 0
			val p3 = if (kind != 0) readU16_le() else 0
			val text = readStringLen2()
			val address = readU16_le() + position.toInt()
			listOf(text, address, optionId, p2, p3)
		}),
		JUMP_IF(0x12, reader = {
			val flag = readU16_le()
			val op = readU8()// ["!=", "==", "<", ">", "<=", ">="]
			val value = readU16_le()
			val address = readU16_le() + position.toInt()
			listOf(flag, op, value, address)
		}),
		JUMP(0x13, reader = {
			listOf(readU16_le() + position.toInt())
		}),
		CALL(0x14, reader = {
			listOf(readU16_le() + position.toInt())
		}),
		RETURN(0x15, reader = {
			listOf()
		}),
		MAP_RETURN(0x16, reader = {
			listOf()
		}),
		FACE_RETURN(0x17, reader = {
			listOf()
		}),
		SCRIPT(0x18, reader = {
			listOf(readStringLen2())
		}),
		PRELOAD_START(0x1A, reader = {
			listOf()
		}),
		PRELOAD_END(0x1B, reader = {
			listOf()
		}),
		OPTION_RESET(0x1C, reader = {
			listOf()
		}),
		OPTION_SHOW(0x1D, reader = {
			listOf(readU8())
		}),
		FACE_SHOW(0x20, reader = {
			listOf(readU16_le())
		}),
		MAP_SHOW(0x21, reader = {
			listOf(readStringLen2())
		}),
		FACE_30(0x30, reader = {
			val p1 = readU8()
			val p2 = readU8()
			val p3 = readU16_le()
			listOf(p1, p2, p3)
		}),
		FACE_66(0x66, reader = {
			val kind = readU8()
			val p1 = if (kind == 0) readU8() else 0
			val p2 = if (kind == 0) readU16_le() else 0
			listOf(kind, p1, p2)
		}),
		FACE_67(0x67, reader = {
			listOf(readU8())
		}),
		FACE_68(0x68, reader = {
			listOf(readU8())
		}),
		FACE_6B(0x6B, reader = {
			listOf(readU8(), readU16_le())
		}),
		GAME_END(0x31, reader = {
			listOf()
		}),
		CHARA_PUT(0x32, reader = {
			val kind = readU8()
			val p1 = readU16_le()
			val p2 = readU8()
			val p3 = readU16_le()
			val p4 = readU8()
			val p5 = if (kind != 0) readU16_le() else 0
			val p6 = readU16_le()
			listOf(kind, p1, p2, p3, p4, p5, p6)
		}),
		CHARA_REMOVE(0x33, reader = {
			val kind = readU8()
			val p1 = readU16_le()
			val p2 = if (kind !== 0) readU16_le() else 0
			val p3 = if (kind !== 0) readU16_le() else 0
			listOf(kind, p1, p2, p3)
		}),
		CHARA_MOVE(0x34, reader = {
			listOf(readU16_le(), readU16_le(), readU16_le(), readU16_le())
		}),
		CHARA_SUIT(0x35, reader = {
			val type = readU8()
			val p1 = if (type <= 1) readU16_le() else 0
			val p2 = if (type == 0) readU8() else 0
			listOf(type, p1, p2)
		}),
		BACKGROUND(0x36, reader = {
			val kind = readU8()
			val str = readStringLen2()
			val p1 = readU8()
			val p2 = readU16_le()
			val p3 = readU16_le()
			val p4 = if (kind == 0) readU16_le() else 0
			val p5 = if (kind == 0) readU16_le() else 0
			listOf(str, p1, p2, p3, p4, p5)
		}),
		BACKGROUND2(0x37, reader = {
			val p1 = readU8()
			val p2 = readStringLen2()
			listOf(p1, p2)
		}),
		BG_PRELOAD(0x38, reader = {
			val type = readU8()
			var str = ""
			var param = 0
			when (type) {
				0 -> {
					str = readStringLen2()
					param = readU16_le()
				}
				1 -> {
					str = readStringLen2()
				}
				2 -> Unit
			}
			listOf(type, str, param)
		}),
		OBJ_PUT(0x39, reader = {
			val kind = readU8()
			val str = readStringLen2()
			val p1 = readU16_le()
			val p2 = readU16_le()
			val p3 = readU16_le()
			val p4 = if (kind != 0) readU16_le() else 0
			val p5 = if (kind != 0) readU16_le() else 0
			listOf(kind, str, p1, p2, p3, p4, p5)
		}),
		OBJ_UNLOAD(0x3A, reader = {
			val kind = readU8()
			val str = readStringLen2()
			val p1 = if (kind != 0) readU16_le() else 0
			val p2 = if (kind != 0) readU16_le() else 0
			listOf(kind, str, p1, p2)
		}),
		OBJ_PRELOAD(0x3C, reader = {
			val kind = readU8()
			var str = ""
			var p1 = 0
			var p2 = 0
			when (kind) {
				0 -> {
					str = readStringLen2()
					p1 = readU8()
					p2 = readU16_le()
				}
				1 -> str = readStringLen2()
				2 -> Unit
			}
			listOf(str, p1, p2)
		}),
		TALKER(0x3D, reader = {
			val kind = readU8()
			val p1 = readU16_le()
			val p2 = if (kind == 0 || kind == 1) readU16_le() else 0
			listOf(kind, p1, p2)
		}),
		TEXT_BG(0x3E, reader = {
			listOf(readU8(), readU16_le())
		}),
		BACKGROUND3(0x52, reader = {
			val str = readStringLen2()
			val p1 = readU16_le()
			val p2 = readU16_le()
			val p3 = readU16_le()
			val p4 = readU16_le()
			listOf(str, p1, p2, p3, p4)
		}),
		FADE_IN(0x56, reader = {
			val type = readU8()
			val param = if (type < 8) readU16_le() else 0
			listOf(type, param)
		}),
		FADE_OUT(0x57, reader = {
			val type = readU8()
			val param = if (type < 8) readU16_le() else 0
			listOf(type, param)
		}),
		MOVIE_PLAY(0x5B, reader = {
			listOf(readStringLen2(), readU16_le())
		}),
		MUSIC(0x5E, reader = {
			val type = readU8()
			val str = if (type == 0) readStringLen2() else ""
			val p1 = readU16_le()
			val p2 = readU16_le()
			listOf(type, str, p1, p2)
		}),
		FLAG_SET(0x60, reader = {
			val flag = readU16_le()
			val setop = FlagSetOp.BY_ID[readU8()]!!
			val value = readU16_le()
			listOf(flag, setop, value)
		}),
		WAIT(0x61, reader = {
			val kind = readU8()
			val param = when (kind) {
				0 -> readU16_le()
				1 -> 0
				2 -> 0
				else -> 0
			}
			listOf(kind, param)

		}),
		VOICE_OVER(0x65, reader = {
			listOf()
		}),
		VOICE2(0x69, reader = {
			listOf(readStringLen2())
		}),
		MINIGAME(0x72, reader = {
			listOf(readU8())
		}),
		TITLE(0x75, reader = {
			listOf(readText())
		}),
		TEXT_ID(0x77, reader = {
			listOf(readU16_le(), readU16_le())
		}),
		PROGRESSION(0x78, reader = {
			listOf(readU16_le())
		}),
		ASK_AUTOSKIP(0x7A, reader = {
			listOf()
		});

		companion object {
			val BY_ID = values().associateBy { it.id }
		}
	}

	annotation class Action(val op: Opcode)
	data class Instruction(val offset: Int, val opId: Int, val op: Opcode, val params: List<Any>)

	fun check(s2: SyncStream) {
		val s = s2.slice()
		if (s.readStringz(4) != "OBJ") invalidOp("Not a shny script")
		val size = s.readU32_le()
		if (s.length != size) invalidOp("Invalid file")
	}

	fun readInstruction(s: SyncStream): Instruction {
		val offset = s.position.toInt()
		val opId = s.readU8()
		val opcode = Opcode.BY_ID[opId] ?: Opcode.INVALID
		val params = opcode.reader(s)
		println("$opcode: $params")
		return Instruction(offset, opId, opcode, params)
	}
}