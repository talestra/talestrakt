package com.talestra.platform.n3ds

import com.soywiz.korim.bitmap.Bitmap32

// From Citra emulator
object N3dsMorton {
	/**
	 * Interleave the lower 3 bits of each coordinate to get the intra-block offsets, which are
	 * arranged in a Z-order curve. More details on the bit manipulation at:
	 * https://fgiesen.wordpress.com/2009/12/13/decoding-morton-codes/
	 */
	fun MortonInterleave(x: Int, y: Int): Int {
		var i = (x and 7) or ((y and 7) shl 8) // ---- -210
		i = (i xor (i shl 2)) and 0x1313      // ---2 --10
		i = (i xor (i shl 1)) and 0x1515      // ---2 -1-0
		i = (i or (i ushr 7)) and 0x3F
		return i
	}

	/**
	 * Calculates the offset of the position of the pixel in Morton order
	 */
	fun GetMortonOffset(x: Int, y: Int, bytes_per_pixel: Int): Int {
		// Images are split into 8x8 tiles. Each tile is composed of four 4x4 subtiles each
		// of which is composed of four 2x2 subtiles each of which is composed of four texels.
		// Each structure is embedded into the next-bigger one in a diagonal pattern, e.g.
		// texels are laid out in a 2x2 subtile like this:
		// 2 3
		// 0 1
		//
		// The full 8x8 tile has the texels arranged like this:
		//
		// 42 43 46 47 58 59 62 63
		// 40 41 44 45 56 57 60 61
		// 34 35 38 39 50 51 54 55
		// 32 33 36 37 48 49 52 53
		// 10 11 14 15 26 27 30 31
		// 08 09 12 13 24 25 28 29
		// 02 03 06 07 18 19 22 23
		// 00 01 04 05 16 17 20 21
		//
		// This pattern is what's called Z-order curve, or Morton order.

		val block_height = 8
		val coarse_x = x and 7.inv()

		val i = MortonInterleave(x, y)

		val offset = coarse_x * block_height

		return (i + offset) * bytes_per_pixel
	}
}

// https://en.wikipedia.org/wiki/Z-order_curve
// https://en.wikipedia.org/wiki/Moser%E2%80%93de_Bruijn_sequence
// swizzled/twidled texture
fun Bitmap32.deswizzle(bytesPerPixel: Int) = this.apply {
	val temp = IntArray(this.area * 16)
	var m = 0
	for (y in 0 until height) {
		val coarse_y = y and 7.inv()
		for (x in 0 until width) {
			val n = N3dsMorton.GetMortonOffset(x, y, bytesPerPixel) + coarse_y * width * bytesPerPixel
			temp[m++] = this.data[n / bytesPerPixel]
		}
	}
	System.arraycopy(temp, 0, this.data, 0, this.area)
}