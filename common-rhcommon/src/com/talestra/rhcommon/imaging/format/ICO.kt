package com.talestra.rhcommon.imaging.format

import com.soywiz.korim.awt.awtShowImage
import com.soywiz.korim.bitmap.Bitmap
import com.soywiz.korim.bitmap.Bitmap32
import com.soywiz.korim.bitmap.Bitmap8
import com.soywiz.korim.color.ColorFormat
import com.soywiz.korim.color.RGBA
import com.soywiz.korim.format.ImageFormat
import com.soywiz.korim.format.ImageInfo
import com.soywiz.korio.stream.*
import com.soywiz.korio.util.extract8
import com.talestra.rhcommon.imaging.Bitmap4

object ICO : ImageFormat() {
	override fun decodeHeader(s: SyncStream): ImageInfo? {
		if (s.readU16_le() != 0) return null
		if (s.readU16_le() != 1) return null
		val count = s.readU16_le()
		if (count >= 1000) return null
		return ImageInfo()
	}

	override fun read(s: SyncStream): Bitmap {
		data class DirEntry(
			val width: Int, val height: Int,
			val colorCount: Int,
			val reserved: Int,
			val planes: Int,
			val bitCount: Int,
			val size: Int,
			val offset: Int
		)

		fun readDirEntry() = DirEntry(
			width = s.readU8(),
			height = s.readU8(),
			colorCount = s.readU8(),
			reserved = s.readU8(),
			planes = s.readU16_le(),
			bitCount = s.readU16_le(),
			size = s.readS32_le(),
			offset = s.readS32_le()
		)

		fun readBitmap(e: DirEntry, s: SyncStream) {
			val headerSize = s.readS32_le()
			val width = s.readS32_le()
			val height = s.readS32_le()
			val planes = s.readS16_le()
			val bitCount = s.readS16_le()
			val compression = s.readS32_le()
			val imageSize = s.readS32_le()
			val pixelsXPerMeter = s.readS32_le()
			val pixelsYPerMeter = s.readS32_le()
			val clrUsed = s.readS32_le()
			val clrImportant = s.readS32_le()
			var palette = IntArray(0)
			if (bitCount <= 8) {
				val colors = if (clrUsed == 0) 1 shl bitCount else clrUsed
				println(planes)
				println(bitCount)
				println(clrUsed)
				println(colors)
				palette = (0 until colors).map {
					val b = s.readU8()
					val g = s.readU8()
					val r = s.readU8()
					val reserved = s.readU8()
					RGBA(r, g, b, 0xFF)
				}.toIntArray()
				println(palette)
			}

			val stride = (e.width * bitCount) / 8
			val data = s.readBytes(stride * e.height)
			val maskData = s.readBytes(e.width * e.height / 8)

			if (bitCount == 4) {
				val bmp = Bitmap4(e.width, e.height, data, palette)
				awtShowImage(bmp.toBMP32().apply { flipY() })
				Thread.sleep(500)
			} else if (bitCount == 8) {
				val bmp = Bitmap8(e.width, e.height, data, palette)
				awtShowImage(bmp.toBMP32().apply { flipY() })
				Thread.sleep(500)
			} else if (bitCount == 32) {
				//val stride = (e.width * bitCount) / 8
				val bmp = Bitmap32(e.width, e.height)
				var n = 0
				for (y in 0 until e.height) {
					for (x in 0 until e.width) {
						val b = data[n++].toInt() and 0xFF
						val g = data[n++].toInt() and 0xFF
						val r = data[n++].toInt() and 0xFF
						val a = data[n++].toInt() and 0xFF
						bmp[x, y] = RGBA(r, g, b, a)
						//println("$x, $y")
					}
				}
				println(s.available)
				awtShowImage(bmp.toBMP32().apply { flipY() })
				Thread.sleep(500)
			} else {
				throw UnsupportedOperationException()
			}
		}

		val reserved = s.readU16_le()
		val type = s.readU16_le()
		val count = s.readU16_le()
		val entries = (0 until count).map { readDirEntry() }
		for (e in entries) {
			println("Entry: $e")
			readBitmap(e, s.sliceWithSize(e.offset.toLong(), e.size.toLong()))
		}
		return Bitmap32(10, 10)
	}
}

object BGRA : ColorFormat() {
	override fun getB(v: Int): Int = v.extract8(0)
	override fun getG(v: Int): Int = v.extract8(8)
	override fun getR(v: Int): Int = v.extract8(16)
	override fun getA(v: Int): Int = v.extract8(24)
}

fun ColorFormat.convertTo(color: Int, target: ColorFormat): Int = target.pack(
	this.getR(color), this.getG(color), this.getB(color), this.getA(color)
)