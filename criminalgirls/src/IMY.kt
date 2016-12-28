import com.jtransc.JTranscArrays
import com.soywiz.kimage.format.ImageFormat

object IMY : ImageFormat() {
	fun getEqualsSize(a: ShortArray, an: Int, b: ShortArray, bn: Int, maxLen: Int): Int {
		for (n in 0 until maxLen) {
			if (a[an + n] != b[bn + n]) {
				return n
			}
		}
		return maxLen
	}

	open class Compressor {
		fun compress(dataToEncode: ShortArray, width: Int) {
			val pitch = width / 2
			var n = 0
			val table = IntArray(0x10000) { -1 }
			//val offsets = intArrayOf(-1, -width / 2, -width / 2 + 1, -width / 2 - 1)
			val offsets = intArrayOf(-1, -pitch, -pitch - 1, -pitch + 1)
			val sizes = intArrayOf(0, 0, 0, 0)
			var datan = 0

			main@ while (n < dataToEncode.size) {
				val vv = dataToEncode[n].toInt() and 0xFFFF

				if (n >= 1) {
					// LZ/RLE
					var maxsize = -1
					var maxkind = 0
					for (kind in offsets.indices) {
						val offset = offsets[kind]
						if (n + offset < 0) continue
						val size = getEqualsSize(dataToEncode, n, dataToEncode, n + offset, Math.min(0x10, dataToEncode.size - n))
						if (size > maxsize) {
							maxsize = size
							maxkind = kind
						}
					}

					//println("maxsize:$maxsize")
					if (maxsize > 0) {
						emitCompressedLZ(maxkind, maxsize)
						n += maxsize
						continue@main
					}

					val lastPos = table[vv]
					val offset = lastPos - datan
					if ((lastPos >= 0) && (offset > -(0xC0 - 0x10)) && (offset < 0)) {
						emitRecall(offset)
						n++
						continue@main
					}
				}

				emitUncompressed(vv)
				table[vv] = datan
				n++
				datan++
			}
		}

		open fun emitUncompressed(vv: Int) {

		}

		open fun emitCompressedLZ(kind: Int, size: Int) {
		}

		open fun emitRecall(offset: Int) {
		}
	}

	override fun write(bitmap: Bitmap, s: Stream2) {
		val bpp = if (bitmap is Bitmap8) 1 else 2
		val bitsPerPixel = bpp * 8
		val hasPalette = if (bitmap is Bitmap8) true else false
		val paletteSize = (if (hasPalette) 0x100 else 0)
		val uncompressedSize = 0x20 + (4 * paletteSize) + (bitmap.area)
		val width = bitmap.width
		val height = bitmap.height
		val swizzled = width.isPowerOfTwo() && height.isPowerOfTwo()
		val intPack = false

		val flags = 0x8C or (intPack.toInt() shl 1) or (swizzled.toInt() shl 5) // Usually AC for swizzled - ShortPacking
		val format = if (hasPalette) 0x08 else 0x0C
		s.writeStringz("IMY", 4)
		s.writeU32_le(uncompressedSize)
		s.writeU16_le(width)
		s.writeU8(flags)
		s.writeU8(format)
		s.writeU16_le(height)
		s.writeU16_le(paletteSize)
		s.writeBytes(ByteArray(0x10))
		if (bitmap is Bitmap8) {
			s.writeBytes(JTranscArrays.copyReinterpret(bitmap.palette))
		}
		val dataToEncode: ShortArray = when (bitmap) {
			is Bitmap8 -> {
				JTranscArrays.copyReinterpretShort_LE(if (swizzled) {
					PostProcessing.CombinedUnswizzleTexture(bitmap.data, width, height, swizzle = true)
				} else {
					bitmap.data
				})
			}
			is Bitmap32 -> {
				val data = ShortArray(bitmap.area)
				for (n in 0 until bitmap.area) {
					val v = bitmap.data[n]
					val r = RGBA.getR(v)
					val g = RGBA.getG(v)
					val b = RGBA.getB(v)
					val a = RGBA.getA(v)
					data[n] = RGBA_4444.pack(b, g, r, a).toShort()
				}
				if (swizzled) {
					PostProcessing.CombinedUnswizzleTexture(data, width, height, swizzle = true)
				} else {
					data
				}
			}
			else -> invalidOp("Unsupported $bitmap")
		}

		val codes = MemoryStream2()
		val data = MemoryStream2()

		object : Compressor() {
			var uncompressedCount = 0
			var codeCount = 0

			fun flushUncompressed() {
				if (uncompressedCount > 0) {
					//println("UNCOMPRESSED:${uncompressedCount}")
					codes.writeU8(uncompressedCount - 1)
					codeCount++
					uncompressedCount = 0
				}
			}

			override fun emitUncompressed(vv: Int) {
				data.writeU16_le(vv)
				uncompressedCount++
				if (uncompressedCount >= 0x10) {
					flushUncompressed()
				}
			}

			override fun emitCompressedLZ(kind: Int, size: Int) {
				flushUncompressed()
				//println("LZ:$kind,$size")
				codes.writeU8(0xC0 or (kind shl 4) or (size - 1))
				codeCount++
			}

			override fun emitRecall(offset: Int) {
				if (offset >= 0) invalidOp("Offset must be negative")
				if (offset < -(0xC0 - 0x10 - 1)) invalidOp("Offset too small")
				flushUncompressed()
				//println("RECALL:$offset")
				codes.writeU8(0x10 + -offset - 1)
				codeCount++
			}
		}.compress(dataToEncode, width)

		codes.writeToAlign(2, 0x00)

		val codesData = codes.toByteArray()
		val dataData = data.toByteArray()
		if (codesData.size == codesData.size.toChar().toInt()) {
			s.writeU16_le(codesData.size)
		} else {
			s.writeU16_le(0)
			s.writeU32_le(codesData.size)
		}
		s.writeBytes(codesData)
		s.writeBytes(dataData)
		s.writeToAlign(4, 0x00)
	}

