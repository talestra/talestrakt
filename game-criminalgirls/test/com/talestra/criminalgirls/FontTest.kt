package com.talestra.criminalgirls

import com.soywiz.korio.async.sync
import com.soywiz.korio.vfs.ResourcesVfs
import org.junit.Assert
import org.junit.Test

class FontTest {
	val resources = ResourcesVfs
	@Test
	fun name(): Unit = sync {
		val glyphs = FONT_WIDTHS.read(resources["font.bin"].readAsSyncStream())
		Assert.assertEquals(2853, glyphs.size)
		Assert.assertEquals("Glyph(index=0, slice=SliceSyncStream(MemorySyncStream(11416), 4, 8), char= , charByte0=32, charByte1=0, xoffset=0, xadvance=12)", glyphs[0].toString())
		Unit
	}
}