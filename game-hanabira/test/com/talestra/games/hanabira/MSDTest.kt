package com.talestra.games.hanabira

import com.soywiz.korio.async.syncTest
import com.soywiz.korio.stream.openSync
import com.soywiz.korio.vfs.ResourcesVfs
import org.junit.Test

class MSDTest {
	@Test
	fun name() = syncTest {
		val root = ResourcesVfs["MSE"].openFJSYS()
		//val data = root["main.MSD"].read()
		for (child in root.list()) {
			val data = child.read()
			val script = MSD.read(MSD.decryptIfRequired(data).openSync())
			println("%s: %d".format(child.basename, script.instructions.size))
		}
	}
}