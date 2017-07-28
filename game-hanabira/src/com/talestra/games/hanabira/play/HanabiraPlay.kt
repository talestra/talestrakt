package com.talestra.games.hanabira.play

import com.soywiz.korau.sound.NativeSound
import com.soywiz.korau.sound.readNativeSoundOptimized
import com.soywiz.korge.Korge
import com.soywiz.korge.scene.Module
import com.soywiz.korge.scene.Scene
import com.soywiz.korge.scene.sleep
import com.soywiz.korge.time.seconds
import com.soywiz.korge.view.Container
import com.soywiz.korge.view.text
import com.soywiz.korim.color.Colors
import com.soywiz.korim.color.RGBA
import com.soywiz.korim.format.ImageData
import com.soywiz.korim.format.ImageFormats
import com.soywiz.korio.async.go
import com.soywiz.korio.async.invokeSuspend
import com.soywiz.korio.inject.AsyncDependency
import com.soywiz.korio.inject.AsyncInjector
import com.soywiz.korio.inject.Singleton
import com.soywiz.korio.stream.SyncStream
import com.soywiz.korio.stream.readAll
import com.soywiz.korio.util.allDeclaredMethods
import com.soywiz.korio.vfs.LocalVfs
import com.soywiz.korio.vfs.VfsFile
import com.talestra.games.hanabira.MSD
import com.talestra.games.hanabira.openFJSYS
import java.lang.reflect.Method

object HanabiraPlay : Module() {
	@JvmStatic fun main(args: Array<String>) = Korge(this)

	override val width: Int get() = 800
	override val height: Int get() = 600

	suspend override fun init(injector: AsyncInjector) {
		injector.mapTyped(HanabiraConfig(
				root = LocalVfs("C:\\temp\\hanabira")
		))
	}

	override val mainScene: Class<out Scene> = HanabiraScene::class.java
}

class HanabiraConfig(
		val root: VfsFile
)

@Singleton
class HanabiraResources(
		private val config: HanabiraConfig
) : AsyncDependency {
	private lateinit var bgm: VfsFile
	private lateinit var mgd: VfsFile
	private lateinit var msd: VfsFile
	private lateinit var voice: VfsFile

	suspend override fun init() {
		bgm = config.root["BGM"].openFJSYS()
		//mgd = config.root["MGD"].openFJSYS()
		mgd = config.root["MGE"].openFJSYS()
		//msd = config.root["MSD"].openFJSYS()
		msd = config.root["MSE"].openFJSYS()
		voice = config.root["VOICE"].openFJSYS()
	}

	suspend fun getMusic(name: String): NativeSound = bgm[name].withExtension("ogg").readNativeSoundOptimized()
	suspend fun getVoice(name: String): NativeSound = voice[name].withExtension("ogg").readNativeSoundOptimized()
	suspend fun getMgd(name: String): ImageData = ImageFormats.readImage(mgd[name].withExtension("mgd").readAsSyncStream())
	suspend fun getMsd(name: String): MSD.Script = MSD.read(msd[name].withExtension("msd").readAll())
}

class ScriptState {
	val colors = arrayListOf(Colors.WHITE, Colors.BLACK)
	val globals = IntArray(512)
}

@Suppress("unused", "UNUSED_PARAMETER")
class ScriptEvaluator(val evaluator: Any) {
	var name = "unknown"
	var sr = MSD.ScriptReader(MSD.Script(listOf(), listOf(), listOf()))
	val opsToMethods = hashMapOf<MSD.Opcode, Method>()

	init {
		for (method in evaluator.javaClass.allDeclaredMethods) {
			val run = method.getAnnotation(MSD.Run::class.java) ?: continue
			opsToMethods[run.op] = method
		}
	}

	fun setScript(s: MSD.Script, name: String = "unknown") {
		this.sr = MSD.ScriptReader(s)
		this.name = name
	}

	fun setScript(s: ByteArray, offset: Int = 0, name: String = "unknown") {
		setScript(MSD.read(s), name = name)
	}

	fun setScript(s: SyncStream, name: String = "unknown") {
		setScript(MSD.read(s.readAll()), name = name)
	}

	suspend fun step() {
		//println(i)
		val instruction = sr.script.instructions[sr.position++]
		callInstruction(instruction)

	}

	suspend fun callInstruction(instruction: MSD.INSTRUCTION) {
		val method = opsToMethods[instruction.op]
		println(instruction)
		println(method)
		method?.invokeSuspend(evaluator, instruction.args)
	}
}


class HanabiraScene(
		val resources: HanabiraResources
) : Scene() {
	val state = ScriptState()
	val evaluator = ScriptEvaluator(this)

	suspend override fun sceneInit(sceneView: Container) {
		go {
			//val s = resources.getMsd("main")
			val s = resources.getMsd("s001")
			//s.writeToFile(File("C:\\temp\\hanabira\\MSD.d\\main.msd"))
			evaluator.setScript(s)
			while (true) {
				evaluator.step()
			}
		}

		/*
		val mgd = resources.getMgd("bg04a")
		val bmp = mgd.mainBitmap
		val tex = views.texture(bmp)
		sceneView.addChild(views.image(tex))
		go {
			resources.getVoice("nana0001").play()
		}
		*/
		/*
		go {
			val music = resources.getMusic("M01")
			music.play()
		}
		*/
	}

	@MSD.Run(MSD.Opcode.TEXT_COLOR)
	suspend fun textColor(id: Int, r: Int, g: Int, b: Int) {
		state.colors[id] = RGBA(r, g, b, 0xFF)
	}

	@MSD.Run(MSD.Opcode.TEXT)
	suspend fun text(unk1: Int, unk2: Int, unk3: Int, text: String, unk4: Int, unk5: Int) {
		sceneView += views.text(text)
	}

	@MSD.Run(MSD.Opcode.WAIT_CLICK) suspend fun waitClick() = run { sleep(10.seconds) }
	@MSD.Run(MSD.Opcode.SET_GLOBAL) suspend fun setGlobal(id: Int, value: Int) = run { state.globals[id] = value }
}
