package com.talestra.platform.ps2

import com.soywiz.korim.bitmap.Bitmap32
import com.soywiz.korim.bitmap.Bitmap4
import com.soywiz.korim.bitmap.Bitmap8
import com.soywiz.korim.color.RGB
import com.soywiz.korim.color.RGBA
import com.soywiz.korim.format.ImageFormat
import com.soywiz.korim.format.ImageFrame
import com.soywiz.korim.format.ImageInfo
import com.soywiz.korio.stream.*
import java.io.IOException

class TIM2 : ImageFormat() {
	class Header(
		val formatVersion: Int,
		val formatId: Int,
		val numberOfPictures: Int
	)

	data class EntryHeader(
		val totalSize: Int, // Total size of the picture data in bytes
		val clutSize: Int, // CLUT data size in bytes
		val imageSize: Int, // Image data size in bytes
		val headerSize: Short, // Header size in bytes
		val clutColors: Short, // Total color number in CLUT data
		val pictFormat: Byte, // ID of the picture format (must be 0)
		val mipMapTexs: Byte, // Number of MIPMAP texture
		val clutType: Byte, // Type of the CLUT data
		val imageType: Byte, // Type of the Image data
		val imageWidth: Short, // Width of the picture
		val imageHeight: Short, // Height of the picture
		val gsTex0: Long, // Data for GS TEX0 register
		val gsTex1: Long, // Data for GS TEX1 register
		val gsRegs: Int, // Data for GS TEXA, FBA, PABE register
		val gsTexClut: Int    // Data for GS TEXCLUT register
	) {
		val width = imageWidth.toInt()
		val height = imageHeight.toInt()
		val colorFormat = when (clutType) {
			ClutType.RGB -> RGB
			ClutType.RGBA -> RGBA
			else -> throw UnsupportedOperationException("clutType: $clutType")
		}
		val bpp = when (imageType) {
			ImageType.BPP32 -> 32
			ImageType.BPP8 -> 8
			ImageType.BPP4 -> 4
			else -> throw UnsupportedOperationException("imageType: $imageType")
		}

		companion object {
			fun read(s: SyncStream): EntryHeader = s.run {
				val s2 = s.sliceWithStart(s.position)

				EntryHeader(
					totalSize = s2.readS32_le(),
					clutSize = s2.readS32_le(),
					imageSize = s2.readS32_le(),
					headerSize = s2.readS16_le().toShort(),
					clutColors = s2.readS16_le().toShort(),
					pictFormat = s2.readS8().toByte(),
					mipMapTexs = s2.readS8().toByte(),
					clutType = s2.readS8().toByte(),
					imageType = s2.readS8().toByte(),
					imageWidth = s2.readS16_le().toShort(),
					imageHeight = s2.readS16_le().toShort(),
					gsTex0 = s2.readS64_le(),
					gsTex1 = s2.readS64_le(),
					gsRegs = s2.readS32_le(),
					gsTexClut = s2.readS32_le()
				).apply {
					s.position += this.headerSize
				}
			}
		}
	}

	object ClutType {
		val RGB = 2.toByte()
		val RGBA = 3.toByte()
	}

	object ImageType {
		val BPP32 = 3.toByte()
		val BPP4 = 4.toByte()
		val BPP8 = 5.toByte()
	}

	fun readHeader(s: SyncStream): Header {
		if (s.readStringz(4) != "TIM2") throw IOException("Not a TIM2 filee")
		val formatVersion = s.readU8()
		val formatId = s.readU8()
		val pictures = s.readU16_le()
		val padding = s.readS64_le()

		return Header(
			formatVersion = formatVersion,
			formatId = formatId,
			numberOfPictures = pictures
		)
	}

	override fun decodeHeader(s: SyncStream, filename: String): ImageInfo? = try {
		val h = readHeader(s)
		for (entry in 0 until h.numberOfPictures) {
			val eh = EntryHeader.read(s)
			s.position += eh.clutSize + eh.imageSize
		}
		ImageInfo().apply {
			width = 0
			height = 0
		}
	} catch (e: Throwable) {
		null
	}

	override fun readFrames(s: SyncStream, filename: String): List<ImageFrame> {
		val h = readHeader(s)
		val out = arrayListOf<ImageFrame>()
		for (entry in 0 until h.numberOfPictures) {
			val eh = EntryHeader.read(s)
			val data = s.readBytes(eh.imageSize)
			val clut = s.readBytes(eh.clutSize)
			val palette = if (eh.clutColors > 0) {
				eh.colorFormat.decode(clut)
			} else {
				IntArray(0)
			}
			val bmp = when (eh.bpp) {
				4 -> Bitmap4(eh.width, eh.height, data = data, palette = palette)
				8 -> Bitmap8(eh.width, eh.height, data = data, palette = palette)
				32 -> Bitmap32(eh.width, eh.height).writeDecoded(RGBA, data)
				else -> throw UnsupportedOperationException()
			}
			out += ImageFrame(bmp)
			//println(eh)
		}
		return out
	}
}