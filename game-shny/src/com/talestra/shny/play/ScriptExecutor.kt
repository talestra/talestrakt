package com.talestra.shny.play

import com.soywiz.korim.awt.awtShowImage
import com.soywiz.korim.format.readBitmap
import com.soywiz.korio.async.invokeSuspend
import com.talestra.rhcommon.inject.Singleton
import com.talestra.shny.format.Script

@Singleton
class ScriptExecutor(
	val reader: ScriptReader,
	val state: GameState,
	val iso: GameIso
) {
	val actions = this.javaClass.declaredMethods.filter { it.getAnnotation(Script.Action::class.java) != null }.map { method ->
		val annotation = method.getAnnotation(Script.Action::class.java)
		annotation.op to method
	}.toMap()

	suspend fun exec() {
		val instruction = reader.readInstruction()
		val action = this.actions[instruction.op] ?: TODO("Unhandled instruction $instruction")
		action.invokeSuspend(this, instruction.params)
	}

	@Script.Action(Script.Opcode.TEXT) fun TEXT(str: String) {
		println(str)
	}

	@Script.Action(Script.Opcode.UNK40) fun UNK40(kind: Int, p1: Int, p2: Int) {
	}

	@Script.Action(Script.Opcode.UNK7B) fun UNK7B() {
	}

	@Script.Action(Script.Opcode.UNK7D) fun UNK7D() {
	}

	@Script.Action(Script.Opcode.UNK7E) fun UNK7E() {
	}

	@Script.Action(Script.Opcode.UNK63) fun UNK63(param: Int) {
	}

	@Script.Action(Script.Opcode.UNK73) fun UNK73(param: Int) {
	}

	@Script.Action(Script.Opcode.UNK5D) fun UNK5D(kind: Int, p1: Int, p2: Int, p3: Int) {
	}

	@Script.Action(Script.Opcode.TITLE) fun TITLE(str: String) {
		println(str)
	}

	@Script.Action(Script.Opcode.PROGRESSION) fun PROGRESSION(p1: Int) {
	}

	@Script.Action(Script.Opcode.JUMP) fun JUMP(address: Int) {
		reader.jump(address)
	}

	@Script.Action(Script.Opcode.FADE_OUT) fun FADE_OUT(type: Int, param: Int) {
	}

	@Script.Action(Script.Opcode.FADE_IN) fun FADE_IN(type: Int, param: Int) {
	}

	@Script.Action(Script.Opcode.ASK_AUTOSKIP) fun ASK_AUTOSKIP() {
	}

	@Script.Action(Script.Opcode.PRELOAD_START) fun PRELOAD_START() {
	}

	@Script.Action(Script.Opcode.PRELOAD_END) fun PRELOAD_END() {
	}

	@Script.Action(Script.Opcode.BG_PRELOAD) suspend fun BG_PRELOAD(type: Int, str: String, param: Int) {
		if (str != "") {
			val image = iso.root["PSP_GAME/USRDIR/data/bg/$str"].readBitmap()
			//showImage(image)
		}
	}

	@Script.Action(Script.Opcode.CHARA_SUIT) fun CHARA_SUIT(type: Int, chara: Int, suit: Int) {
		state.chars[chara].suit = suit
	}

	@Script.Action(Script.Opcode.BACKGROUND) suspend fun BACKGROUND(str: String, p1: Int, p2: Int, p3: Int, p4: Int, p5: Int) {
		val image = iso.root["PSP_GAME/USRDIR/data/bg/$str"].readBitmap()
		awtShowImage(image)
	}

	@Script.Action(Script.Opcode.BACKGROUND2) suspend fun BACKGROUND2(p1: Int, str: String) {
		val image = iso.root["PSP_GAME/USRDIR/data/bg/$str"].readBitmap()
		awtShowImage(image)
	}

	@Script.Action(Script.Opcode.WAIT) fun WAIT(kind: Int, param: Int) {
	}

	@Script.Action(Script.Opcode.MOVIE_PLAY) fun MOVIE_PLAY(str: String, param: Int) {
	}

	@Script.Action(Script.Opcode.TALKER) fun TALKER(kind: Int, p1: Int, p2: Int) {
	}

	@Script.Action(Script.Opcode.EOF) fun EOF() {
	}

	@Script.Action(Script.Opcode.TEXT_BG) fun TEXT_BG(p1: Int, p2: Int) {
	}

	@Script.Action(Script.Opcode.CALL) fun CALL(offset: Int) {
		reader.call(offset)
	}

	@Script.Action(Script.Opcode.MUSIC) fun MUSIC(type: Int, str: String, p1: Int, p2: Int) {
	}

	@Script.Action(Script.Opcode.CHARA_PUT) suspend fun CHARA_PUT(kind: Int, charaId: Int, p2: Int, p3: Int, p4: Int, p5: Int, p6: Int) {
		val charaName = "bu%02d_a%02d.gim".format(charaId, state.chars[charaId].suit)

		awtShowImage(iso.root["PSP_GAME/USRDIR/data/bu/$charaName"].readBitmap())
		//showImage(GIM.read(iso.root["PSP_GAME/USRDIR/data/bu/bu02_ak.gim"].open2("r")))
		//PKG.read(iso.root["PSP_GAME/USRDIR/data/bu/bu02_ak.pkg"].open2("r"))
	}

	@Script.Action(Script.Opcode.CHARA_REMOVE) fun CHARA_REMOVE(kind: Int, charaId: Int, p2: Int, p3: Int) {
	}

	@Script.Action(Script.Opcode.FLAG_SET) fun FLAG_SET(flag: Int, op: Script.FlagSetOp, value: Int) {
		when (op) {
			Script.FlagSetOp.ASSIGN -> state.flags[flag] = value
			Script.FlagSetOp.ADD -> state.flags[flag] += value
			Script.FlagSetOp.SUB -> state.flags[flag] -= value
			Script.FlagSetOp.MUL -> state.flags[flag] *= value
			Script.FlagSetOp.DIV -> state.flags[flag] /= value
			Script.FlagSetOp.REM -> state.flags[flag] %= value
			Script.FlagSetOp.AND -> state.flags[flag] = state.flags[flag] and value
			Script.FlagSetOp.OR -> state.flags[flag] = state.flags[flag] or value
		}
	}

	@Script.Action(Script.Opcode.FACE_SHOW) fun FACE_SHOW(id: Int) {
	}

	@Script.Action(Script.Opcode.SCRIPT) suspend fun SCRIPT(str: String) {
		reader.setScript(str)
	}
}