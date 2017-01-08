package com.talestra.dividead.play

import com.jtransc.annotation.JTranscKeep
import com.soywiz.korim.bitmap.Bitmap32
import com.soywiz.korim.bitmap.BitmapChannel
import com.soywiz.korim.color.Colors
import com.soywiz.korim.font.drawText
import com.soywiz.korim.font.nativeFonts
import com.soywiz.korim.format.readBitmap
import com.soywiz.korim.geom.Anchor
import com.soywiz.korim.geom.ScaleMode
import com.soywiz.korio.async.*
import com.soywiz.korio.util.OS
import com.soywiz.korio.vfs.*
import com.soywiz.korui.Application
import com.soywiz.korui.frame
import com.soywiz.korui.geom.len.pt
import com.soywiz.korui.style.height
import com.soywiz.korui.style.width
import com.soywiz.korui.ui.*
import com.talestra.dividead.openAsDL1
import com.talestra.dividead.uncompressIfRequired
import java.io.FileNotFoundException
import java.io.IOException

object Play {
	lateinit var root: VfsFile
	lateinit var backBufferImage: Image
	val backBuffer = Bitmap32(640, 480)

	var loadButton: Button? = null

	val onClick = Signal<Unit>()

	@JvmStatic fun main(args: Array<String>) = EventLoop.main {
		val frameIcon = ResourcesVfs["dividead/icon1.png"].readBitmap()
		//val bmp = ResourcesVfs["dividead/icon.png"].readBitmap()
		//val bmp = ImageFormats.decode(ResourcesVfs["dividead/icon.png"])
		//println(bmp)
		//backBuffer.put(bmp.toBMP32())



		Application().frame("DIVI DEAD", width = 640, height = 480) {
			bgcolor = Colors.BLACK
			icon = frameIcon
			layersKeepAspectRatio(anchor = Anchor.MIDDLE_CENTER, scaleMode = ScaleMode.SHOW_ALL) {
				backBufferImage = image(backBuffer) {
					width = 640.pt
					height = 480.pt
					smooth = true
				}.click {
					onClick()
					//println("click: $mouseX, $mouseY")
				}
			}
			loadButton = button("Load").click {
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
		try {
			tryLoadRoot(JailedLocalVfs("D:/juegos/dividead"))
		} catch (e: IOException) {

		}
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

		backBufferImage.click {
			println("$mouseX,$mouseY")
		}

		val script = object : Script() {
			@JTranscKeep
			override suspend fun setScript(name: String) = asyncFun {
				s = SG["$name.AB"].readAsSyncStream()
			}
		}

		val font = nativeFonts.getNativeFont("Arial", 15.0)

		var chars = ""
		chars += ('A'..'Z').joinToString("")
		chars += ('a'..'z').joinToString("")
		chars += ('0'..'9').joinToString("")
		chars += "áéíóúñü"
		chars += "ÁÉÍÓÚÑÜ"
		chars += "¿¡?!"
		chars += "@"
		chars += "\""
		chars += "[](){}"
		chars += "'"
		chars += " \t"
		chars += ".,;:"

		val bmpFont = font.getGlyphs(chars)
		//println(aGlyph)
		//println(aGlyph.data.toList())

		val renderer = object : Renderer() {
			suspend private fun getBmp(name: String): Bitmap32 = asyncFun {
				val imgName = PathInfo(name).pathWithExtension("BMP")
				val bmp = SG[imgName.toUpperCase()].readBitmap().toBMP32()
				bmp
			}

			suspend private fun getBmp2(color: String, mask: String): Bitmap32 = asyncFun {
				val c = getBmp(color)
				val m = getBmp(mask)
				Bitmap32.createWithAlpha(c, m, alphaChannel = BitmapChannel.RED)
			}

			@JTranscKeep
			override suspend fun draw(img: String, x: Int, y: Int, anchor: Anchor) = asyncFun {
				backBuffer.put(getBmp(img), x, y)
				//println("draw: $img")
			}

			@JTranscKeep
			override suspend fun drawMasked(color: String, mask: String, x: Int, y: Int, anchor: Anchor) = asyncFun {
				val bitmapData = getBmp2(color, mask)

				backBuffer.draw(bitmapData, (640 / 2 - (bitmapData.width * anchor.sx)).toInt(), (385 - bitmapData.height * anchor.sy).toInt())
				println("draw: $color, $mask")
			}

			@JTranscKeep
			suspend override fun fill(x: Int, y: Int, width: Int, height: Int, color: Int) {
				backBuffer.fill(color, x, y, width, height)
			}

			@JTranscKeep
			override suspend fun text(text: String, x: Int, y: Int) {
				backBuffer.drawText(bmpFont, text.replace('@', '"'), x, y)
				println("draw: $text")
			}

			@JTranscKeep
			override suspend fun update(x: Int, y: Int, width: Int, height: Int) {
				println("update: $x, $y, $width, $height")
				backBufferImage.refreshImage()
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
				onClick.waitOne()
				//sleep(1000)
			}
		}

		script.setScript("AASTART", 5838)
		//script.setScript("AASTART", 0)
		val state = State()

		val ab = ScriptEvaluator(script, renderer, state, input)

		while (true) {
			ab.execOne()
		}
	}
}