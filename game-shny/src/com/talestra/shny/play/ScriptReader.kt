package com.talestra.shny.play

import com.soywiz.korio.inject.Singleton
import com.soywiz.korio.stream.MemorySyncStream
import com.soywiz.korio.stream.SyncStream
import com.talestra.rhcommon.ds.Stack
import com.talestra.shny.format.Script

@Singleton
class ScriptReader(val iso: GameIso) {
	var s: SyncStream = MemorySyncStream()
	var scriptName = ""

	suspend fun setScript(name: String) {
		if (scriptName == name) return
		scriptName = name
		s = iso.root["/PSP_GAME/USRDIR/data/script/$name"].readAsSyncStream()
		s.position = 8
	}

	suspend fun setScript(name: String, offset: Int) {
		setScript(name)
		s.position = offset.toLong()
	}

	fun jump(address: Int) {
		s.position = address.toLong()
	}

	fun readInstruction() = Script.readInstruction(s)

	class StackEntry(val script: String, val offset: Int)

	val stack = Stack<StackEntry>()

	fun call(offset: Int) {
		stack.push(StackEntry(scriptName, this.s.position.toInt()))
	}

	suspend fun ret() {
		val entry = stack.pop()
		setScript(entry.script, entry.offset)
	}
}