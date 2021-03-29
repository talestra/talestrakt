package com.talestra.games.hanabira

import com.soywiz.korim.bitmap.sliceWithSize
import com.soywiz.korim.format.*
import com.soywiz.korio.serialization.binary.*
import com.soywiz.korio.stream.*

class MGD : ImageFormat("mgd") {
	data class Header(
			@Order(0) @Count(4) @Encoding("UTF-8") val magic: String,
			@Order(1) val unk1: Short,
			@Order(2) val unk2: Short,
			@Order(3) val unk3: Int,
			@Order(4) val width: Short,
			@Order(5) val height: Short,
			@Order(6) val unk4: Int,
			@Order(7) val pngSize: Int
	) : Struct

	override fun decodeHeader(s: SyncStream, filename: String): ImageInfo? {
		val header = s.readStruct<Header>()
		if (header.magic != "MGD ") return null
		return ImageInfo().apply {
			width = header.width.toInt()
			height = header.height.toInt()
			bitsPerPixel = 32
		}
	}

	override fun readImage(s: SyncStream, filename: String): ImageData {
		val header = s.readStruct<Header>()
		val content = s.sliceWithSize(0x60, header.pngSize.toLong() - 4)
		val end = s.sliceWithStart(((0x60 + header.pngSize).toLong()))
		val ends = end.readSlice(end.readS32_le().toLong())
		val count = ends.readU16_le()
		val bytesPerPixel = ends.readU16_le()
		val atlas = ImageFormats.decode(content)
		val frames = arrayListOf<ImageFrame>()
		for (n in 0 until count) {
			val x = ends.readU16_le()
			val y = ends.readU16_le()
			val width = ends.readU16_le()
			val height = ends.readU16_le()
			//println("$x,$y,$width,$height")
			val chunk = atlas.sliceWithSize(x, y, width, height)
			frames += ImageFrame(chunk.extract())
			//println(chunk)
		}
		return ImageData(frames)
	}
}