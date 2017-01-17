package com.talestra.criminalgirls

import com.soywiz.korio.util.ListReader

object CriminalGirlsTool {
	@JvmStatic fun main(args: Array<String>) {
		val argsr = ListReader(args.toList())
		while (!argsr.eof) {
			val arg = argsr.read()
			when (arg.toLowerCase()) {
				"-?" -> {

				}
			}
		}
		println("CriminalGirlsTool")
	}
}