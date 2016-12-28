package com.talestra.rhcommon.pak

import com.soywiz.korio.async.sync
import com.soywiz.korio.vfs.ResourcesVfs
import com.soywiz.korio.vfs.openAsIso
import org.junit.Test

class IsoTest {
	@Test
	fun name() = sync {
		val resources = ResourcesVfs()
		val root = resources["cube.iso"].openAsIso()
		//println(root["PSP_GAME/PARAM.SFO"].open2("r").readAll().toString(Charsets.UTF_8))
		//root.dump()
	}
}