	// This includes a compression algorithm? Must disasm executable to find out (font_xx.imy have different sizes)
	// Already found at 0x810E3DAC
	override fun read(s: Stream2): Bitmap {
		if (s.readStringz(4) != "IMY") invalidOp("Not an IMY file")
		val uncompressedSize = s.readS32_le()
		val width = s.readU16_le()
		val flags = s.readU8()
		val format = s.readU8()
		val height = s.readS16_le()
		val paletteSize = s.readS16_le()
		val uncompressedArea = width * height
		s.readBytes(0x10)

		//val expectedUncompressedSizeForPalette = 0x20 + 0x100 * 4 + uncompressedArea
		//val expectedUncompressedSizeForRGBA = 0x20 + uncompressedArea * 4

		val palette = s.readIntArray_le(paletteSize)

		val wordSize = ((flags ushr 1) and 0x1) != 0
		val swizzle = ((flags ushr 5) and 0x1) != 0

		//println(wordSize)

		val actualWidth = width

		val outBytes = if (wordSize) {
			uncompressInts(actualWidth, height, s)
		} else {
			uncompressShorts(actualWidth, height, s)
		}

		if (paletteSize != 0) {
			val outBytes2 = if (swizzle) {
				PostProcessing.UnswizzleTexture(outBytes, actualWidth, height, 8)
			} else {
				outBytes
			}

			val bmp = Bitmap8(actualWidth, height, ByteArray(actualWidth * height), palette)
			//val bmp = Bitmap8(256, height, ByteArray(realWidth * height * 2), palette)
			var m = 0
			var n = 0

			for (y in 0 until height) {
				for (x in 0 until actualWidth) {
					bmp.data[m++] = outBytes2[n]
					//bmp.data[m++] = ((out[n].toInt() ushr 0) and 0xFF).toByte()
					//bmp.data[m++] = ((out[n].toInt() ushr 8) and 0xFF).toByte()
					n++
				}
			}
			return bmp
		} else {
			val outBytes2 = if (swizzle) {
				//PostProcessing.UnswizzleTexture(outBytes.sliceArray(actualWidth * height * 2 until outBytes.size) + outBytes.sliceArray(0 until actualWidth * height * 2), actualWidth, height, 16)
				PostProcessing.UnswizzleTexture(outBytes, actualWidth, height, 16)
			} else {
				outBytes
			}


			val out2 = Bitmap32(actualWidth, height)

			// RGBA4444
			var n = 0
			var m = 0
			for (y in 0 until height) {
				for (x in 0 until actualWidth) {
					val vl = outBytes2[n++].toInt() and 0xFF
					val vh = outBytes2[n++].toInt() and 0xFF
					val vv = vl or (vh shl 8)
					out2.data[m++] = RGBA.pack(RGBA_4444.getR(vv), RGBA_4444.getG(vv), RGBA_4444.getB(vv), RGBA_4444.getA(vv))
				}
			}
			return out2
		}
	}

