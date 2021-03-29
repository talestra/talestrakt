package com.talestra.games.toa

import com.soywiz.korio.async.EventLoop
import com.soywiz.korui.Application
import com.soywiz.korui.frame

object ToaPatcher {
	@JvmStatic fun main(args: Array<String>) = EventLoop.main {
		Application().frame("Tales of the Abyss en español") {

		}
	}
}