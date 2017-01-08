package com.talestra.platform.psp

import com.soywiz.korio.async.sync
import com.soywiz.korio.stream.openAsync
import com.soywiz.korio.stream.readAll
import com.soywiz.korio.vfs.ResourcesVfs
import com.soywiz.korio.vfs.openAsIso
import org.junit.Assert
import org.junit.Test

class CSOTest {
	val resources = ResourcesVfs

	@Test
	fun name() = sync {
		val CUBE_ISO = resources["cube.iso"].read()
		val CUBE_CSO = resources["cube.cso"].read()
		val READED_ISO = CUBE_CSO.openAsync().cso().readAll()

		Assert.assertArrayEquals(READED_ISO, CUBE_ISO)
		val root = CUBE_CSO.openAsync().cso().openAsIso()
		Assert.assertEquals(53150, root["PSP_GAME/SYSDIR/BOOT.BIN"].size())
	}
}