	fun uncompressShorts(actualWidth: Int, height: Int, s: Stream2): ByteArray {
		var codeSize = s.readU16_le()
		if (codeSize == 0) codeSize = s.readS32_le()

		val codes = s.readBytes(codeSize)
		val data = s.readShortArray_le(s.available.toInt() / 2)
		val out = ShortArray(actualWidth * height)

		var cp = 0
		var dp = 0
		var op = 0

		//val actualWidth = if (paletteSize == 0) pitch else pitch / 2
		val n = actualWidth / 2

		val offsets = intArrayOf(1, n, n + 1, n - 1)
		//var nn = 0
		while (cp < codes.size) {
			val code = codes.getu(cp++)
			if (code < 0x10) {
				val size = (code + 1)
				if (dp + size < data.size) {
					System.arraycopy(data, dp, out, op, size)
				}
				dp += size
				op += size
				if (op >= out.size) break
			} else if (code < 0xC0) {
				val v = code - 0x10
				out[op] = data[dp - v - 1]
				op++
				if (op >= out.size) break
			} else {
				// LZ
				val offset = offsets[((code ushr 4) and 0x3)]
				val size = (((code ushr 0) and 0xF) + 1)

				//println("OFFSET: {nn++} : {((code ushr 4) and 0x3)} : {op} : offset : width")

				for (n in 0 until size) {
					out[op] = out[op - offset]
					op++
				}
				if (op >= out.size) break
			}
		}

		//println("CP=cp : TOTAL={codes.size}")
		//println("DP=dp : DATA_SIZE={data.size}")
		//println("OP=op : OP_SIZE={out.size}")

		return JTranscArrays.copyReinterpret(out)
	}

	fun uncompressInts(actualWidth: Int, height: Int, s: Stream2): ByteArray {
		var codeSize = s.readU16_le()
		if (codeSize == 0) codeSize = s.readS32_le()

		val codes = s.readBytes(codeSize)
		val data = s.readIntArray_le(s.available.toInt() / 4)
		val out = IntArray(actualWidth * height)

		var cp = 0
		var dp = 0
		var op = 0

		//val actualWidth = if (paletteSize == 0) pitch else pitch / 2
		val n = actualWidth / 4

		val offsets = intArrayOf(1, n, n + 1, n - 1)
		//var nn = 0
		while (cp < codes.size) {
			val code = codes.getu(cp++)
			if (code < 0x10) {
				val size = (code + 1)
				if (dp + size < data.size) {
					System.arraycopy(data, dp, out, op, size)
				}
				dp += size
				op += size
			} else if (code < 0xC0) {
				val v = code - 0x10
				out[op] = data[dp - v - 1]
				op++
			} else {
				// LZ
				val offset = offsets[((code ushr 4) and 0x3)]
				val size = (((code ushr 0) and 0xF) + 1)

				//println("OFFSET: {nn++} : {((code ushr 4) and 0x3)} : {op} : offset : width")

				for (n in 0 until size) {
					out[op] = out[op - offset]
					op++
				}
			}
		}

		//println("CP=cp : TOTAL={codes.size}")
		//println("DP=dp : DATA_SIZE={data.size}")
		//println("OP=op : OP_SIZE={out.size}")

		return JTranscArrays.copyReinterpret(out)
	}

	//fun unswizzle(bmp: Bitmap32): Bitmap32 {

	//}

