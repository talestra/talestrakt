package com.talestra.games.hanabira

import com.soywiz.korio.crypto.md5
import com.soywiz.korio.error.invalidOp
import com.soywiz.korio.serialization.binary.*
import com.soywiz.korio.stream.*
import com.soywiz.korio.util.mapWhile
import com.soywiz.korio.util.readStringz
import com.soywiz.korio.util.toHexStringLower
import java.nio.charset.Charset
import kotlin.experimental.xor

object MSD {
	class Header(
			@Order(0) @Count(0x10) @Encoding("UTF-8") val magic: String,
			@Order(1) val unk1: Int,
			@Order(2) val table1Count: Int,
			@Order(3) val table2Count: Int
	) : Struct

	val SHIFT_JIS = Charset.forName("SHIFT_JIS")

	fun decryptIfRequired(data: ByteArray): ByteArray = if (data.readStringz(0, 0x10) == "MSCENARIO FILE  ") data else decrypt(data)

	fun decrypt(data: ByteArray): ByteArray = decryptInsitu(data.copyOf())

	fun decryptInsitu(data: ByteArray): ByteArray {
		for (n in 0 until Math.ceil(data.size.toDouble() / 32.0).toInt()) {
			val hash = "その花びらにくちづけを$n".toByteArray(SHIFT_JIS).md5().toHexStringLower().toByteArray()
			val pos = n * 0x20
			val remaining = data.size - pos
			for (m in 0 until Math.min(0x20, remaining)) {
				data[pos + m] = data[pos + m] xor hash[m]
			}
		}
		return data
	}

	annotation class Run(val op: Opcode)

	enum class Opcode(val id: Int) {
		VALUE(0),
		FUNC_START(1),
		SCRIPT(2),
		FUNC_END(3),
		SWITCH(4),
		SET_GLOBAL(5),
		JUMP_IF(6),
		UNK_7(7),
		UNK_8(8),

		BUFFER_SET(100),
		IMAGE_UNSET(101),
		IMAGE_SET(102),
		IMAGE_POSITION(103),
		IMAGE_SET_FROM_BUFFER(106),
		IMAGE_DRAW(107),
		UNK_108(108),
		ANIMATE(110),

		MUSIC_PLAY(201),
		UNK_202(202),
		UNK_208(208),
		UNK_209(209),
		SOUND_EFFECT(211),

		SAVE_POINT(1001),
		UNK_1002(1002),
		UNK_1004(1004),
		SAVE_TITLE(1005),
		UNK_1006(1006),
		UNK_1007(1007),
		UNK_1008(1008),

		UNK_2000(2000),
		TEXT_COLOR(2001),
		UNK_2003(2003),
		UNK_2005(2005),
		UNK_2006(2006),
		CHARA_ID(2007),
		VOICE(2008),
		WAIT_CLICK(2009),
		TEXT(2010),
		UNK_2013(2013),
		UNK_2014(2014),
		UNK_2015(2015),
		UNK_2016(2016),
		UNK_2017(2017),
		UNK_2018(2018),

		COLOR_UNK(2020),

		END(10000);

		companion object {
			val ops = values().map { it.id to it }.toMap()
		}
	}

	val charaNames = mapOf(
			-1 to "-",
			0 to "NANA",
			1 to "YUUNA",
			2 to "GIRL_A",
			3 to "GIRL_B",
			4 to "GIRL_C",
			5 to "TEACHER",
			6 to "CHILD_A",
			7 to "CHILD_B",
			8 to "???"
	)

	data class REF(val id: Int)
	data class REF_UNK(val id: Int)

	data class INSTRUCTION(val pos: Long, val op: Opcode, val args: List<Any>) {
		override fun toString(): String = "%08X: %s %s".format(pos, op, args)
	}

	class Script(
			val table1: List<Int>,
			val table2: List<Int>,
			val instructions: List<INSTRUCTION>
	)

	class ScriptReader(val script: Script) {
		var position = 0
	}

	fun read(data: ByteArray): Script {
		val s = decryptIfRequired(data).openSync()
		val h = s.readStruct<Header>()
		if (h.magic != "MSCENARIO FILE  ") invalidOp("Not a msd file")
		s.position = 0x458
		val table1 = (0 until h.table1Count).map { s.readS32_le() }
		val table2 = (0 until h.table2Count).map { s.readS32_le() }
		return Script(table1, table2, readInstructions(s))
	}

	fun readInstructions(s: SyncStream): List<INSTRUCTION> {
		return mapWhile(cond = { !s.eof }, gen = { readInstruction(s) })
	}

	fun readInstruction(s: SyncStream): INSTRUCTION {
		val pos = s.position
		val op = s.readU16_le()
		val args = readParams(s.readStream(s.readU16_le()))
		val i = INSTRUCTION(pos, Opcode.ops[op] ?: invalidOp("Unknown op $op"), args)
		//println(i)
		return i
	}

	fun readParams(s: SyncStream): List<Any> {
		return mapWhile(cond = { !s.eof }, gen = { readParam(s) })
	}

	fun readParam(s: SyncStream): Any {
		val kind = s.readU8()
		return when (kind) {
		//0 -> s.readS64_le()
			1 -> s.readS32_le()
			2 -> REF(s.readS32_le())
			3 -> s.readStringz(SHIFT_JIS)
			4 -> {
				val out = arrayListOf<Pair<Int, Int>>()
				while (!s.eof) {
					out += s.readS32_le() to s.readS32_le()
				}
				out
			}
			5 -> REF_UNK(s.readS32_le())
			else -> TODO("readParam kind: $kind")
		}
	}
}