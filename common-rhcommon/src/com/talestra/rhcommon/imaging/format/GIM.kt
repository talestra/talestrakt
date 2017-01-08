package com.talestra.rhcommon.imaging.format

import com.soywiz.korim.bitmap.Bitmap
import com.soywiz.korim.bitmap.Bitmap32
import com.soywiz.korim.bitmap.Bitmap8
import com.soywiz.korim.color.RGBA
import com.soywiz.korim.format.ImageFormat
import com.soywiz.korim.format.ImageFrame
import com.soywiz.korim.format.ImageInfo
import com.soywiz.korio.stream.*
import com.soywiz.korio.util.UByteArray

// https://github.com/soywiz/dutils/blob/master/si/si_gim.d
class GIM : ImageFormat() {
	override fun decodeHeader(s: SyncStream, filename: String): ImageInfo? {
		val magic = s.readStringz(0x10)
		if (magic != "MIG.00.1PSP") return null
		val h = Reader().readHeader(s)
		return ImageInfo().apply {
			this.width = h.width
			this.height = h.height
			this.bitsPerPixel = h.bpp
		}
	}

	override fun readFrames(s: SyncStream, filename: String): List<ImageFrame> {
		val magic = s.readStringz(0x10)
		if (magic != "MIG.00.1PSP") throw IllegalArgumentException("Not a GIM file")
		return listOf(ImageFrame(Reader().readBitmap(s)))
	}

	enum class ChunkType(val id: Int) {
		GimContainer(0x02),
		Image(0x03),
		ImagePixels(0x04),
		ImagePalette(0x05),
		Comments(0xFF);

		companion object {
			val BY_ID = values().associateBy { it.id }
		}
	}

	data class Header(
		val _u1: Int,
		val type: Int,
		val _u2: Int,
		val width: Int,
		val height: Int,
		val bpp: Int,
		var xbs: Int,
		val ybs: Int,
		val _u5: Unit
	) {
		companion object {
			operator fun invoke(s: SyncStream): Header = Header(
				_u1 = s.readS32_le(),
				type = s.readS16_le(),
				_u2 = s.readS16_le(),
				width = s.readS16_le(),
				height = s.readS16_le(),
				bpp = s.readS16_le(),
				xbs = s.readS16_le(),
				ybs = s.readS16_le(),
				_u5 = Unit.apply { s.readBytes(0x17 * 2) }
			)
		}
	}

	class Reader() {
		lateinit var header: Header
		val palette = Bitmap32(256, 1)
		var img: Bitmap = Bitmap32(1, 1)
		var comments = ""

		fun readBitmap(s: SyncStream): Bitmap {
			readChunks(s, 0, 0)
			return img
		}

		fun readHeader(s: SyncStream): Header {
			readChunks(s, 0, 1)
			return header
		}

		fun readChunks(s: SyncStream, level: Int, mode: Int) {
			while (!s.eof) {
				val type = ChunkType.BY_ID[s.readS16_le()]
				val unk0 = s.readS16_le()
				val len = s.readS32_le()
				val unk1 = s.readS32_le()
				val unk2 = s.readS32_le()
				val data = s.readStream((len - 0x10).toLong())

				//println(type)

				when (type) {
					ChunkType.GimContainer, ChunkType.Image -> {
						readChunks(data, level + 1, mode)
					}
					ChunkType.ImagePixels, ChunkType.ImagePalette -> {
						val header = Header(data)
						this.header = header

						if (mode == 1) return

						val block = UByteArray(header.xbs * header.ybs * header.bpp / 8)
						val img32 = Bitmap32(header.width, header.height)
						val img8 = Bitmap8(header.width, header.height)
						val img = if (header.bpp <= 8) img8 else img32

						//header.xbs = when (header.type) {
						//	0x00 -> 8
						//	0x03 -> 4
						//	0x05 -> 16
						//	0x04 -> 32
						//	else -> invalidOp("Can't fix xbs")
						//}

						//println(data.available)

						for (by in 0 until header.height / header.ybs) {
							for (bx in 0 until header.width / header.xbs) {
								val addx = bx * header.xbs
								val addy = by * header.ybs
								var n = 0
								data.read(block)
								for (y in 0 until header.ybs) {
									for (x in 0 until header.xbs) {
										when (header.bpp) {
											8 -> {
												img8[addx + x, addy + y] = block[n++]
											}
											32 -> {
												val r = block[n++]
												val g = block[n++]
												val b = block[n++]
												val a = block[n++]
												img32[addx + x, addy + y] = RGBA(r, g, b, a)
											}
											else -> TODO("Unsupported bpp: ${header.bpp}")
										}
									}
								}
							}
						}

						if (type == ChunkType.ImagePalette) {
							palette.put(img32.toBMP32())
						} else {
							if (img == img8) img8.palette = palette.data
							this.img = img
						}
					}
					ChunkType.Comments -> {
						this.comments = data.readAll().toString(Charsets.UTF_8)
					}
					else -> TODO("Not implemented chunk $type")
				}
			}
		}
	}
}