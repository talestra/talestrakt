package com.talestra.shny.util

import com.soywiz.korio.async.sync
import com.soywiz.korio.stream.eof
import com.soywiz.korio.stream.openSync
import com.soywiz.korio.stream.readAll
import com.soywiz.korio.vfs.LocalVfs
import com.soywiz.korio.vfs.VfsOpenMode
import com.soywiz.korio.vfs.openAsIso
import com.talestra.shny.format.Script

fun main(args: Array<String>) = sync {
	val iso = LocalVfs("D:/isos/console/psp/Suzumiya Haruhi no Yakusoku.iso")
	val files = iso.openAsIso()
	for (file in files["PSP_GAME/USRDIR/data/script"].list()) {
		//println(file)
		val s = file.file.open(VfsOpenMode.READ).readAll().openSync()
		Script.check(s)
		s.position = 8
		while (!s.eof) Script.readInstruction(s)

	}
	//files.dump()
}