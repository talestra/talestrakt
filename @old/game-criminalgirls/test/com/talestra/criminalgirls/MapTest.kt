package com.talestra.criminalgirls

import com.soywiz.korio.async.syncTest
import com.soywiz.korio.async.toList
import com.soywiz.korio.stream.openSync
import com.soywiz.korio.vfs.ResourcesVfs
import org.junit.Assert
import org.junit.Test

class MapTest {
	val resources = ResourcesVfs

	@Test
	fun testTpk(): Unit = syncTest {
		val map = resources["map_d_000_006.tpk"].openAsDsarCidx()
		Assert.assertEquals(
				"[map_d_000_006.tpk.0000]",
				map.listRecursive().toList().map { it.fullname }.toString()
		)
	}

	@Test
	fun testBscr(): Unit = syncTest {
		val bscr = BSCR.read(resources["map_d_000_006.tpk"].openAsDsarCidx()["map_d_000_006.tpk.0000"].read().openSync())
		Assert.assertEquals("map_d_000_006.bms", bscr.name)
	}
}