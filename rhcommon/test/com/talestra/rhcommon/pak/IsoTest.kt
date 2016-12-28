package com.talestra.rhcommon.pak

import org.junit.Test

class IsoTest {
	@Test
	fun name() {
		val CUBE_ISO = ClassLoader.getSystemResource("cube.iso").readBytes()
		val root = ISO.read(CUBE_ISO.open2("r"))
		//println(root["PSP_GAME/PARAM.SFO"].open2("r").readAll().toString(Charsets.UTF_8))
		//root.dump()
	}
}