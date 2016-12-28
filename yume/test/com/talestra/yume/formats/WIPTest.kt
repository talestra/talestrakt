package com.talestra.yume.formats

import WIP
import org.junit.Assert.assertArrayEquals
import org.junit.Test

class WIPTest {
	@Test
	fun name() {
		val images = WIP.read(getResourceBytes("BG_IMG13.WIP").open2("r"))
		val recompressed = WIP.write(images)
		val images2 = WIP.read(recompressed.open2("r"))
		assertArrayEquals(
			(images[0].bitmap as Bitmap32).data,
			(images2[0].bitmap as Bitmap32).data
		)
	}
}