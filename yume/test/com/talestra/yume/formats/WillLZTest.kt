package com.talestra.yume.formats

import org.junit.Assert.assertArrayEquals
import org.junit.Test

class WillLZTest {
	@Test
	fun name() {
		val originalData = "Hello World! World! World!".toByteArray()
		val compressedData = WillLZ.compress(originalData)
		val decompressedData = WillLZ.decompress(compressedData, ByteArray(originalData.size))
		assertArrayEquals(decompressedData, originalData)
	}
}