package com.talestra.talesof.complib

import com.soywiz.korio.util.*
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.util.*
import java.util.zip.Inflater
import java.util.zip.InflaterInputStream
import kotlin.system.measureTimeMillis

object CompTalesOf {
	fun isCompressed(data: ByteArray): Boolean {
		if (data.size < 9) return false
		if (data.readStringz(0, 4) == "TLZC") return true
		if (data[0] == 0.toByte() && data.readS32_le(1) == data.readS32_le(5)) return true
		if (data[0] == 1.toByte()) return true
		if (data[0] == 3.toByte()) return true
		return false
	}

	fun deepDecompressWhileRequired(data: ByteArray): ByteArray {
		var workData = data
		while (isCompressed(workData)) workData = decompress(workData)
		return workData
	}

	fun decompress(data: ByteArray): ByteArray {
		if (data.readStringz(0, 4) == "TLZC") {
			if (data.readS32_be(4) != 0x01020000) throw IllegalArgumentException("Not a TLZC file version 0x01010000")
			val compressed = data.readS32_le(8)
			val uncompressed = data.readS32_le(16)
			val out = ByteArrayOutputStream(uncompressed)
			val inp = ByteArrayInputStream(data.readByteArray(24, compressed))
			val inflater = Inflater(true)
			InflaterInputStream(inp, inflater).copyTo(out)
			return out.toByteArray()
		} else if (data[0] == 0.toByte() ||data[0] == 1.toByte() || data[0] == 3.toByte()) {
			val level = data[0].toUnsigned()
			when (level) {
				0, 1, 3 -> Unit
				else -> throw IllegalArgumentException("Not a compto format")
			}

			val compressed = data.readS32_le(1)
			val uncompressed = data.readS32_le(5)

			if (level == 0) {
				if (uncompressed != compressed) throw IllegalArgumentException("Not compression level")
				return Arrays.copyOfRange(data, 9, 9 + uncompressed)
			} else {
				return decompressLzRawFast(level, data, 9, 9 + compressed, uncompressed)
				//return decompressLzRawSlow(level, data, 9, 9 + compressed, ByteArray(uncompressed), 0, uncompressed)
			}
		} else {
			throw IllegalArgumentException("Not a compto format")
		}
	}

	fun testDecompressionSpeed(c: ByteArray) {
		for (n in 0 until 10000) measureTimeMillis { CompTalesOf.decompress(c) }
		val times = (0 until 40).map {
			measureTimeMillis {
				for (n in 0 until 10000) CompTalesOf.decompress(c)
			}
		}
		println("%d-%d".format(times.min(), times.max()))
	}

	val LZ_PREDATA by lazy {
		val out = ByteArray(0x1000)
		var p = 0
		for (n in 0 until 0x100) {
			out[p + 0] = n.toByte()
			out[p + 1] = 0.toByte()
			out[p + 2] = n.toByte()
			out[p + 3] = 0.toByte()
			out[p + 4] = n.toByte()
			out[p + 5] = 0.toByte()
			out[p + 6] = n.toByte()
			out[p + 7] = 0.toByte()
			p += 8
		}

		for (n in 0 until 0x100) {
			out[p + 0] = n.toByte()
			out[p + 1] = 0xFF.toByte()
			out[p + 2] = n.toByte()
			out[p + 3] = 0xFF.toByte()
			out[p + 4] = n.toByte()
			out[p + 5] = 0xFF.toByte()
			out[p + 6] = n.toByte()
			p += 7
		}
		out
	}

