package com.talestra.yume.common

import com.soywiz.korio.vfs.VfsFile
import com.talestra.rhcommon.inject.AsyncDependency
import com.talestra.yume.formats.openAsARC

class GameAssets(val folder: VfsFile) : AsyncDependency {
	lateinit var CHIP_ARC: VfsFile

	suspend override fun init() {
		CHIP_ARC = folder["Chip.arc"].openAsARC()
	}
}