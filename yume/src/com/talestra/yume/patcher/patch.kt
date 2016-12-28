package com.talestra.yume.patcher

import WIP
import com.soywiz.kimage.awt.showImage
import com.soywiz.kimage.bitmap.Bitmap32
import com.soywiz.korio.vfs.ResourcesVfs
import com.soywiz.korio.vfs.VfsOpenMode
import com.talestra.yume.common.GameAssets
import com.talestra.yume.formats.ARC
import com.talestra.yume.formats.WSC
import java.io.File

@Singleton class Patcher(
	val assets: GameAssets
) {
	val translations by lazy {
		ResourcesVfs()["data/text/es.bin"].open(VfsOpenMode.READ)
		val s = getResourceBytes("data/text/es.bin").open2("r")
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

	fun patchScripts() {
		val rio = ARC.read(assets.folder["Rio.arc"].open2("r"))
		for ((name, data) in rio) {
			//println("$name:")
			//File("D:/$name.out").writeBytes(data.slice().readAll())
			val instructions = WSC.readInstructions(WSC.Encryption.decryptStream2(data.slice()), "UNKNOWN")
			println("$name: ${instructions.take(10)}")
		}
	}

	fun dumpTranslations() {
		for ((name, texts) in translations) {
			println("$name:")
			for ((id, text) in texts) {
				println("- $id: ${text.replace("\r", "").replace("\n", "\\n")}")
			}
		}
	}

	fun patchImages() {
		val images = WIP.read(assets.CHIP_ARC["MAINGP.WIP"]!!)

		fun cleanMainMenuBackground(bg: Bitmap32) {
			val slice = bg.sliceWithSize(207, 162, 7, 268)
			for (n in 0 until 7) bg.put(slice, 207 + 7 * n, 162)
			val patch1 = bg.sliceWithSize(248, 315, 29, 10)
			bg.put(patch1, 248, 267)
		}

		cleanMainMenuBackground(images[0].bitmap as Bitmap32)

		showImage(images[0].bitmap)
	}
}

object PatcherSpike {
	@JvmStatic fun main(args: Array<String>) {
		val assets = GameAssets(File("D:/juegos/yume"))
		val injector = Injector()
		injector.map(assets)
		val patcher = injector.get<Patcher>()
		//patcher.patchScripts()
		//patcher.dumpTranslations()
		patcher.patchImages()
	}
}