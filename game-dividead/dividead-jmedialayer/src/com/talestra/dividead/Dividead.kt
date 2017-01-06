package com.talestra.dividead

import jmedialayer.backends.Backend
import jmedialayer.backends.BackendSelector
import jmedialayer.graphics.Bitmap32
import jmedialayer.graphics.EmbeddedFont
import jmedialayer.imaging.BMP
import jmedialayer.util.Stopwatch

object Dividead {
	@JvmStatic fun main(args: Array<String>) {
		val stopwatch = Stopwatch()
		val time0 = stopwatch.stamp()
		val backend = BackendSelector.getDefault()
		val time1 = stopwatch.stamp()
		val game = Game(backend)

		//game.scriptHandler.setScript("AASTART")

		//game.scriptHandler.executeOne()

		val time2 = stopwatch.stamp()

		game.files
		//println(game.files.files)

		val time3 = stopwatch.stamp()
		val bmpBytesCompressed = game.files.readBytes("WAKU_A1.BMP")
		val time4 = stopwatch.stamp() // reading
		val bmpBytesUncompressed = LZ.uncompress(bmpBytesCompressed)
		val time5 = stopwatch.stamp() // uncompress
		val bmp = if (bmpBytesUncompressed.isNotEmpty()) BMP().read(bmpBytesUncompressed) else Bitmap32(300, 300)
		val bmp2 = game.files.readImage("I_46.BMP")
		val time6 = stopwatch.stamp() // decode

		//val bmp = game.files.readImage("WAKU_A1")

		println("" + bmp2.width + "x" + bmp2.height)

		//val bmp = files.readImage("B03_0.BMP")

		game.screen.back.draw(bmp.toBitmap32(), 0, 0, false)

		game.screen.back.draw(bmp2.toBitmap32(), 32, 8, false)
		val time7 = stopwatch.stamp()

		EmbeddedFont.draw(game.screen.back, 0, 0, "0=$time0, 1=$time1, 2=$time2, 3=$time3, 4=$time4, 5=$time5, 6=$time6, 7=$time7")


		//backend.setTween(20000) { step ->
		backend.setTween(250) { step ->
			game.transitions.transition(4, step)
		}

		backend.loop {
			game.screen.upload(backend)
		}
	}
}

class Game(val backend: Backend) {
	val screen = Screen()
	val transitions = Transitions(screen)
	val scriptHandler = ScriptHandler(this)
	val sgdl1 = backend.openRAStreanSync("SG.DL1") ?: backend.openRAStreanSync("ux0:/data/dividead/SG.DL1") ?: backend.openRAStreanSync("d:/juegos/dividead/SG.DL1")
	//val sgdl1 = backend.openRAStreanSync("ux0:/data/dividead/SG.DL1")  ?: backend.openRAStreanSync("d:/juegos/dividead/SG.DL1")
	val files by lazy { DL1.read(sgdl1) }
}

class ScriptHandler(val game: Game) : AB() {
	fun setScript(name: String) {
		s = game.files.readScriptStream(name)
	}
}
