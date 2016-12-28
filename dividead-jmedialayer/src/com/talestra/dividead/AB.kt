package com.talestra.dividead

import com.jtransc.io.ra.RAByteArray
import com.jtransc.io.ra.RAStream

open class AB() {
	var s: RAStream = RAByteArray(byteArrayOf())

	fun RAStream.readF() = readU16_LE()
	fun RAStream.read2() = readU16_LE()
	fun RAStream.readc() = readU8_LE().toChar()
	fun RAStream.readP() = readS32_LE()
	fun RAStream.readS() = readStringz()
	fun RAStream.readT() = readStringz()

	fun executeOne() {
		val op = s.readU8_LE()
		println("%02X".format(op))
		when (op) {
			0x00 -> {
				savepoint()
				val text = s.readT()
				TEXT(text)
			}

			0x02 -> {
				val address = s.readP()
				JUMP(address)
			}
			0x03 -> {
				val flag1 = s.readF()
				val flag2 = s.readF()
				val value = s.read2()
				SET_RANGE_FLAG(flag1, flag2, value)
			}
			0x04 -> {
				val flag = s.readF()
				val cond = s.readc()
				val value = s.read2()
				SET(flag, cond, value)
			}
			0x10 -> {
				val flag = s.readF()
				val cond = s.readc()
				val value = s.read2()
				val address = s.readP()
				JUMP_IF_NOT(flag, cond, value, address)
			}
			0x18 -> {
				val script = s.readS()
				SCRIPT(script)
			}
			0x19 -> {
				GAME_END()
			}
			else -> {
				throw RuntimeException("Unimplemented opcode $op")
			}
		}
	}

	/**
	 * Prints a text on the screen
	 */
	private fun TEXT(text: String) {
		//TEXT(id = 0x00, format = "T", description = "Prints a text on the screen", savepoint = true),
	}

	/**
	 * Reached a savepoint
	 */
	open fun savepoint() {

	}

	/**
	 * Ends the game
	 */
	open fun GAME_END() {

	}

	/**
	 * Loads and executes a script
	 */
	open fun SCRIPT(script: String) {
	}

	/**
	 * Sets a flag with a value
	 */
	open fun SET(flag: Int, cond: Char, value: Int) {
	}

	/**
	 * Sets a range of flags to a value
	 */
	open fun SET_RANGE_FLAG(flag1: Int, flag2: Int, value: Int) {
	}

	/**
	 * Jumps unconditionally to a fixed address
	 */
	open fun JUMP(address: Int) {
	}

	/**
	 * Jumps if the condition is not true
	 */
	open fun JUMP_IF_NOT(flag: Int, cond: Char, value: Int, address: Int) {
	}

	/*
	enum class Opcode(val id: Int, val format: String, val description: String, val savepoint: Boolean = false) {
		TITLE(id = 0x50, format = "T", description = "Sets the title for the save"),
		OPTION_RESET(id = 0x06, format = "", description = "Empties the option list", savepoint = true),
		OPTION_ADD(id = 0x01, format = "PT", description = "Adds an option to the list of options"),
		OPTION_SHOW(id = 0x07, format = "", description = "Show the list of options"),
		OPTION_RESHOW(id = 0x0A, format = "", description = "Shows again a list of options"),
		MAP_IMAGES(id = 0x37, format = "SS", description = "Sets the images that will be used in the map overlay"),
		MAP_OPTION_RESET(id = 0x38, format = "", description = "Empties the map_option list", savepoint = true),
		MAP_OPTION_ADD(id = 0x40, format = "P2222", description = "Adds an option to the map_option list"),
		MAP_OPTION_SHOW(id = 0x41, format = "", description = "Shows the map and waits for selecting an option"),
		WAIT(id = 0x11, format = "2", description = "Wait `time` milliseconds"),
		MUSIC_PLAY(id = 0x26, format = "S", description = "Starts a music"),
		MUSIC_STOP(id = 0x28, format = "", description = "Stops the currently playing music"),
		VOICE_PLAY(id = 0x2B, format = "S", description = "Plays a sound in the voice channel"),
		EFFECT_PLAY(id = 0x35, format = "S", description = "Plays a sound in the effect channel"),
		EFFECT_STOP(id = 0x36, format = "", description = "Stops the sound playing in the effect channgel"),
		FOREGROUND(id = 0x46, format = "S", description = "Sets an image as the foreground"),
		BACKGROUND(id = 0x47, format = "s", description = "Sets an image as the background"),
		IMAGE_OVERLAY(id = 0x16, format = "S", description = "Puts an image overlay on the screen"),
		CHARA1(id = 0x4B, format = "S", description = "Puts a character in the middle of the screen"),
		CHARA2(id = 0x4C, format = "SS", description = "Puts two characters in the screen"),
		ANIMATION(id = 0x4D, format = "", description = "Performs an animation with the current background (ABCDEF)"),
		SCROLL_DOWN(id = 0x4E, format = "", description = "Makes an scroll to the bottom with the current image"),
		SCROLL_UP(id = 0x4F, format = "", description = "Makes an scroll to the top with the current image"),
		CLIP(id = 0x30, format = "2222", description = "Sets a clipping for the screen"),
		REPAINT(id = 0x14, format = "2", description = "Repaints the screen"),
		REPAINT_IN(id = 0x4A, format = "2", description = "Repaints the inner part of the screen"),
		FADE_OUT_BLACK(id = 0x1E, format = "", description = "Performs a fade out to color black"),
		FADE_OUT_WHITE(id = 0x1F, format = "", description = "Performs a fade out to color white");

		companion object {
			val BY_ID = values().associateBy { it.id }
		}
	}

	data class Instruction(val offset: Int, val op: Opcode, val param: List<Any>)

	annotation class Action(val opcode: Opcode)

	fun readInstruction(s: Stream2): Instruction {
		val offset = s.position.toInt()
		val op = Opcode.BY_ID[s.readU16_le()]!!
		val params = arrayListOf<Any>()
		for (c in op.format) {
			when (c) {
				'P' -> params += s.readS32_le()
				'F' -> params += s.readU16_le()
				'2' -> params += s.readU16_le()
				'T' -> params += s.readStringz()
				'S' -> params += s.readStringz()
				's' -> params += s.readStringz()
				'c' -> params += s.readU8().toChar()
				else -> invalidOp("Not implemented $c")
			}
		}
		return Instruction(offset, op, params)
	}
	*/
}

