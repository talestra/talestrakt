package com.talestra.dividead.play

import com.soywiz.korio.async.Signal
import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.async.executeInWorker
import com.soywiz.korio.async.sleep

open class Input {
	val onClick = Signal<Unit>()
	val onKeyPress = Signal<Unit>()
	open var skipping = false

	suspend open fun waitText(): Unit = asyncFun {
		if (skipping) {
			Unit
		} else {
			//TODO("Not implemented waitText")
			sleep(500)
			//return Promise.any(onKeyPress.waitOneAsync(), onClick.waitOneAsync())
		}
	}
}