	fun unswizzleInline(rowWidth: Int, from: ByteArray, width: Int, height: Int) {
		val textureHeight = height;
		val size = from.size
		val temp = ByteArray(size);
		unswizzle(from, temp, rowWidth, textureHeight);
		System.arraycopy(temp, 0, from, 0, size)
	}

	fun unswizzle(input: ByteArray, output: ByteArray, rowWidth: Int, textureHeight: Int) {
		val pitch = ((rowWidth - 16) / 4);
		val bxc = (rowWidth / 16);
		val byc = (textureHeight / 8);
		val pitch4 = (pitch * 4);
		var src = 0;
		var ydest = 0;
		for (by in 0 until byc) {
			var xdest = ydest;
			for (bx in 0 until bxc) {
				var dest = xdest;
				for (n in 0 until 8) {
					for (m in 0 until 16) output[dest++] = input[src++];
					dest += pitch4
				}
				xdest += 16;
			}
			ydest += rowWidth * 8;
		}
	};
}

// https://github.com/xdanieldzd/GXTConvert
// http://www.forceflow.be/2013/10/07/morton-encodingdecoding-through-bit-interleaving-implementations/
// Fixed for rectangular POT textures + Optimizations: https://github.com/xdanieldzd/GXTConvert/issues/5

object PostProcessing {
	// Unswizzle logic by @FireyFly
	// http://xen.firefly.nu/up/rearrange.c.html

	val tileOrder = intArrayOf(
		0, 1, 8, 9,
		2, 3, 10, 11,
		16, 17, 24, 25,
		18, 19, 26, 27,

		4, 5, 12, 13,
		6, 7, 14, 15,
		20, 21, 28, 29,
		22, 23, 30, 31,

		32, 33, 40, 41,
		34, 35, 42, 43,
		48, 49, 56, 57,
		50, 51, 58, 59,

		36, 37, 44, 45,
		38, 39, 46, 47,
		52, 53, 60, 61,
		54, 55, 62, 63
	)

	private fun GetTilePixelIndex(t: Int, x: Int, y: Int, width: Int): Int {
		return ((((tileOrder[t] / 8) + y) * width) + ((tileOrder[t] % 8) + x)).toInt();
	}

	private fun GetTilePixelOffset(t: Int, x: Int, y: Int, width: Int, pixelFormatSize: Int): Int {
		return (GetTilePixelIndex(t, x, y, width) * (pixelFormatSize / 8));
	}

	public fun UntileTexture(pixelData: ByteArray, width: Int, height: Int, pixelFormatSize: Int): ByteArray {
		val untiled = ByteArray(pixelData.size)

		var s = 0;
		var y = 0
		while (y < height) {
			var x = 0
			while (x < width) {

				for (t in 0 until 8 * 8) {
					val pixelOffset = GetTilePixelOffset(t, x, y, width, pixelFormatSize);
					System.arraycopy(pixelData, s, untiled, pixelOffset, 4)
					s += 4;
				}
				x += 8
			}
			y += 8
		}

		return untiled;
	}

	// Unswizzle (Morton)

	private fun Compact1By1(xx: Int): Int {
		var x = xx and 0x55555555;                 // x = -f-e -d-c -b-a -9-8 -7-6 -5-4 -3-2 -1-0
		x = (x xor (x ushr 1)) and 0x33333333; // x = --fe --dc --ba --98 --76 --54 --32 --10
		x = (x xor (x ushr 2)) and 0x0f0f0f0f; // x = ---- fedc ---- ba98 ---- 7654 ---- 3210
		x = (x xor (x ushr 4)) and 0x00ff00ff; // x = ---- ---- fedc ba98 ---- ---- 7654 3210
		x = (x xor (x ushr 8)) and 0x0000ffff; // x = ---- ---- ---- ---- fedc ba98 7654 3210
		return x;
	}

	private fun DecodeMorton2X(code: Int): Int {
		return Compact1By1(code ushr 0);
	}

	private fun DecodeMorton2Y(code: Int): Int {
		return Compact1By1(code ushr 1);
	}

	private fun DecodeMorton2Z(code: Int): Int {
		return Compact1By1(code ushr 2);
	}

