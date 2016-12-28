package com.talestra.dividead.play

import com.soywiz.kimage.awt.convertImage
import com.soywiz.kimage.awt.transferTo
import com.soywiz.kimage.bitmap.Bitmap32
import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.async.sync
import com.soywiz.korio.stream.SyncStream
import com.soywiz.korio.stream.toInputStream
import com.soywiz.korio.vfs.LocalVfs
import com.soywiz.korio.vfs.VfsFile
import com.talestra.dividead.openAsDL1
import com.talestra.dividead.uncompressIfRequired
import java.awt.Font
import java.awt.Graphics
import java.awt.Graphics2D
import java.awt.event.KeyAdapter
import java.awt.event.KeyEvent
import java.awt.event.MouseEvent
import java.awt.image.BufferedImage
import java.awt.image.DataBufferInt
import java.io.BufferedInputStream
import java.io.File
import javax.imageio.ImageIO
import javax.sound.midi.MidiSystem
import javax.sound.sampled.AudioSystem
import javax.swing.JFrame
import javax.swing.JPanel
import javax.swing.WindowConstants
import javax.swing.event.MouseInputAdapter

class PlaySwing {
	fun combineColorMask(color: BufferedImage, mask: BufferedImage): BufferedImage {
		val out = BufferedImage(color.width, color.height, BufferedImage.TYPE_INT_ARGB)
		val i_out = (out.raster.dataBuffer as DataBufferInt).data
		val i_color = (convertImage(color).raster.dataBuffer as DataBufferInt).data
		val i_mask = (convertImage(mask).raster.dataBuffer as DataBufferInt).data
		for (n in 0 until i_out.size) {
			i_out[n] = (i_color[n] and 0x00FFFFFF) or (i_mask[n].toInt() shl 24)
		}
		out.flush()
		return out
	}

	val WIDTH = 640
	val HEIGHT = 480
	val scale = 2
	val ACTUAL_WIDTH = WIDTH * scale
	val ACTUAL_HEIGHT = HEIGHT * scale

	val BASE = LocalVfs("D:/juegos/dividead")
	lateinit var SG: VfsFile
	lateinit var WV: VfsFile


	val SGx2 = BASE["SG.DL1.2x.d"]

	val buffer = BufferedImage(ACTUAL_WIDTH, ACTUAL_HEIGHT, BufferedImage.TYPE_INT_ARGB)

	val back = Bitmap32(ACTUAL_WIDTH, ACTUAL_HEIGHT)

	//val bg = ImageFormats.read(SGx2["H_PB0.png"]).toBMP32()
	//val color = ImageFormats.read(SGx2["B01_1A.png"]).toBMP32()
	//val alpha = ImageFormats.read(SGx2["B01_0.png"]).toBMP32()
	//val image = Bitmap32.createWithAlpha(color, alpha)
//
//
	////val image = Bitmap32.createWithAlpha(color = ImageFormats.read(SG["B01_1A.BMP"]!!).toBMP32(), alpha = ImageFormats.read(SG["B01_0.BMP"]!!).toBMP32())
//
	////back.draw(bmp1, -100, -100)
	//back.put(bg)
	//back.draw(image)
	////*/

	val panel = object : JPanel() {
		override fun paintComponent(g: Graphics) {
			super.paintComponent(g)
			g.drawImage(buffer, 0, 0, null)
		}

	}

	fun update() {
		back.transferTo(buffer)
		panel.repaint()
	}

	fun playSound(s: SyncStream) {
		val audioInputStream = AudioSystem.getAudioInputStream(s.toInputStream())
		val clip = AudioSystem.getClip()
		clip.open(audioInputStream)
		clip.start()
	}

	val sequencer by lazy {
		val sequencer = MidiSystem.getSequencer();
		sequencer.open();
		sequencer
	}

	fun playMidi(s: SyncStream) {
		sequencer.stop()
		val `is` = BufferedInputStream(s.toInputStream())
		sequencer.setSequence(`is`)
		sequencer.start()
	}


