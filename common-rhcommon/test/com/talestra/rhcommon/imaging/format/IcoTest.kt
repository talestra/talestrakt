package com.talestra.rhcommon.imaging.format

import com.soywiz.korim.format.decode
import com.soywiz.korio.async.sync
import com.soywiz.korio.vfs.ResourcesVfs
import org.junit.Test

class IcoTest {
	@Test
	fun name() = sync {
		ICO.decode(ResourcesVfs["icon.ico"])
		Unit
	}
}