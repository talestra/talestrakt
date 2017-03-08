package com.talestra.dividead

import com.soywiz.korio.async.sync
import com.soywiz.korio.async.syncTest
import com.soywiz.korio.vfs.ResourcesVfs
import org.junit.Test

class LzTest {
	@Test
	fun name(): Unit = syncTest {
		LZ.uncompress(ResourcesVfs["B04_0.BMP"].read())
		Unit
	}
}