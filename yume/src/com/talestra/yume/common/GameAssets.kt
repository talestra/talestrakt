package com.talestra.yume.common

import com.soywiz.korio.vfs.VfsFile
import com.soywiz.korio.vfs.VfsOpenMode
import com.talestra.yume.formats.ARC

class GameAssets(val folder: VfsFile) {
	val CHIP_ARC: VfsFile by lazy { ARC.read(folder["Chip.arc"].open(VfsOpenMode.READ)) }
}