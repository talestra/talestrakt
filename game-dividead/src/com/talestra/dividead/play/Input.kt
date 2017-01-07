package com.talestra.dividead.play

abstract class Input {
	open var skipping = false

	suspend abstract fun waitText(): Unit
}