	//fun decompressLzRawFast(version: Int, inp: ByteArray, ioffset: Int, iend: Int, outSize: Int): ByteArray {
	//	return when (version) {
	//		1 -> decompressLzRawFastV1(inp, ioffset, iend, outSize)
	//		3 -> decompressLzRawFastV3(inp, ioffset, iend, outSize)
	//		else -> throw RuntimeException("Unknown version")
	//	}
	//}
//
	//fun decompressLzRawFastV1(inp: ByteArray, ioffset: Int, iend: Int, outSize: Int): ByteArray {
	//	val out = ByteArray(0x1000 + outSize)
	//	val N = 0x1000
	//	val RING_MASK = N - 1
	//	val T = 2
	//	val F = 0x12
//
	//	var i = ioffset
//
	//	System.arraycopy(LZ_BUFFER, 0, out, F, N - F)
//
	//	var o = N
//
	//	main@while (true) {
	//		val flags = inp[i++].toInt()
	//		for (n in 0 until 8) {
	//			// UNCOMPRESSED
	//			if (((flags ushr n) and 1) != 0) {
	//				val c = inp[i++]
	//				out[o++] = c
	//			} else {
	//				if (i >= iend) break@main
	//				val c1 = inp[i++].toInt()
	//				val c2 = inp[i++].toInt()
	//				val v1 = (c1 and 0xFF) or ((c2 and 0xF0) shl 4)
	//				val v2 = (c2 and 0x0F) + T
	//				// LZ
	//				val backpos = o - ((o - F - v1) and RING_MASK)
	//				val len = v2 + 1
	//				System.arraycopy(out, backpos, out, o, len)
	//				o += len
	//			}
	//		}
	//	}
//
	//	if (i != iend) throw IllegalArgumentException("Failed to decompress (I)")
	//	if (o != out.size) throw IllegalArgumentException("Failed to decompress (O)")
//
	//	return Arrays.copyOfRange(out, 0x1000, out.size)
	//}
//
	//fun decompressLzRawFastV3(inp: ByteArray, ioffset: Int, iend: Int, outSize: Int): ByteArray {
	//	val out = ByteArray(0x1000 + outSize)
	//	var flags = 0
	//	val N = 0x1000
	//	val RING_MASK = N - 1
	//	val T = 2
	//	val F = 0x11
	//	var i = ioffset
	//	System.arraycopy(LZ_BUFFER, 0, out, F, N - F)
	//	var o = N
	//	main@while (true) {
	//		flags = flags ushr 1
	//		if ((flags and 0x100) == 0) {
	//			flags = (inp[i++].toInt() and 0xFF) or 0xFF00
	//		}
//
	//		// UNCOMPRESSED
	//		if ((flags and 1) != 0) {
	//			val c = inp[i++]
	//			out[o++] = c
	//		} else {
	//			if (i >= iend) break@main
	//			val c1 = inp[i++].toInt()
	//			val c2 = inp[i++].toInt()
	//			val v1 = (c1 and 0xFF) or ((c2 and 0xF0) shl 4)
	//			val v2 = (c2 and 0x0F) + T
	//			// LZ
	//			if (v2 < F) {
	//				val backpos = o - ((o - F - v1) and RING_MASK)
	//				val len = v2 + 1
	//				System.arraycopy(out, backpos, out, o, len)
	//				o += len
	//			}
	//			// RLE
	//			else {
	//				val c = if (v1 < 0x100) inp[i++] else (v1 and 0xff).toByte()
	//				val len = (if (v1 < 0x100) v1 + F + 1 else (v1 ushr 8) + T) + 1
	//				Arrays.fill(out, o, o + len, c)
	//				o += len
	//			}
	//		}
	//	}
//
	//	if (i != iend) throw IllegalArgumentException("Failed to decompress (I)")
	//	if (o != out.size) throw IllegalArgumentException("Failed to decompress (O)")
//
	//	return Arrays.copyOfRange(out, 0x1000, out.size)
	//}

