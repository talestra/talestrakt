package com.talestra.yume.play

import com.jtransc.JTranscSystem
import com.talestra.yume.formats.ARC
import java.io.File

val YumeModule = object : Module() {
	init {

	}

	override val mainSceneClass: Class<out Scene> get() = YumeScene::class.java
	override val dependencies: List<Any> = super.dependencies + listOf(
		//GamePaths(File("D:/juegos/yume/Chip.arc"))
	)
}

@Singleton
class GameAssets(
	//private val gamePaths: GamePaths
) {
	lateinit var chipArc: VfsFile
	lateinit var rioArc: VfsFile
	lateinit var voiceArc: VfsFile
	lateinit var seArc: VfsFile

	/*
	override fun initAsync(): Promise<Unit> = async {
		chipArc = ARC.readAsync(gamePaths.chipArc.openAsync2().await()).await()
		rioArc = ARC.readAsync(gamePaths.rioArc.openAsync2().await()).await()
		voiceArc = ARC.readAsync(gamePaths.voiceArc.openAsync2().await()).await()
		seArc = ARC.readAsync(gamePaths.seArc.openAsync2().await()).await()
	}
	*/

	fun setRootAsync(root: VfsFile) = async<Unit> {
		//if (JTranscSystem.isJs()) {
		//	chipArc = root["CHIP.ARC.d"]
		//	rioArc = root["RIO.ARC.d"]
		//	voiceArc = root["VOICE.ARC.d"]
		//	seArc = root["SE.ARC.d"]
		//} else {
		chipArc = ARC.readAsync(root["CHIP.ARC"].openAsync().await()).await()
		rioArc = ARC.readAsync(root["RIO.ARC"].openAsync().await()).await()
		voiceArc = ARC.readAsync(root["VOICE.ARC"].openAsync().await()).await()
		seArc = ARC.readAsync(root["SE.ARC"].openAsync().await()).await()
		//}
	}
}

class YumeScene(
	val g2: G2,
	val backend: Backend,
	val assets: GameAssets,
	val eval: ScriptEvaluator,
	injector: Injector
) : Scene(injector) {
	init {
		async<Unit> {
			if (JTranscSystem.isJs()) {
				//assets.setRootAsync(backend.vfs).await()
				assets.setRootAsync(ISO.openVfsAsync(backend.vfs["YUDISC1.iso"].openAsync().await()).await()).await()
			} else {

				//assets.setRootAsync(ISO.openVfsAsync(UrlVfs("http://127.0.0.1:8080/")["YUDISC1.iso"].openAsync().await()).await()).await()

				//assets.setRootAsync(ISO.openVfsAsync(backend.dialogs.openFileAsync().await()).await()).await()
				assets.setRootAsync(ISO.openVfsAsync(File("D:/isos/pc/YUDISC1.iso").openAsync2().await()).await()).await()
			}

			//println(file2["Chip.arc"].statAsync().await())
			//println(file2["CHIP.ARC"].statAsync().await())

			//println(file2)

			//backend.dialogs.openFileAsync().await()

			//val wipData = assets.chipArc["BG_01E.WIP"].readBytesAsync().await()
			//val wip = WipView(g2, wipData)
//
			//val bmp = Bitmap32(800, 600)
//
			//g2.renderToBitmap32(bmp, linear = true) {
			//	wip.render(g2)
			//}
//
			//sceneView += Image(g2.createTexture(bmp))
			//sceneView += wip


			sceneView += eval.view

			eval.initAsync().await()
			//eval.setScriptAsync("TITLE").await()
			//eval.setScriptAsync("T001_01", 5700).await()
			//eval.setScriptAsync("T001_01", 19255).await()
			//eval.setScriptAsync("T001_01", 36030).await()
			//eval.setScriptAsync("t001_02a", 35708).await()
			//eval.setScriptAsync("t001_04d").await()
			//eval.setScriptAsync("TITLE").await()
			eval.setScriptAsync("START").await()

			while (true) {
				eval.execOneAsync().await()
			}

		}
	}
}