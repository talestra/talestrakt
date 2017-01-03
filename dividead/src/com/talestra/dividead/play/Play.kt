package com.talestra.dividead.play

import com.jtransc.annotation.JTranscKeep
import com.soywiz.korim.bitmap.Bitmap32
import com.soywiz.korim.font.drawText
import com.soywiz.korim.font.nativeFonts
import com.soywiz.korim.format.readBitmap
import com.soywiz.korio.async.EventLoop
import com.soywiz.korio.async.async
import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.async.sleep
import com.soywiz.korio.util.OS
import com.soywiz.korio.vfs.*
import com.soywiz.korui.Application
import com.soywiz.korui.frame
import com.soywiz.korui.ui.Button
import com.soywiz.korui.ui.Image
import com.soywiz.korui.ui.button
import com.soywiz.korui.ui.image
import com.talestra.dividead.openAsDL1
import com.talestra.dividead.uncompressIfRequired
import java.io.FileNotFoundException

object Play {
	lateinit var root: VfsFile
	lateinit var backBufferImage: Image
	val backBuffer = Bitmap32(640, 480)

	var loadButton: Button? = null

	@JvmStatic fun main(args: Array<String>) = EventLoop.main {
		val frameIcon = ResourcesVfs["dividead/icon1.png"].readBitmap()
		//val bmp = ResourcesVfs["dividead/icon.png"].readBitmap()
		//val bmp = ImageFormats.decode(ResourcesVfs["dividead/icon.png"])
		//println(bmp)
		//backBuffer.put(bmp.toBMP32())

		Application().frame("DIVI DEAD", width = 640, height = 480) {
			icon = frameIcon
			backBufferImage = image(backBuffer)
			loadButton = button("Load") {
				val file = dialogOpenFile()
				println("Selected file: $file")
				tryLoadRoot(if (file.extension == "iso") {
					file.openAsIso()
				} else {
					file
				})
			}
			if (!OS.isJs) {
				async { tryAutoload() }
			}
		}
	}

	suspend private fun tryAutoload() = asyncFun {
		tryLoadRoot(JailedLocalVfs("D:/juegos/dividead"))
	}

	suspend private fun tryLoadRoot(root: VfsFile) = asyncFun {
		this.root = root
		println("Loaded: ${Play.root}")
		if (!Play.root["SG.DL1"].exists()) {
			println("File not found!")
			throw FileNotFoundException("SG.DL1")
		}
		loadButton?.visible = false
		startGame()
	}

	suspend fun startGame() = asyncFun {
		println("startGame: $root")

		val SG = root["SG.DL1"].openAsDL1().uncompressIfRequired()
		val WV = root["WV.DL1"].openAsDL1().uncompressIfRequired()
		val imgFile = SG["B04_0.BMP"]

		println("startGame.imgFile: $imgFile")
		//val stat = imgFile.stat()
		//println(stat)
		//backBufferImage.image = imgFile.readBitmap()
		//backBuffer.draw(imgFile.readBitmap().toBMP32())
		//backBufferImage.refreshImage()

		backBufferImage.onClick {
			println("$mouseX,$mouseY")
		}

		val script = object : Script() {
			@JTranscKeep
			override suspend fun setScript(name: String) = asyncFun {
				s = SG["$name.AB"].readAsSyncStream()
			}
		}

		val font = nativeFonts.getNativeFont("Arial", 15.0)
		val bmpFont = font.getGlyphs("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.,")
		//println(aGlyph)
		//println(aGlyph.data.toList())

		val renderer = object : Renderer() {
			@JTranscKeep
			override suspend fun draw(img: String, x: Int, y: Int) = asyncFun {
				val imgName = PathInfo(img).pathWithExtension("BMP")
				val bmp = SG[imgName.toUpperCase()].readBitmap().toBMP32()
				backBuffer.put(bmp, x, y)
				//println("draw: $img")
			}

			@JTranscKeep
			override suspend fun drawMasked(color: String, mask: String, x: Int, y: Int) = asyncFun {
				println("draw: $color, $mask")
			}

			@JTranscKeep
			override suspend fun text(text: String, x: Int, y: Int) {
				backBuffer.drawText(bmpFont, text, x, y)
				println("draw: $text")
			}

			@JTranscKeep
			override suspend fun update(x: Int, y: Int, width: Int, height: Int) {
				println("update: $x, $y, $width, $height")
				backBufferImage.image = backBuffer
			}

			@JTranscKeep
			override suspend fun playMusic(s: String) = asyncFun {
				println("playMusic")
			}
		}

		val input = object : Input() {
			override var skipping: Boolean
				get() = super.skipping
				set(value) {}

			@JTranscKeep
			suspend override fun waitText() = asyncFun {
				sleep(1000)
			}
		}

		//script.setScript("AASTART", 5838)
		script.setScript("AASTART", 0)
		val state = State()

		val ab = ScriptEvaluator(script, renderer, state, input)

		while (true) {
			ab.execOne()
		}
	}
}