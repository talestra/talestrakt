import com.soywiz.korio.stream.*
import java.nio.charset.Charset

// FONT is a BIG 2048x512 set of 4 textures
// Each glyph size is 28x28
// Each texture has 36 glyphs per row
// Each texture has 28 glyphs per column
// This file describes each cell: character, yoffset when drawing + xadvance
object FONT_WIDTHS {
	data class Glyph(val index: Int, val slice: SliceSyncStream, val char: Char, val charByte0: Int, val charByte1: Int, val xoffset: Int, val xadvance: Int)

	val SHIFT_JIS = Charset.forName("Shift_JIS")

	// FONT.BIN
	fun read(s: SyncStream): List<Glyph> {
		return (0 until s.readS32_le()).map { index ->
			val offset = s.position
			val charByte0 = s.readU8()
			val charByte1 = s.readU8()
			val xoffset = s.readU8()
			val width = s.readU8()

			val cc = if (charByte1 == 0) {
				charByte0.toChar()
			} else {
				String(byteArrayOf(charByte1.toByte(), charByte0.toByte()), SHIFT_JIS)[0]
			}

			Glyph(index, s.slice(offset until offset + 4), cc, charByte0, charByte1, xoffset, width)
			//println("$char(${char.toChar()}): $yoffset: $width")
		}
	}

	fun writeLines(glyphs: List<Glyph>): List<String> {
		val out = arrayListOf<String>()
		for (glyph in glyphs) out += "%04X,'%c',%d,%d".format()
		return out
	}
}