package com.talestra.dividead.play

import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.stream.SyncStream
import com.talestra.dividead.AB

open class Script() {
	init {
		//var s: Stream2, startposition: Int = 0
		//s.position = startposition.toLong()
	}

	lateinit var s: SyncStream

	suspend open fun setScript(name: String) {
	}

	suspend fun setScript(name: String, offset: Int) = asyncFun {
		setScript(name)
		jump(offset)
	}

	open fun jump(offset: Int) {
		s.position = offset.toLong()
	}

	open fun read(): AB.Instruction {
		return AB.readInstruction(s)
	}
}