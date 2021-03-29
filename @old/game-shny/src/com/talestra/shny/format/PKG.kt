package com.talestra.shny.format

import com.soywiz.korio.stream.*

object PKG {
	fun read(s: SyncStream) {
		val slices = readSlices(s.sliceWithStart(s.readS32_le().toLong()))
		val sprites = readSprites(s.sliceWithStart(s.readS32_le().toLong()))
	}

	data class Slice(
		val _1: Int,
		val draw_x: Int,
		val draw_y: Int,
		val image_id: Int,
		val _3: Int,
		val slice_x: Int,
		val slice_y: Int,
		val slice_width: Int,
		val slice_height: Int,
		val _4: Int,
		val _5: Int,
		val _6: Int,
		val _7: Int,
		val _8: Int
	)

	fun readSlices(s: SyncStream) {
		val count = s.readU16_le() / 2
		s.position -= 2
		val ptrs = (0 until count).map { s.readU16_le() + it * 2 }
		val slices = (0 until count).map {
			Slice(
				_1 = s.readS16_le(),
				draw_x = s.readS16_le(),
				draw_y = s.readS16_le(),
				image_id = s.readS16_le(),
				_3 = s.readS16_le(),
				slice_x = s.readS16_le(),
				slice_y = s.readS16_le(),
				slice_width = s.readS16_le(),
				slice_height = s.readS16_le(),
				_4 = s.readS16_le(),
				_5 = s.readS16_le(),
				_6 = s.readS16_le(),
				_7 = s.readS16_le(),
				_8 = s.readS16_le()
			)
		}
		for (slice in slices) {
			println(slice)
		}
	}

	fun readSprites(s: SyncStream) {
		val base = s.position
		val count = s.readU16_le() / 2
		s.position -= 2
		val ptrs = (0 until count).map { s.readU16_le() + base + it * 2 }
		val anims = (0 until count).map {
			(0 until s.readU16_le()).map {
				(0 until 10).map {
					s.readU16_le()
				}
			}
		}
		for (anim in anims) {
			println(anim)
		}
	}
}