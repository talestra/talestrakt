package com.talestra.dividead

import jmedialayer.backends.Backend
import jmedialayer.graphics.Bitmap32

class Screen {
	val width: Int get() = 640
	val height: Int get() = 480

	val back = Bitmap32(width, height)
	val front = Bitmap32(width, height)
	var updated = false

	fun copyRow(row: Int) {
		updated = false
		front.copyPixels(back, 0, row, back.width, 1, 0, row)
	}

	fun upload(backend: Backend) {
		if (!updated) {
			updated = true
			backend.g1.updateBitmap(front)
		} else {
			//println("Do nothing!")
		}
	}
}