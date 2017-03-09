package com.talestra.games.toa

import com.soywiz.korim.format.readImageImageNoNative
import com.soywiz.korim.format.showImagesAndWait
import com.soywiz.korio.async.EventLoop
import com.soywiz.korio.vfs.LocalVfs
import com.soywiz.korio.vfs.openAsIso
import com.talestra.games.toa.util.openAsCVM

fun main(args: Array<String>) = EventLoop {
	val iso = LocalVfs("d:/isos/ps2/Tales of the Abyss.iso").openAsIso()
	val root = iso["TO7ROOT.CVM"].openAsCVM()
	for (f in root.listRecursive()) println(f)
	showImagesAndWait(root["_S_MENU.TM2"].readImageImageNoNative())
	//showImagesAndWait(root["_FONTA.TM2"].readImageImageNoNative())
	//showImagesAndWait(root["ENDROLL.TM2"].readImageImageNoNative())
	//showImagesAndWait(root["SUNLIGHT.TM2"].readImageImageNoNative())
	//println(root["TOAEND_US.TXT"].readString())
}