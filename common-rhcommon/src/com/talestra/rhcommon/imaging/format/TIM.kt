package com.talestra.rhcommon.imaging.format

import com.soywiz.korim.bitmap.Bitmap32
import com.soywiz.korim.bitmap.Bitmap8
import com.soywiz.korim.color.BGRA_5551
import com.soywiz.korim.color.ColorFormat16
import com.soywiz.korim.color.ColorFormatBase
import com.soywiz.korim.format.ImageFormat
import com.soywiz.korim.format.ImageFrame
import com.soywiz.korim.format.ImageInfo
import com.soywiz.korio.stream.SyncStream
import com.soywiz.korio.stream.readBytes
import com.soywiz.korio.stream.readS32_le
import com.soywiz.korio.stream.readU16_le
import com.soywiz.korio.util.UByteArray
import com.soywiz.korio.util.readU16_le

class TIM : ImageFormat() {
	override fun decodeHeader(s: SyncStream, filename: String): ImageInfo? = try {
		val h = readHeader(s)

		ImageInfo().apply {
			this.width = h.width
			this.height = h.height
			this.bitsPerPixel = h.bpp
		}
	} catch (e: Throwable) {
		null
	}

	class Header(
		val bpp: Int,
		val wordsPerRow: Int,
		val height: Int,
		val imgoffset: Int,
		val imgX: Int,
		val imgY: Int,
		val palettes: List<IntArray>
	) {
		val width = when (bpp) {
			4 -> wordsPerRow * 4
			8 -> wordsPerRow * 2
			16 -> wordsPerRow
			else -> throw IllegalArgumentException("Unsupported bpp: $bpp")
		}
	}

	private fun readHeader(s: SyncStream): Header {
		val magic = s.readS32_le()
		val type = s.readS32_le()
		if (magic != 0x10) throw IllegalArgumentException("Not a TIM file")
		val bpp = when (type) {
			0x08 -> 4
			0x09 -> 8
			0x02 -> 16
			0x03 -> 24
			else -> throw IllegalArgumentException("Unsupported type")
		}
		var palettes = listOf<IntArray>()

		if (bpp <= 8) {
			val paloffset = s.readS32_le() // always Size of Clut data + 12
			val palX = s.readU16_le()
			val palY = s.readU16_le()
			val ncol = s.readU16_le()
			val nclut = s.readU16_le()
			palettes = (0 until nclut).map { (0 until ncol).map { BGRA_5551i.toRGBA(s.readU16_le()) }.toIntArray() }
		}

		val imgoffset = s.readS32_le()
		val imgX = s.readU16_le()
		val imgY = s.readU16_le()
		val wordsPerRow = s.readU16_le()
		val height = s.readU16_le()

		return Header(
			bpp = bpp,
			imgX = imgX,
			imgY = imgY,
			height = height,
			wordsPerRow = wordsPerRow,
			imgoffset = imgoffset,
			palettes = palettes
		)
	}

	override fun readFrames(s: SyncStream, filename: String): List<ImageFrame> {
		val h = readHeader(s)
		val bpp = h.bpp


		val data = UByteArray(s.readBytes(h.wordsPerRow * 2 * h.height))
		val bmp = when (bpp) {
			4 -> {
				val out = Bitmap8(h.width, h.height)
				out.palette = h.palettes[0]
				var n = 0
				for (y in 0 until h.height) for (x in 0 until h.width / 2) {
					val b = data[n++]
					out[x * 2 + 0, y] = (b ushr 0) and 0xF
					out[x * 2 + 1, y] = (b ushr 4) and 0xF
				}
				out
			}
			8 -> {
				val out = Bitmap8(h.width, h.height)
				out.palette = h.palettes[0]
				var n = 0
				for (y in 0 until h.height) for (x in 0 until h.width) out[x, y] = data[n++]
				out
			}
			16 -> {
				val out = Bitmap32(h.width, h.height)
				var n = 0
				for (y in 0 until h.height) for (x in 0 until h.width) {
					out[x, y] = BGRA_5551.toRGBA(data.data.readU16_le(n))
					n += 2
				}
				out
			}
			else -> throw IllegalArgumentException("Unsupported bpp: $bpp")
		}

		return listOf(ImageFrame(bmp, targetX = h.imgX, targetY = h.imgY))
	}
}

private val BGRA_5551i_mixin: ColorFormatBase = ColorFormatBase.Mixin(
	bOffset = 0, bSize = 5,
	gOffset = 5, gSize = 5,
	rOffset = 10, rSize = 5,
	aOffset = 15, aSize = 1
)

object BGRA_5551i : ColorFormat16(), ColorFormatBase by BGRA_5551i_mixin {
	override fun getA(v: Int): Int = 0xFF - (BGRA_5551i_mixin.getA(v) and 0xFF)
}