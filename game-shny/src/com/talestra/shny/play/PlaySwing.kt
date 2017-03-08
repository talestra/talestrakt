package com.talestra.shny.play

import com.soywiz.korio.async.syncTest
import com.soywiz.korio.inject.AsyncInjector
import com.soywiz.korio.vfs.LocalVfs

fun main(args: Array<String>) = syncTest {
	val injector = AsyncInjector()
	val haruhiIso = LocalVfs("D:/isos/psp/haruhi.iso")

	injector.map(GameIso.fromIso(haruhiIso.open()))
	val executor = injector.get<ScriptExecutor>()
	executor.reader.setScript("s_0000ess0.dat")
	while (true) {
		executor.exec()
	}
}