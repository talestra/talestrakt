package com.talestra.games.hanabira.util

import com.soywiz.korim.format.readImageData
import com.soywiz.korim.format.showImagesAndWait
import com.soywiz.korio.async.spawn
import com.soywiz.korio.async.syncTest
import com.soywiz.korio.error.ignoreErrors
import com.soywiz.korio.stream.openAsync
import com.soywiz.korio.stream.openSync
import com.soywiz.korio.stream.readAvailable
import com.soywiz.korio.stream.skip
import com.soywiz.korio.vfs.JailedLocalVfs
import com.soywiz.korio.vfs.VfsFile
import com.talestra.games.hanabira.MSD
import com.talestra.games.hanabira.openFJSYS

fun main(args: Array<String>) = syncTest {
	val root = JailedLocalVfs("C:\\temp\\hanabira")
	//root["BGM"].openFJSYS().copyToTree(root["BGM.d"].ensureParents(), notify = { process(it) })
	//root["DATA"].openFJSYS().copyToTree(root["DATA.d"].ensureParents(), notify = { process(it) })
	//root["MGD"].openFJSYS().copyToTree(root["MGD.d"].ensureParents(), notify = { process(it) })
	root["MGE"].openFJSYS().copyToTree(root["MGE.d"].ensureParents(), notify = { process(it) })
	root["MSD"].openFJSYS().copyToTree(root["MSD.d"].ensureParents(), notify = { process(it) })
	root["MSE"].openFJSYS().copyToTree(root["MSE.d"].ensureParents(), notify = { process(it) })
	//root["SE"].openFJSYS().copyToTree(root["SE.d"].ensureParents(), notify = { process(it) })
	//root["VOICE"].openFJSYS().copyToTree(root["VOICE.d"].ensureParents(), notify = { process(it) })
}

suspend fun process(it: Pair<VfsFile, VfsFile>) {
	when (it.first.extensionLC) {
		"mgd" -> {
			val data = it.first.read().openSync().skip(0x60).readAvailable()
			//println("mgd!")
			//println("data: ${data.size}")
			//println("it: ${it.second.withExtension("png")}")
			it.second.withExtension("png").write(data)
			//ignoreErrors(show = true) {
			//	spawn { showImagesAndWait(data.openAsync().readImageData()) }
			//}
		}
		"msd" -> {
			it.second.withExtension("msd2").write(MSD.decryptIfRequired(it.second.read()))
		}
	}
}