	fun getIndex(i: Int, width: Int, height: Int, k: Int, k2: Int, minMask: Int, maxMask: Int): Int {
		val base = i ushr (2 * k) shl (2 * k)
		//val base = 0
		//println(base)
		return if (height < width) {
			// XXXyxyxyx → XXXxxxyyy
			base or
				((DecodeMorton2Y(i) and minMask) shl k) or
				((DecodeMorton2X(i) and minMask) shl 0) or
				(((DecodeMorton2X(i)) ushr k) shl (k * 2))
		} else {
			// YYYyxyxyx → YYYyyyxxx
			base or
				((DecodeMorton2X(i) and minMask) shl k) or
				((DecodeMorton2Y(i) and minMask) shl 0) or
				(((DecodeMorton2Y(i)) ushr k) shl (k * 2))
		}
	}

	public fun UnswizzleTexture(pixelData: ByteArray, width: Int, height: Int, pixelFormatSize: Int): ByteArray {
		val bytesPerPixel = (pixelFormatSize / 8);
		val unswizzled = ByteArray(pixelData.size)

		val min = if (width < height) width else height;
		val k = (Math.log(min.toDouble()) / Math.log(2.0)).toInt()
		val k2 = k * 2
		val minMask = min - 1

		if (height < width) {
			// XXXyxyxyx → XXXxxxyyy
			for (i in 0 until width * height) {
				val mx = DecodeMorton2X(i)
				val my = DecodeMorton2Y(i)
				val j = (i ushr (2 * k) shl (2 * k)) or
					((my and minMask) shl k) or
					((mx and minMask) shl 0) or
					((mx ushr k) shl k2)
				val x = j ushr k
				val y = j and minMask
				System.arraycopy(pixelData, i * bytesPerPixel, unswizzled, ((y * width) + x) * bytesPerPixel, bytesPerPixel)
			}
		} else {
			// YYYyxyxyx → YYYyyyxxx
			for (i in 0 until width * height) {
				val mx = DecodeMorton2X(i)
				val my = DecodeMorton2Y(i)
				// YYYyxyxyx → YYYyyyxxx
				val j = (i ushr (2 * k) shl (2 * k)) or
					((mx and minMask) shl k) or
					((my and minMask) shl 0) or
					((my ushr k) shl k2)
				val x = j and minMask
				val y = j ushr k
				System.arraycopy(pixelData, i * bytesPerPixel, unswizzled, ((y * width) + x) * bytesPerPixel, bytesPerPixel)
			}
		}

		return unswizzled;
	}

	fun packJ(i: Int, mlow: Int, mhigh: Int, k: Int, k2: Int, minMask: Int, width: Int, height: Int): Int {
		return (i ushr (2 * k) shl (2 * k)) or
			((mhigh and minMask) shl k) or
			((mlow and minMask) shl 0) or
			((mlow ushr k) shl k2)
	}

	interface MyPack {
		fun pack(i: Int, mx: Int, my: Int, k: Int, k2: Int, minMask: Int, width: Int, height: Int): Int {
			val j = packJ(i, mx, my, k, k2, minMask, width, height)
			val x = j ushr k
			val y = j and minMask
			return y * width + x
		}
	}

	val packJH = object : MyPack {
		override fun pack(i: Int, mx: Int, my: Int, k: Int, k2: Int, minMask: Int, width: Int, height: Int): Int {
			// XXXyxyxyx → XXXxxxyyy
			val j = packJ(i, mx, my, k, k2, minMask, width, height)
			val x = j ushr k
			val y = j and minMask
			return y * width + x
		}
	}

	val packJV = object : MyPack {
		override fun pack(i: Int, mx: Int, my: Int, k: Int, k2: Int, minMask: Int, width: Int, height: Int): Int {
			// YYYyxyxyx → YYYyyyxxx
			val j = packJ(i, my, mx, k, k2, minMask, width, height)
			val x = j and minMask
			val y = j ushr k
			return y * width + x
		}
	}

