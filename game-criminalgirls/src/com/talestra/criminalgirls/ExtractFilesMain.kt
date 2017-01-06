package com.talestra.criminalgirls

import com.soywiz.korio.async.sync
import com.soywiz.korio.vfs.LocalVfs

fun main(args: Array<String>): Unit = sync {
	val root = LocalVfs("D:/isos/psvita/DATA.DAT").openAsPs3Fs()
	val out = LocalVfs("D:/isos/psvita/criminalgirls.out").jail()
	out.mkdirs()
	for (item in root.listRecursive()) {
		print(item.fullname + "(${item.size()})...")
		val outItem = out[item.fullname]
		if (!outItem.exists()) {
			outItem.writeFile(item)
			println("Ok")
		} else {
			println("Exists")
		}
	}
	Unit
}