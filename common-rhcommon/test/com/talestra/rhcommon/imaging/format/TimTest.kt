package com.talestra.rhcommon.imaging.format

import com.soywiz.korim.awt.awtShowImage
import com.soywiz.korim.format.readBitmap
import com.soywiz.korio.async.sync
import com.soywiz.korio.vfs.ResourcesVfs
import org.junit.Test

class TimTest {
	@Test
	fun name(): Unit = sync {
		val image = ResourcesVfs["test.tim"].readBitmap()
		//showImage(image)
		awtShowImage(image); Thread.sleep(10000L)
		Unit
	}
}