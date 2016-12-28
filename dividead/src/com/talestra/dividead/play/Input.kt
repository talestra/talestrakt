package com.talestra.dividead.play

import com.soywiz.korio.async.Signal
import com.soywiz.korio.async.asyncFun

open class Input {
	val onClick = Signal<Unit>()
	val onKeyPress = Signal<Unit>()
	open var skipping = false

	suspend open fun waitText(): Unit = asyncFun {
		if (skipping) {
			Unit
		} else {
			TODO("Not implemented waitText")
			//return Promise.any(onKeyPress.waitOneAsync(), onClick.waitOneAsync())
		}
	}
}