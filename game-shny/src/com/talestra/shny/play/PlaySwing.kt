package com.talestra.shny.play

import com.soywiz.korio.async.sync
import com.soywiz.korio.vfs.LocalVfs
import com.talestra.rhcommon.inject.AsyncInjector

fun main(args: Array<String>) = sync {
	val injector = AsyncInjector()
	val haruhiIso = LocalVfs("D:/isos/psp/haruhi.iso")

	injector.map(GameIso.fromIso(haruhiIso.open()))
	val executor = injector.get<ScriptExecutor>()
	executor.reader.setScript("s_0000ess0.dat")
	while (true) {
		executor.exec()
	}
}