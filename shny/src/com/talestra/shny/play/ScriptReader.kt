package com.talestra.shny.play

import com.talestra.shny.format.Script

@Singleton
class ScriptReader(val iso: GameIso) {
	var s: Stream2 = MemoryStream2()
	var scriptName = ""

	fun setScriptAsync(name: String): Promise<Unit> = async {
		if (scriptName == name) return@async Unit
		scriptName = name
		s = iso.root["/PSP_GAME/USRDIR/data/script/$name"].readStreamAsync().await()
		s.position = 8
	}

	fun setScriptAsync(name: String, offset: Int) = async<Unit> {
		setScriptAsync(name).await()
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

	fun retAsync(): Promise<Unit> = async {
		val entry = stack.pop()
		setScriptAsync(entry.script, entry.offset).await()
	}
}