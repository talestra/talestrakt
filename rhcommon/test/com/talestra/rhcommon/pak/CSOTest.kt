package com.talestra.rhcommon.pak

import com.soywiz.korio.stream.openSync
import com.soywiz.korio.stream.readAll
import com.soywiz.korio.vfs.ISO
import com.talestra.rhcommon.compression.CSO
import org.junit.Assert
import org.junit.Test

class CSOTest {
	@Test
	fun name() {
		val CUBE_ISO = ClassLoader.getSystemResource("cube.iso").readBytes()
		val CUBE_CSO = ClassLoader.getSystemResource("cube.cso").readBytes()
		val READED_ISO = CSO.read(CUBE_CSO.openSync("r")).readAll()

		Assert.assertArrayEquals(READED_ISO, CUBE_ISO)
		val root = ISO.read(CSO.read(CUBE_CSO.openSync("r")))
		Assert.assertEquals(53150, root["PSP_GAME/SYSDIR/BOOT.BIN"].size)
	}
}