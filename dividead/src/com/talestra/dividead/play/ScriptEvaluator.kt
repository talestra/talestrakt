package com.talestra.dividead.play

import com.soywiz.korio.async.asyncFun
import com.talestra.dividead.AB
import java.io.File
import java.util.*

class ScriptEvaluator(val script: Script, val render: Renderer, val state: State, val input: Input) {
	//static var margin = { x = 108, y = 400, h = 12 };

	// ---------------
	//  FLOW RELATED
	// ---------------

	val methodsByOpcode = this.javaClass.declaredMethods.filter { it.getAnnotation(AB.Action::class.java) != null }.associateBy {
		it.getAnnotation(AB.Action::class.java)?.opcode
	}

	suspend fun execOne(): Any? {
		val instruction = script.read()
		val method = methodsByOpcode[instruction.op]
		println(instruction)
		val result = method?.invoke(this, *instruction.param.toTypedArray())
		//return Promise.ensure(result).unit
		return result
	}

	suspend private fun repaint() = asyncFun {
		render.update(0, 0, 640, 480)
	}

	@AB.Action(AB.Opcode.JUMP) fun JUMP(offset: Int) {
		script.jump(offset)
	}

	@AB.Action(AB.Opcode.JUMP_IF_NOT) fun JUMP_IF_NOT(flag: Int, op: Char, value: Int, pointer: Int) {
		//printf("JUMP_IF_NOT (%08X) FLAG[%d] %c %d\n", pointer, flag, op, value);
		val result = when (op) {
			'=' -> (state.flags[flag] == value)
			'}' -> (state.flags[flag] > value)
			'{' -> (state.flags[flag] < value)
			else -> throw Exception("Unknown JUMP_IF_NOT operation '$op'")
		}
		if (!result) script.jump(pointer)
	}

	@AB.Action(AB.Opcode.SET_RANGE_FLAG) fun SET_RANGE_FLAG(start: Int, end: Int, value: Int) {
		//Log.trace("FLAG[$start..$end] = $value")
		//Log.trace("CHECK: Is \'end\' flag included?")
		for (n in start until end) state.flags[n] = value
	}

	@AB.Action(AB.Opcode.TITLE) fun TITLE(title: String) {
		state.title = title
		println("Set title: '$title'")
	}

	// ---------------
	//  SOUND RELATED
	// ---------------

	@AB.Action(AB.Opcode.MUSIC_PLAY) suspend fun MUSIC_PLAY(name: String) = asyncFun {
		render.playMusic(name)
	}

	// ---------------
	//  IMAGE RELATED
	// ---------------

	@AB.Action(AB.Opcode.FOREGROUND) suspend fun FOREGROUND(name: String) = asyncFun {
		state.foreground = name
		render.draw(state.foreground, 0, 0)
	}

	@AB.Action(AB.Opcode.BACKGROUND) suspend fun BACKGROUND(name: String) = asyncFun {
		state.background = name
		render.draw(state.background, 32, 8)
	}

	@AB.Action(AB.Opcode.REPAINT) suspend fun REPAINT(type: Int) = asyncFun {
		repaint()
		//Thread.sleep(300)
	}

	@AB.Action(AB.Opcode.REPAINT_IN) suspend fun REPAINT_IN(type: Int) = asyncFun {
		repaint()
	}


	@AB.Action(AB.Opcode.TEXT) suspend fun TEXT(text: String) = asyncFun {
		render.text(text, 102, 400)
		render.update(0, 400, 640, 80)
		input.waitText()
		repaint()
	}

	@AB.Action(AB.Opcode.SET) fun SET(flag: Int, op: Char, value: Int) {
		println("FLAG[$flag] $op $value")
		when (op) {
			'=' -> state.flags[flag] = value
			'+' -> state.flags[flag] += value
			'-' -> state.flags[flag] -= value
			else -> throw Exception("Unknown SET operation '$op'")
		}
	}

	@AB.Action(AB.Opcode.OPTION_RESET) fun OPTION_RESET() {
		state.options.clear()
	}

