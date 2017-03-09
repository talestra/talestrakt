package com.talestra.games.toa

import com.soywiz.korio.inject.AsyncDependency
import com.soywiz.korio.vfs.MemoryVfs
import com.soywiz.korio.vfs.ResourcesVfs
import com.soywiz.korio.vfs.VfsFile
import com.talestra.games.toa.util.openAsCVM

class ToaFS(val iso: VfsFile) : AsyncDependency {
	val resources = ResourcesVfs["com/talestra/games/toa"].jail()
	lateinit var root: VfsFile
	lateinit var target: VfsFile

	suspend override fun init() {
		root = iso["TO7ROOT.CVM"].openAsCVM()
		target = MemoryVfs()
	}
}