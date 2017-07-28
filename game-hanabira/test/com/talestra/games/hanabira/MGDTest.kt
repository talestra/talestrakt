package com.talestra.games.hanabira

import com.soywiz.korim.format.readImageData
import com.soywiz.korio.async.syncTest
import com.soywiz.korio.vfs.ResourcesVfs
import org.junit.Assert
import org.junit.Test

class MGDTest {
	@Test
	fun name() = syncTest {
		val image = ResourcesVfs["conf_p.MGD"].readImageData()
		Assert.assertEquals(10, image.frames.size)
		//for ((index, frame) in image.frames.withIndex()) {
		//	LocalVfs("C:/temp/hanabira")["$index.png"].writeBitmap(frame.bitmap)
		//}
	}
}