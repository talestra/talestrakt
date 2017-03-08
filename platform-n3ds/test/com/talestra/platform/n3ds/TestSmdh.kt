package com.talestra.platform.n3ds

import com.soywiz.korim.bitmap.Bitmap32
import com.soywiz.korim.format.readBitmap
import com.soywiz.korio.async.sync
import com.soywiz.korio.async.syncTest
import com.soywiz.korio.vfs.ResourcesVfs
import org.junit.Assert
import org.junit.Test

class TestSmdh {
	val resources = ResourcesVfs["com/talestra/platform/n3ds"]
	@Test
	fun name() = syncTest {
		val smdh = N3dsSMDH.read(resources["test.smdh"].readAsSyncStream())
		val smallRef = resources["small.png"].readBitmap()
		val largeRef = resources["large.png"].readBitmap()
		Assert.assertTrue(Bitmap32.matches(smdh.icons.small, smallRef))
		Assert.assertTrue(Bitmap32.matches(smdh.icons.large, largeRef))
		Unit
	}
}