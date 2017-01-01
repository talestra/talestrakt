package com.talestra.dividead.play

import com.soywiz.korim.bitmap.Bitmap32
import com.soywiz.korim.color.Colors
import com.soywiz.korim.format.readBitmap
import com.soywiz.korio.async.EventLoop
import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.vfs.ResourcesVfs
import com.soywiz.korio.vfs.VfsFile
import com.soywiz.korio.vfs.openAsIso
import com.soywiz.korui.Application
import com.soywiz.korui.frame
import com.soywiz.korui.ui.Image
import com.soywiz.korui.ui.button
import com.soywiz.korui.ui.image
import com.talestra.dividead.openAsDL1
import com.talestra.dividead.uncompressIfRequired
import java.io.FileNotFoundException

object PlayKorui {
	lateinit var root: VfsFile
	lateinit var backBufferImage: Image
	val backBuffer = Bitmap32(640, 480, { x, y -> Colors.BLACK })

	@JvmStatic fun main(args: Array<String>) = EventLoop.main {
		val bmp = ResourcesVfs["dividead/icon.png"].readBitmap()
		//val bmp = ImageFormats.decode(ResourcesVfs["dividead/icon.png"])
		//println(bmp)
		backBuffer.put(bmp.toBMP32())
		Application().frame("DiviDead", width = 640, height = 480) {
			backBufferImage = image(backBuffer)
			button("Load") {
				val file = dialogOpenFile()
				println("Selected file: $file")
				root = if (file.extension == "iso") {
					file.openAsIso()
				} else {
					file
				}
				println("Loaded: $root")
				if (!root["SG.DL1"].exists()) {
					println("File not found!")
					throw FileNotFoundException("SG.DL1")
				}
				this.visible = false
				startGame()
			}
		}
	}

	suspend fun startGame() = asyncFun {
		println("startGame: $root")

		//val SG_raw = root["SG.DL1"].openAsDL1()

		//SG_raw.copyToTree(LocalVfs("/tmp/out").apply { mkdir() })

		val SG = root["SG.DL1"].openAsDL1().uncompressIfRequired()
		val WV = root["WV.DL1"].openAsDL1().uncompressIfRequired()
		//val imgFile = SG["B01_1B.BMP"]
		val imgFile = SG["B04_0.BMP"]

		println("startGame.imgFile: $imgFile")
		//val stat = imgFile.stat()
		//println(stat)
		//backBufferImage.image = imgFile.readBitmap()
		backBuffer.draw(imgFile.readBitmap().toBMP32())
		//backBufferImage.refreshImage()
		backBufferImage.image = backBuffer

		backBufferImage.onClick {
			println("$mouseX,$mouseY")
		}
	}
}