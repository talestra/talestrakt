package com.talestra.games.toa.jobs

import com.talestra.games.toa.ToaFS

class MISC(
		val fs: ToaFS
) {
	val target = fs.target
	val resources = fs.resources

	suspend fun process() {
		processDat()
		processImages()
		processEnding()
	}

	suspend fun processDat() {
	}

	suspend fun processImages() {
	}

	suspend fun processEnding() {
		target.set("root/TOAEND_US.TXT", resources["end/TOAEND_ES.TXT"])
	}
}