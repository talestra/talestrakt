package com.talestra.talesof.complib

import com.soywiz.korio.async.sync
import com.soywiz.korio.vfs.ResourcesVfs
import org.junit.Assert
import org.junit.Test

class complibtest {
	@Test
	fun name() = sync<Unit> {
		val c = ResourcesVfs["00B2BB72.SLZ.c"].read()
		val u = ResourcesVfs["00B2BB72.SLZ"].read()
		Assert.assertArrayEquals(u, CompTalesOf.decompress(c))
		//CompTalesOf.testDecompressionSpeed(c)
	}

	@Test
	fun testTLZC() = sync<Unit> {
		val c = ResourcesVfs["9F2E0DC0.TOMDLK.c"].read()
		val u = ResourcesVfs["9F2E0DC0.TOMDLK"].read()
		Assert.assertArrayEquals(u, CompTalesOf.decompress(c))
	}
}