package com.talestra.yume.patcher

import WIP
import com.soywiz.korim.awt.awtShowImage
import com.soywiz.korim.bitmap.Bitmap32
import com.soywiz.korim.bitmap.sliceWithSize
import com.soywiz.korio.async.syncTest
import com.soywiz.korio.inject.AsyncInjector
import com.soywiz.korio.inject.Singleton
import com.soywiz.korio.stream.eof
import com.soywiz.korio.stream.readS32_le
import com.soywiz.korio.stream.readStringz
import com.soywiz.korio.vfs.LocalVfs
import com.soywiz.korio.vfs.ResourcesVfs
import com.talestra.rhcommon.lang.AsyncCacheItem
import com.talestra.rhcommon.lang.mapWhile
import com.talestra.yume.common.GameAssets
import com.talestra.yume.formats.WSC
import com.talestra.yume.formats.openAsARC

@Singleton class Patcher(
		val assets: GameAssets
) {
	val resources = ResourcesVfs

	val translations = AsyncCacheItem {
		val s = resources["data/text/es.bin"].readAsSyncStream()
		mapWhile({ !s.eof }) {
			val name = s.readStringz(s.readS32_le())
			val count = s.readS32_le()
			name to (0 until count).map {
				val id = s.readS32_le()
				val text = s.readStringz(s.readS32_le(), Charsets.ISO_8859_1)
				id to text
			}.toMap()
		}.toMap()
	}

	suspend fun patchScripts() {
		val rio = assets.folder["Rio.arc"].openAsARC()
		for (file in rio.listRecursive()) {
			//println("$name:")
			//File("D:/$name.out").writeBytes(data.slice().readAll())
			val instructions = WSC.readInstructions(WSC.Encryption.decryptStream2(file.readAsSyncStream()), "UNKNOWN")
			println("${file.fullname}: ${instructions.take(10)}")
		}
	}

	suspend fun dumpTranslations() {
		for ((name, texts) in translations.get()) {
			println("$name:")
			for ((id, text) in texts) {
				println("- $id: ${text.replace("\r", "").replace("\n", "\\n")}")
			}
		}
	}

	suspend fun patchImages() {
		val images = WIP.read(assets.CHIP_ARC["MAINGP.WIP"])

		fun cleanMainMenuBackground(bg: Bitmap32) {
			val slice = bg.sliceWithSize(207, 162, 7, 268)
			for (n in 0 until 7) bg.put(slice, 207 + 7 * n, 162)
			val patch1 = bg.sliceWithSize(248, 315, 29, 10)
			bg.put(patch1, 248, 267)
		}

		cleanMainMenuBackground(images[0].bitmap as Bitmap32)

		awtShowImage(images[0].bitmap)
	}
}

object PatcherSpike {
	@JvmStatic fun main(args: Array<String>) = syncTest {
		val assets = GameAssets(LocalVfs("D:/juegos/yume"))
		val injector = AsyncInjector()
		injector.map(assets)
		val patcher = injector.get<Patcher>()
		//patcher.patchScripts()
		//patcher.dumpTranslations()
		patcher.patchImages()
	}
}