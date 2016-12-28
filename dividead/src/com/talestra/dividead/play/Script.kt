package com.talestra.dividead.play

import com.talestra.dividead.AB

open class Script() {
	init {
		//var s: Stream2, startposition: Int = 0
		//s.position = startposition.toLong()
	}

	lateinit var s: Stream2

	open fun setScript(name: String) {
	}

	fun setScript(name: String, offset: Int) {
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