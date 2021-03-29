package com.talestra.shny

import com.soywiz.korim.format.PNG
import com.soywiz.korim.format.readBitmap
import com.soywiz.korim.format.writeBitmap
import com.soywiz.korio.async.sync
import com.soywiz.korio.async.syncTest
import com.soywiz.korio.vfs.LocalVfs
import com.soywiz.korio.vfs.openAsIso
import com.talestra.platform.psp.GIM

fun main(args: Array<String>) = syncTest {
	val iso = LocalVfs("D:/isos/psp/Suzumiya Haruhi no Yakusoku.iso")
	val files = iso.openAsIso()

	//val data = files["PSP_GAME/USRDIR/data/script/s_tnormal.dat"].open2("r").readAll()
	//val s = data.open2("r")
	//Script.check(s)
	//s.position = 8
	//while (!s.eof) Script.readInstruction(s)

	for (file in files["PSP_GAME/USRDIR/data/bg"].listRecursive()) {
		println(file.fullname)
		val img = file.readBitmap()
		//val bgFolder = LocalVfs("D:/bg").mkdirs()
		LocalVfs("D:/bg/${file.basename}.png").ensureParents().writeBitmap(img)
	}

	//val gim = GIM.read(files["PSP_GAME/USRDIR/data/bg/bg001_0.gim"].open2("r"))
	//showImage(gim)
}