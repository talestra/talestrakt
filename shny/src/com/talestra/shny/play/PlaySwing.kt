package com.talestra.shny.play

import java.io.File

fun main(args: Array<String>) {
	EventLoop.mainAsync {
		val injector = Injector()
		injector.map(GameIso.fromIsoAsync(File("D:/isos/psp/haruhi.iso").openAsync2().await()).await())
		val executor = injector.get<ScriptExecutor>()
		executor.reader.setScriptAsync("s_0000ess0.dat")
		while (true) {
			executor.execAsync().await()
		}
	}
}