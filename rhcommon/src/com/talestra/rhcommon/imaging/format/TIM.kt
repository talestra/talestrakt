package com.talestra.rhcommon.imaging.format

import com.soywiz.kimage.bitmap.Bitmap
import com.soywiz.kimage.bitmap.Bitmap32
import com.soywiz.kimage.bitmap.Bitmap8
import com.soywiz.kimage.color.BGRA_5551
import com.soywiz.kimage.format.ImageFormat
import com.soywiz.korio.stream.SyncStream
import com.soywiz.korio.stream.readBytes
import com.soywiz.korio.stream.readS32_le
import com.soywiz.korio.stream.readU16_le
import com.soywiz.korio.util.UByteArray
import com.soywiz.korio.util.readU16_le

object TIM : ImageFormat() {
	override fun read(s: SyncStream): Bitmap {
		val magic = s.readS32_le()
		val type = s.readS32_le()
		if (magic != 0x10) throw IllegalArgumentException("Not a TIM file")
		val bpp = when (type) {
			0x08 -> 4
			0x09 -> 8
			0x02 -> 16
			0x03 -> 24
			else -> throw IllegalArgumentException("Invalid bpp")
		}

		var palettes = listOf<List<Int>>()

		if (bpp <= 8) {
			val paloffset = s.readS32_le() // always Size of Clut data + 12
			val palX = s.readU16_le()
			val palY = s.readU16_le()
			val ncol = s.readU16_le()
			val nclut = s.readU16_le()
			palettes = (0 until nclut).map { (0 until ncol).map { BGRA_5551.toRGBA(s.readU16_le()) } }
		}

		val imgoffset = s.readS32_le()
		val imgX = s.readU16_le()
		val imgY = s.readU16_le()
		val wordsPerRow = s.readU16_le()
		val height = s.readU16_le()
		val data = UByteArray(s.readBytes(wordsPerRow * 2 * height))
		when (bpp) {
			8 -> {
				val width = wordsPerRow * 2
				val out = Bitmap8(width, height)
				out.palette = palettes[0].toIntArray()
				var n = 0
				for (y in 0 until height) for (x in 0 until width) out[x, y] = data[n++]
				return out
			}
			4 -> {
				val width = wordsPerRow * 4
				val out = Bitmap8(width, height)
				out.palette = palettes[0].toIntArray()
				var n = 0
				for (y in 0 until height) for (x in 0 until width / 2) {
					val b = data[n++]
					out[x * 2 + 0, y] = (b ushr 0) and 0xF
					out[x * 2 + 1, y] = (b ushr 4) and 0xF
				}
				return out
			}
			16 -> {
				val width = wordsPerRow
				val out = Bitmap32(width, height)
				var n = 0
				for (y in 0 until height) for (x in 0 until width) {
					out[x, y] = BGRA_5551.toRGBA(data.data.readU16_le(n))
					n += 2
				}
				return out
			}
			else -> {
				throw IllegalArgumentException("Unsupported bpp: $bpp")
			}
		}

		//println(s.available)

		//showImage(out)
		//println(data.toList())

	}
}