	// 50% faster decompression. Ring buffer not required. This is possible
	// because we are going to have the whole output in memory so we can use
	// output data instead of the ring buffer.
	fun decompressLzRawFast(level: Int, inp: ByteArray, ioffset: Int, iend: Int, outSize: Int): ByteArray {
		val out = ByteArray(0x1000 + outSize)
		var flags = 0
		val N = 0x1000
		val RING_MASK = N - 1
		val T = 2
		val F = when (level) {
			1 -> 0x12
			3 -> 0x11
			else -> throw RuntimeException("Unknown version")
		}

		var i = ioffset

		System.arraycopy(LZ_PREDATA, 0, out, F, N - F)

		var o = N

		main@ while (i < iend) {
			flags = flags ushr 1
			if ((flags and 0x100) == 0) {
				flags = (inp[i++].toInt() and 0xFF) or 0xFF00
			}

			// UNCOMPRESSED
			if ((flags and 1) != 0) {
				val c = inp[i++]
				//println("Uncompressed[%d]: %02X".format(o - N, c))
				out[o++] = c
			} else {
				val c1 = inp[i++].toInt()
				val c2 = inp[i++].toInt()
				val v1 = (c1 and 0xFF) or ((c2 and 0xF0) shl 4)
				val v2 = (c2 and 0x0F) + T
				// LZ
				if (level == 1 || v2 < F) {
					//val RingOffset = N - F ; val outputPosition = o - N ; val readPosInRing = v1
					//val writePosInRing = (RingOffset + outputPosition) and RING_MASK
					//val offset = (writePosInRing - readPosInRing) and RING_MASK
					//val backpos = o - offset ; val len = v2 + 1
					val backpos = o - ((o - F - v1) and RING_MASK)
					val len = v2 + 1

					//println("$v1: $v2 -> $backpos($len) -> $o :: rel(${backpos - o})")
					//for (n in 0 until len) {
					//	println("Compressed[%d]: %02X".format(o - N + n, out[backpos + n]))
					//}
					System.arraycopy(out, backpos, out, o, len)
					o += len
				}
				// RLE
				else {
					//val c: Byte
					//val len: Int
					//if (v1 < 0x100) {
					//	c = inp[i++]
					//	len = v1 + F + 1
					//} else {
					//	c = (v1 and 0xff).toByte()
					//	len = (v1 ushr 8) + T
					//}

					val c = if (v1 < 0x100) inp[i++] else (v1 and 0xff).toByte()
					val len = (if (v1 < 0x100) v1 + F + 1 else (v1 ushr 8) + T) + 1
					//println("RLE")
					Arrays.fill(out, o, o + len, c)
					o += len
				}
			}
		}

		if (i != iend) throw IllegalArgumentException("Failed to decompress (I)")
		//println("$o, ${out.size}")
		if (o != out.size) throw IllegalArgumentException("Failed to decompress (O)")

		return Arrays.copyOfRange(out, 0x1000, out.size)
	}

	fun decompressLzRawSlow(version: Int, inp: ByteArray, ioffset: Int, iend: Int, out: ByteArray, ooffset: Int, oend: Int): ByteArray {
		var flags = 0
		val N = 0x1000
		val MF = 0x12
		val T = 2
		val F = when (version) {
			1 -> 0x12
			3 -> 0x11
			else -> throw RuntimeException("Unknown version")
		}
		val RingBuffer = ByteArray(N + MF - 1)
		val RingMask = N - 1

		var i = ioffset
		var o = ooffset
		var r = N - F

		System.arraycopy(LZ_PREDATA, 0, RingBuffer, 0, N)

		while (i < iend) {
			flags = flags ushr 1
			if ((flags and 0x100) == 0) {
				flags = inp[i++].toUnsigned() or 0xff00
			}

			// UNCOMPRESSED
			if ((flags and 1) != 0) {
				val c = inp[i++]
				//println("Uncompressed[%d]: %02X".format(o - ooffset, c))
				out[o++] = c
				RingBuffer[r++] = c
				r = r and RingMask
			} else {
				val c1 = inp[i++].toUnsigned()
				val c2 = inp[i++].toUnsigned()
				val v1 = c1 or ((c2 and 0xf0) shl 4)
				val v2 = (c2 and 0x0f) + T
				// LZ
				if (version == 1 || v2 < (F)) {
					//println("CompressedBlock: $v1, $v2")
					for (k in 0..v2) {
						val c = RingBuffer[(v1 + k) and RingMask]
						//println("Compressed[%d]: %02X".format(o - ooffset, c))
						out[o++] = c
						RingBuffer[r++] = c
						r = r and RingMask
					}
				}
				// RLE
				else {
					val c: Byte
					val len: Int
					if (v1 < 0x100) {
						c = inp[i++]
						len = v1 + F + 1
					} else {
						c = (v1 and 0xff).toByte()
						len = (v1 ushr 8) + T
					}
					for (k in 0..len) {
						out[o++] = c
						RingBuffer[r++] = c
						r = r and RingMask
					}
				}
			}
		}

		if (i != iend) throw IllegalArgumentException("Failed to decompress")
		if (o != oend) throw IllegalArgumentException("Failed to decompress")

		return out
	}
}