	val renderer = object : Renderer() {
		override suspend fun draw(img: String, x: Int, y: Int) = asyncFun {
			if (!SGx2["$img.png"].exists()) return@asyncFun
			//val i = ImageFormats.read(SGx2["$img.png"]).toBMP32()
			//back.draw(i, x * scale, y * scale)
			try {
				val image = ImageIO.read(SGx2["$img.png"].readAsSyncStream().toInputStream())
				buffer.graphics.drawImage(image, x * scale, y * scale, null)
			} catch (e: Throwable) {
				e.printStackTrace()
			}
		}

		override suspend fun drawMasked(color: String, mask: String, x: Int, y: Int) = asyncFun {
			if (!SGx2["$color.png"].exists()) return@asyncFun
			if (!SGx2["$mask.png"].exists()) return@asyncFun
			//val i = ImageFormats.read(SGx2["$img.png"]).toBMP32()
			//back.draw(i, x * scale, y * scale)
			try {
				val color = ImageIO.read(SGx2["$color.png"].readAsSyncStream().toInputStream())
				val mask = ImageIO.read(SGx2["$mask.png"].readAsSyncStream().toInputStream())
				val image = combineColorMask(color, mask)
				buffer.graphics.drawImage(image, x * scale, y * scale, null)
			} catch (e: Throwable) {
				e.printStackTrace()
			}
		}

		override fun text(text: String, x: Int, y: Int) {
			val g = buffer.graphics as Graphics2D
			val size = 14
			g.font = Font("Lucida Console", 0, size * scale)
			g.drawString(text, x * scale, (y + size) * scale)
		}

		override fun update(x: Int, y: Int, width: Int, height: Int) {
			panel.repaint(x * scale, y * scale, width * scale, height * scale)
		}

		override suspend fun playMusic(s: String) = asyncFun {
			playMidi(BASE["MID"]["$s.mid"].readAsSyncStream())
		}
	}

	class Input2 : Input() {
		fun register(frame: JFrame) {
			frame.addMouseListener(object : MouseInputAdapter() {
				override fun mouseClicked(e: MouseEvent?) {
					onClick(Unit)
				}
			})
			frame.addKeyListener(object : KeyAdapter() {
				override fun keyTyped(e: KeyEvent) {
					skipping = e.isControlDown
					onKeyPress(Unit)
					super.keyTyped(e)
				}

				override fun keyPressed(e: KeyEvent) {
					skipping = e.isControlDown
					onKeyPress(Unit)
					super.keyPressed(e)
				}

				override fun keyReleased(e: KeyEvent) {
					skipping = e.isControlDown
					super.keyReleased(e)
				}
			})
		}
	}

	val input = Input2()

	val script = object : Script() {
		override suspend fun setScript(name: String) = asyncFun {
			s = SG["$name.AB"].readAsSyncStream()
		}
	}

	suspend fun init() = asyncFun {
		script.setScript("AASTART", 5838)
		val state = State()

		val ab = ScriptEvaluator(script, renderer, state, input)

		while (true) {
			ab.execOne()
		}
	}

	//renderer.draw("H_PB0")
	//renderer.flip()



	/*
	frame = JFrame("DiviDead").apply {

	}
	*/

	fun main() = sync {
		SG = BASE["SG.DL1"].openAsDL1().uncompressIfRequired()
		WV = BASE["WV.DL1"].openAsDL1().uncompressIfRequired()
		back.setEach { x, y -> 0xFF000000.toInt() }

		JFrame("DiviDead").apply {
			//ignoreRepaint = true
			//createBufferStrategy(2)

			iconImage = ImageIO.read(ClassLoader.getSystemResource("dividead/icon.png"))

			contentPane.add(panel)

			setBounds(0, 0, ACTUAL_WIDTH, ACTUAL_HEIGHT)
			//setSize(ACTUAL_WIDTH, ACTUAL_HEIGHT)
			//pack()
			isResizable = false
			setLocationRelativeTo(null)
			defaultCloseOperation = JFrame.EXIT_ON_CLOSE
			isVisible = true
			update()
			//playMidi(BASE["MID"]["BGM_1.MID"].open2("r"))
			//playSound(WV["AZU0075.WAV"]!!)
			//Timer(5000, object : ActionListener {
			//	override fun actionPerformed(e: ActionEvent?) {
			//		playMidi(BASE["MID"]["BGM_2.MID"].open2("r"))
			//	}
			//}).start()

			input.register(this)
			init()
		}

		Unit
	}

	companion object {
		@JvmStatic fun main(args: Array<String>): Unit = PlaySwing().main()
	}
}


object SwingSandbox {

	@JvmStatic fun main(args: Array<String>) {
		val frame = buildFrame()

		val image = ImageIO.read(File("D:/juegos/dividead/SG.DL1.d/B01_1B.BMP"))

		val pane = object : JPanel() {
			override fun paintComponent(g: Graphics) {
				super.paintComponent(g)
				g.drawImage(image, 0, 0, null)
			}
		}

		pane.setBounds(0, 0, 200, 200)

		frame.contentPane.add(pane)

		pane.repaint()
	}


	private fun buildFrame(): JFrame {
		val frame = JFrame()
		frame.defaultCloseOperation = WindowConstants.EXIT_ON_CLOSE
		frame.setSize(500, 500)
		//frame.pack()
		frame.isVisible = true
		//frame.invalidate()
		frame.contentPane.repaint()
		return frame
	}

}