	fun CombinedUnswizzleTexture(inp: ByteArray, width: Int, height: Int, swizzle: Boolean): ByteArray {
		val out = ByteArray(inp.size)

		val min = if (width < height) width else height;
		val k = (Math.log(min.toDouble()) / Math.log(2.0)).toInt()
		val k2 = k * 2
		val minMask = min - 1

		val packer = if (height < width) packJH else packJV

		if (swizzle) {
			for (i in 0 until width * height) {
				val j = packer.pack(i, DecodeMorton2X(i), DecodeMorton2Y(i), k, k2, minMask, width, height)
				out[i] = inp[j]
			}
		} else {
			for (i in 0 until width * height) {
				val j = packer.pack(i, DecodeMorton2X(i), DecodeMorton2Y(i), k, k2, minMask, width, height)
				out[j] = inp[i]
			}
		}

		return out;
	}

	fun CombinedUnswizzleTexture(inp: ShortArray, width: Int, height: Int, swizzle: Boolean): ShortArray {
		val out = ShortArray(inp.size)

		val min = if (width < height) width else height;
		val k = (Math.log(min.toDouble()) / Math.log(2.0)).toInt()
		val k2 = k * 2
		val minMask = min - 1

		val packer = if (height < width) packJH else packJV

		if (swizzle) {
			for (i in 0 until width * height) {
				val j = packer.pack(i, DecodeMorton2X(i), DecodeMorton2Y(i), k, k2, minMask, width, height)
				out[i] = inp[j]
			}
		} else {
			for (i in 0 until width * height) {
				val j = packer.pack(i, DecodeMorton2X(i), DecodeMorton2Y(i), k, k2, minMask, width, height)
				out[j] = inp[i]
			}
		}

		return out;
	}

	fun CombinedUnswizzleTexture(inp: IntArray, width: Int, height: Int, swizzle: Boolean): IntArray {
		val out = IntArray(inp.size)

		val min = if (width < height) width else height;
		val k = (Math.log(min.toDouble()) / Math.log(2.0)).toInt()
		val k2 = k * 2
		val minMask = min - 1

		val packer = if (height < width) packJH else packJV

		if (swizzle) {
			for (i in 0 until width * height) {
				val j = packer.pack(i, DecodeMorton2X(i), DecodeMorton2Y(i), k, k2, minMask, width, height)
				out[i] = inp[j]
			}
		} else {
			for (i in 0 until width * height) {
				val j = packer.pack(i, DecodeMorton2X(i), DecodeMorton2Y(i), k, k2, minMask, width, height)
				out[j] = inp[i]
			}
		}

		return out;
	}

	/*
	fun SwizzleTexture(un: ShortArray, width: Int, height: Int): ShortArray {
		val swizzled = ByteArray(un.size)

		val min = if (width < height) width else height;
		val k = (Math.log(min.toDouble()) / Math.log(2.0)).toInt()
		val k2 = k * 2
		val minMask = min - 1


		for (y in 0 until height) {
			for (x in 0 until width) {
			}
		}

		if (height < width) {
			// XXXyxyxyx → XXXxxxyyy
			for (i in 0 until width * height) {
				val mx = DecodeMorton2X(i)
				val my = DecodeMorton2Y(i)
				val j = (i ushr (2 * k) shl (2 * k)) or
					((my and minMask) shl k) or
					((mx and minMask) shl 0) or
					((mx ushr k) shl k2)
				val x = j ushr k
				val y = j and minMask
				System.arraycopy(pixelData, i * bytesPerPixel, swizzled, ((y * width) + x) * bytesPerPixel, bytesPerPixel)
			}
		} else {
			// YYYyxyxyx → YYYyyyxxx
			for (i in 0 until width * height) {
				val mx = DecodeMorton2X(i)
				val my = DecodeMorton2Y(i)
				// YYYyxyxyx → YYYyyyxxx
				val j = (i ushr (2 * k) shl (2 * k)) or
					((mx and minMask) shl k) or
					((my and minMask) shl 0) or
					((my ushr k) shl k2)
				val x = j and minMask
				val y = j ushr k
				System.arraycopy(pixelData, i * bytesPerPixel, swizzled, ((y * width) + x) * bytesPerPixel, bytesPerPixel)
			}
		}

		return swizzled;
	}
	*/
}