	//@Unimplemented
	@AB.Action(AB.Opcode.OPTION_ADD) fun OPTION_ADD(pointer: Int, text: String) {
		val option = Option(state.script, pointer, text)
		state.options += option
	}

	//@Unimplemented
	@AB.Action(AB.Opcode.OPTION_SHOW) suspend fun OPTION_SHOW() = asyncFun {
		val selected = Random().nextInt(state.options.size)
		script.jump(state.options[selected].offset)
	}

	@AB.Action(AB.Opcode.OPTION_RESHOW) suspend fun OPTION_RESHOW() = asyncFun {
		OPTION_SHOW()
	}

	@AB.Action(AB.Opcode.CHARA1) suspend fun CHARA1(name: String) = asyncFun {
		val nameColor = name
		val nameMask = name.split('_')[0] + "_0"

		render.drawMasked(nameColor, nameMask, 0, 0)
		//return game.getImageMaskCachedAsync(nameColor, nameMask).then { bitmapData ->
		//	game.back.draw(bitmapData, (640 / 2 - bitmapData.width / 2), (385 - bitmapData.height))
		//}
	}

	@AB.Action(AB.Opcode.CHARA2) suspend fun CHARA2(name1: String, name2: String) = asyncFun {
		val name1Color = name1
		val name1Mask = name1.split('_')[0] + "_0"

		val name2Color = name2
		val name2Mask = name2.split('_')[0] + "_0"

		//return game.getImageMaskCachedAsync(name1Color, name1Mask).pipe { bitmapData1 ->
		//	game.getImageMaskCachedAsync(name2Color, name2Mask).then { bitmapData2 ->
		//		game.back.draw(bitmapData1, 640 * 1 / 3 - bitmapData1.width / 2, 385 - bitmapData1.height)
		//		game.back.draw(bitmapData2, 640 * 2 / 3 - bitmapData2.width / 2, 385 - bitmapData2.height)
		//	}
		//}
	}

	@AB.Action(AB.Opcode.SCRIPT) suspend fun SCRIPT(name: String) = asyncFun {
		//Log.trace("SCRIPT('$name')")
		script.setScript(File(name).nameWithoutExtension.toUpperCase(), 0)
	}

	@AB.Action(AB.Opcode.MAP_OPTION_RESET) fun MAP_OPTION_RESET() {
		state.optionsMap.clear()
	}

	@AB.Action(AB.Opcode.MAP_OPTION_ADD) fun MAP_OPTION_ADD(pointer: Int, x1: Int, y1: Int, x2: Int, y2: Int) {
		state.optionsMap += MapOption(state.script, pointer, x1, y1, x2 - x1, y2 - y1)
	}

	@AB.Action(AB.Opcode.MAP_OPTION_SHOW) suspend fun MAP_OPTION_SHOW() = asyncFun {
		val selected = Random().nextInt(state.optionsMap.size)
		script.jump(state.optionsMap[selected].offset)
	}

