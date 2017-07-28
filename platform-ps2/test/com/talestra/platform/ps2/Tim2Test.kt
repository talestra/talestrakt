package com.talestra.platform.ps2

import com.soywiz.korim.format.readImageData
import com.soywiz.korim.format.showImageAndWait
import com.soywiz.korio.async.syncTest
import com.soywiz.korio.vfs.ResourcesVfs
import org.junit.Test

class Tim2Test {
	@Test
	fun name(): Unit = syncTest {
		//val frames = ResourcesVfs["PK_ETC.TM2"].readImageFramesNoNative()
		//val frames = ResourcesVfs["_FONTB.TM2"].readImageFramesNoNative()
		//val frames = ResourcesVfs["_S_MENU.TM2"].readImageFramesNoNative()
		//val frames = ResourcesVfs["S_TOA_LOGO.TM2"].readImageFramesNoNative()
		val frames = ResourcesVfs["S_DB_SECRET.TM2"].readImageData().frames
		//for (frame in frames) showImageAndWait(frame.bitmap)
		Unit
	}
}
