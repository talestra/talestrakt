package com.talestra.criminalgirls

import com.soywiz.korio.async.filter
import com.soywiz.korio.async.sync
import com.soywiz.korio.vfs.LocalVfs
import com.soywiz.korio.vfs.ResourcesVfs
import com.talestra.rhcommon.translations.KAcme
import com.talestra.rhcommon.translations.PO

object ConvertTxtToPo {
	@JvmStatic fun main(args: Array<String>) = sync {
		val outFolder = LocalVfs("/Users/soywiz/out").apply { mkdirs() }.jail()
		for (file in ResourcesVfs["text"].list().filter { it.extensionLC == "txt" }) {
			println(file.fullname)
			val entries = KAcme.read(file.readString().lines())
			outFolder[file.withExtension("po").basename].writeString(PO.generate(entries))
			println("Ok")
			//println(entries)
		}
	}
}