	/*




	//@Unimplemented
	@AB.Action(AB.Opcode.GAME_END) fun GAME_END() {
		Log.trace("GAME_END")
		ab.end()
		throw Exception("GAME_END")
	}

	// ---------------
	//  INPUT
	// ---------------

	//@Unimplemented
	@AB.Action(AB.Opcode.TEXT) fun TEXT(text: String): Promise<Unit> {
		//println("TEXT: $text")
		game.textField.text = text.replace('@', '"')

		var slices = game.ui.PAGES.map { Bitmap(it) }
		var animated = Sprite()
		var totalTime = 0
		animated.addUpdatable { dt ->
			totalTime += dt
			animated.removeChildren()
			animated.addChild(slices[(totalTime / 100) % slices.size])
		}
		game.overlaySprite.removeChildren()
		game.overlaySprite.addChild(animated)
		var promise = if (game.isSkipping()) {
			game.gameSprite.timers.waitAsync(50.milliseconds)
		} else {
			//game.gameSprite.timers.waitAsync(5000.milliseconds);
			val deferred = Promise.Deferred<Unit>()
			val group = DisposableGroup()
			fun done() {
				group.dispose()
				deferred.resolve(Unit)
			}
			animated.keys.onKeyDown.add {
				if (it.code != Keys.ESC) done()
			}
			animated.mice.onMouseClick.add {
				done()
			}

			deferred.promise
		}
		animated.x = 520.0
		animated.y = 448.0

		return promise.then { e ->
			game.textField.text = ""
			game.overlaySprite.removeChildren()
			game.voiceChannel.stop()
		}
	}



	@AB.Action(AB.Opcode.MAP_IMAGES) fun MAP_IMAGES(name1: String, name2: String) {
		game.state.mapImage1 = name1
		game.state.mapImage2 = name2
	}

	@AB.Action(AB.Opcode.MAP_OPTION_RESET) fun MAP_OPTION_RESET() {
		game.state.optionsMap.clear()
	}

	@AB.Action(AB.Opcode.MAP_OPTION_ADD) fun MAP_OPTION_ADD(pointer: Int, x1: Int, y1: Int, x2: Int, y2: Int) {
		game.state.optionsMap.add(GameState.MapOption(pointer, IRectangle(x1, y1, x2 - x1, y2 - y1)))
	}

	@AB.Action(AB.Opcode.MAP_OPTION_SHOW) fun MAP_OPTION_SHOW(): Promise<Unit> {

		//return Promise.whenAll(
		//	game.getImageCachedAsync(game.state.mapImage1),
		//	game.getImageCachedAsync(game.state.mapImage2)
		//).pipe { bitmaps ->
		//	val bg = bitmaps[0];
		//	val fg = bitmaps[1];
		//	var matrix = Matrix();
		//	matrix.translate(32.0, 8.0);
		//	game.front.draw(bg, matrix);
		//	var events = EventListenerListGroup();
		//	var deferred = Promise.Deferred<Unit>();
		//	game.state.optionsMap.forEach { option ->
		//		var pointer = option.pointer;
		//		var rect: Rectangle = option.rect;
		//		var slice = Sprite();
		//		slice.addChild(Bitmap(BitmapDataUtils.slice(fg, rect), PixelSnapping.AUTO, true));
		//		slice.x = rect.x + 32;
		//		slice.y = rect.y + 8;
		//		slice.alpha = 0.0
		//		events.addEventListener(slice, MouseEvent.MOUSE_OVER, function(e) {
		//			println("over");
		//			slice.alpha = 1.0
		//		});
		//		events.addEventListener(slice, MouseEvent.MOUSE_OUT, function(e) {
		//			println("out");
		//			slice.alpha = 0.0
		//		});
		//		events.addEventListener(slice, MouseEvent.CLICK, function(e) {
		//			deferred.resolve(option);
		//		});
		//		game.overlaySprite.addChild(slice);
		//	}
		//	deferred.promise.then { option ->
		//		events.dispose();
		//		game.overlaySprite.removeChildren();
		//		ab.jump(option.pointer);
		//	}
		//}

		noImpl
	}

	@AB.Action(AB.Opcode.WAIT) fun WAIT(time: Int): Promise<Unit> {
		if (game.isSkipping()) return Promise.unit

		return game.gameSprite.timers.waitAsync((time * 10).milliseconds)
	}


	@AB.Action(AB.Opcode.MUSIC_STOP) fun MUSIC_STOP() {
		ab.game.musicChannel.stop()
	}

	@AB.Action(AB.Opcode.VOICE_PLAY) fun VOICE_PLAY(name: String): Promise<Unit> {
		return ab.game.getSoundAsync(name).then { sound ->
			ab.game.voiceChannel.play(sound)
		}
	}

	@AB.Action(AB.Opcode.EFFECT_PLAY) fun EFFECT_PLAY(name: String): Promise<Unit> {
		EFFECT_STOP()
		return ab.game.getSoundAsync(name).then { sound ->
			ab.game.effectChannel.play(sound)
		}
	}

	@AB.Action(AB.Opcode.EFFECT_STOP) fun EFFECT_STOP() {
		ab.game.effectChannel.stop()
	}

	@AB.Action(AB.Opcode.IMAGE_OVERLAY) fun IMAGE_OVERLAY(name: String): Promise<Unit> {
		return game.getImageCachedAsync(name).then { bitmapData ->
			val outBitmapData = bitmapData.applyChroma(Colors.GREEN)
			game.back.draw(outBitmapData, 32, 8)
		}
	}


	// ----------------------
	//  IMAGE/EFFECT RELATED
	// ----------------------

	@AB.Action(AB.Opcode.ANIMATION) fun ANIMATION(type: Int): Promise<Unit> {

		//var time = if (game.isSkipping()) 50.milliseconds else 500.milliseconds
		//var names = (0 until 6).map { n -> state.background.substr(0, -1) + String.fromCharCode('A'.code + n)] }
		//var promises = names.map { game.getImageCachedAsync(name) }
		//return Promise.whenAll(promises).pipe { images ->
		//	var stepAsync: (() -> Promise<Unit>)? = null
		//	stepAsync = fun(v: Any) {
		//		if (images.length > 0) {
		//			var image = images.shift();
		//			//trace('image', image);
		//			var bmp = Bitmap(image, PixelSnapping.AUTO, true);
		//			bmp.x = 32.0;
		//			bmp.y = 8.0;
		//			game.overlaySprite.removeChildren();
		//			game.overlaySprite.addChild(bmp);
		//			game.back.draw(image, new Matrix(1, 0, 0, 1, 32, 8));
		//			return game.gameSprite.timers.waitAsync(time).pipe(stepAsync);
		//		} else {
		//			return game.gameSprite.timers.waitAsync(time);
		//		}
		//	};
		//	stepAsync(null).then {
		//		//trace('*******************');
		//		game.overlaySprite.removeChildren();
		//	}
		//}

		return Promise.unit
	}

	@AB.Action(AB.Opcode.SCROLL_DOWN) fun SCROLL_DOWN(type: Int) = _SCROLL_DOWN_UP("A", +1.0)

	@AB.Action(AB.Opcode.SCROLL_UP) fun SCROLL_UP(type: Int) = _SCROLL_DOWN_UP("B", -1.0)

	private fun _SCROLL_DOWN_UP(add: String, multiplier: Double) {

		//val time = if (game.isSkipping()) 300.milliseconds else 3000.milliseconds
		//val bgB = state.background + add;
		//return game.getImageCachedAsync(bgB).pipe { bgBImage ->
		//	var bgImage = BitmapDataUtils.slice(game.front, IRectangle(32, 8, bgBImage.width, bgBImage.height));
		//	var a = Bitmap(bgImage, PixelSnapping.AUTO, true);
		//	var b = Bitmap(bgBImage, PixelSnapping.AUTO, true);
		//	var container = Sprite();
		//	b.y = a.height * multiplier;
		//	container.addChild(a);
		//	container.addChild(b);
		//	container.scrollRect = Rectangle(0.0, 0.0, bgImage.width, bgImage.height)
		//	container.x = 32.0
		//	container.y = 8.0
		//	game.overlaySprite.removeChildren();
		//	game.overlaySprite.addChild(container);
		//	game.gameSprite.animateAsync(time, Easing.easeInOutQuad) { ratio ->
		//		val ratio = ratio * multiplier;
		//		container.scrollRect = Rectangle(0, bgImage.height * ratio, bgImage.width, bgImage.height);
		//	}.then { v ->
		//		game.front.draw(container, Matrix(1.0, 0.0, 0.0, 1.0, 32.0, 8.0));
		//		game.back.draw(container, Matrix(1.0, 0.0, 0.0, 1.0, 32.0, 8.0));
		//		game.overlaySprite.removeChildren();
		//	}
		//}

	}


	// ----------------------
	//  EFFECT RELATED
	// ----------------------

	@AB.Action(AB.Opcode.CLIP) fun CLIP(x1: Int, y1: Int, x2: Int, y2: Int) {
	}

	@AB.Action(AB.Opcode.FADE_OUT_BLACK) fun FADE_OUT_BLACK():Promise<Unit> {
		return ab.paintToColorAsync(Colors.BLACK, 1.seconds)
	}

	@AB.Action(AB.Opcode.FADE_OUT_WHITE) fun FADE_OUT_WHITE() = ab.paintToColorAsync(Colors.WHITE, 1.seconds)
	*/
}
