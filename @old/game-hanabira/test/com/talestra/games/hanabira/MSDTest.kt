package com.talestra.games.hanabira

import com.soywiz.korio.async.syncTest
import com.soywiz.korio.stream.openSync
import com.soywiz.korio.vfs.ResourcesVfs
import org.junit.Test

class MSDTest {
	@Test
	fun name() = syncTest {
		val root = ResourcesVfs["MSE"].openFJSYS()
		//val script = MSD.read(root["main.MSD"].read())
		val script = MSD.read(root["S001.MSD"].read())
		for (i in script.instructions) {
			println(i)
		}
		/*
		for (child in root.list()) {
			val script = MSD.read(child.read())
			println("%s: %d".format(child.basename, script.instructions.size))
		}
		*/
	}
}