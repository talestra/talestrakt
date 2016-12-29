package com.talestra.yume.play

import WIP
import com.talestra.rhcommon.inject.Singleton
import com.talestra.yume.formats.ANM
import com.talestra.yume.formats.TBL
import com.talestra.yume.formats.WSC
import java.io.File
import java.lang.reflect.Method

/*
@Suppress("unused")
@Singleton
open class ScriptEvaluator(
	val gameAssets: GameAssets,
	//@Path("fonts/default/font.fnt") val font: BitmapFont.Dependency,
	@Path("fonts/base/font.fnt") val font: BitmapFont.Dependency,
	val backend: Backend,
	val a1: A1,
	val g2: G2
) {
	val TRACE = false
	// All times are in frames. 1 tick = 1 frame. Game runs at 25fps.
	val FPS = 25
	val SECONDS_PER_TICK = 1.0 / FPS.toDouble()

	fun ticksToSeconds(ticks: Int) = (ticks * SECONDS_PER_TICK) * (if (skipping) 0.1 else 1.0)
	fun msToSeconds(ms: Int) = (ms / 1000.0) * (if (skipping) 0.1 else 1.0)

	object COMMON_FLAGS {
		val TEXT_TIME = 993
		val INVERTED = 999
	}

	//var skipping = true
	//var skipping = false
	var anmWip: WipView? = null
	var tbl: TBL? = null
	var tblMsk: WipView? = null
	val viewBackground = ViewContainer()
	val l1 = listOf(ViewContainer(), ViewContainer(), ViewContainer())
	val l2 = listOf(ViewContainer(), ViewContainer(), ViewContainer())
	val obj = listOf(ViewContainer(), ViewContainer(), ViewContainer())
	var lastText = ""
	var lastTitle = ""

	val ui = YumeIngameUi(g2, font.font).apply {
		y = 432.0
	}

	val back = ViewContainer().apply {
		this += viewBackground
		this += l1
		this += l2
		this += obj
	}

	val transition = TransitionView(g2)

	val view = ViewContainer().apply {
		this += transition
		this += ui
	}

	fun initAsync() = async<Unit> {
		ui.setWIP(loadWIPMSKAsync("WINBASE0").await())
	}

	fun loadWIPAsync(name: String): Promise<WipView> = async {
		//try {
		val bytes = gameAssets.chipArc["$name.WIP"].readBytesAsync().await()
		WipView(g2, bytes)
		//} catch (e: Throwable) {
		//	e.printStackTrace()
		//	WipView(g2, listOf(WIP.Entry(Bitmap32(1, 1), 0, 0)))
		//}
	}

	fun loadWIPMSKAsync(name: String): Promise<WipView> = async {
		val color = WIP.read(gameAssets.chipArc["$name.WIP"].readBytesAsync().await())
		val mask = WIP.read(gameAssets.chipArc["$name.MSK"].readBytesAsync().await())

		for (n in 0 until color.size) {
			(color[n].bitmap as Bitmap32).writeChannel(BitmapChannel.ALPHA, mask[n].bitmap as Bitmap8)
		}

		return@async WipView(g2, color)
	}

	fun loadMSKAsync(name: String): Promise<WipView> = async {
		val bytes = gameAssets.chipArc["$name.MSK"].readBytesAsync().await()
		WipView(g2, bytes)
	}

	class ScriptPoint(val script: String, val offset: Int)

	var scriptStream: Stream2 = ByteArray(0).open2("r")
	var scriptName = ""
	val scriptStack = Stack<ScriptPoint>()

	fun setScriptAsync(name: String): Promise<Unit> = async {
		println("SetScript: $name")
		scriptName = name
		scriptStream = WSC.Encryption.decrypt(gameAssets.rioArc[File(name).nameWithoutExtension + ".WSC"].readBytesAsync().await()).open2("r")
		scriptStream.position = 0
	}

	fun setScriptAsync(name: String, offset: Int) = async<Unit> {
		setScriptAsync(name).await()
		jump(offset)
	}

	fun jump(offset: Int) {
		scriptStream.position = offset.toLong()
	}

	fun read(): WSC.Instruction {
		return WSC.readInstruction(scriptStream, scriptName)
	}

	val methodsByOpcode = hashMapOf<WSC.Opcode, Method>()

	init {
		for (method in this.javaClass.declaredMethods) {
			val action = method.getAnnotation(WSC.Action::class.java) ?: continue
			methodsByOpcode[action.opcode] = method
		}
	}

	fun execOneAsync(): Promise<Unit> = async {
		val instruction = read()
		val method = methodsByOpcode[instruction.op]
		//instruction.
		try {
			if (TRACE) println("***$instruction")
			val result = method?.invoke(this@ScriptEvaluator, *instruction.params.toTypedArray())
			if (result is Promise<*>) {
				result.await()
			} else if (result == null) {
				println("!!!!UNHANDLED: $instruction")
			}
		} catch (e: Throwable) {
			println(method)
			println(instruction.params)
			for (param in instruction.params) {
				println(param.javaClass)
			}
			e.printStackTrace()
			throw e
		}
		Unit
	}

	// STATE
	var ingame = false
	var scriptId = -1
	val flags = IntArray(3000)

	private fun flags_set_range(start: Int, end: Int, value: Int) {
		for (n in start..end) flags[n] = value
	}

	init {
		flags_set_range(1051, 1067, 1); // ENABLE BGM

		flags_set_range(1100, 1108, 1); // ENABLE CG (PAGE 1)
		flags_set_range(1109, 1117, 1); // ENABLE CG (PAGE 2)
		flags_set_range(1118, 1126, 1); // ENABLE CG (PAGE 3)
		flags_set_range(1127, 1135, 1); // ENABLE CG (PAGE 4)
		flags_set_range(1136, 1144, 1); // ENABLE CG (PAGE 5)
		flags_set_range(1145, 1153, 1); // ENABLE CG (PAGE 6)
		flags_set_range(1154, 1162, 1); // ENABLE CG (PAGE 7)
		flags_set_range(1163, 1170, 1); // ENABLE CG (PAGE 8)

		flags_set_range(1200, 1270, 1); // AEKA
		flags_set_range(1271, 1339, 1); // KIRIMIYA
		flags_set_range(1340, 1403, 1); // NEKOKO
		flags_set_range(1404, 1412, 1); // MISC

		flags_set_range(1500, 1512, 1); // ENABLE EVENTS (AEKA)
		flags_set_range(1513, 1524, 1); // ENABLE EVENTS (KIRIMIYA)
		flags_set_range(1525, 1538, 1); // ENABLE EVENTS (NEKOKO)
		flags_set_range(1539, 1541, 1); // ENABLE EVENTS (AYA)
	}


	@WSC.Action(WSC.Opcode.SCRIPT) fun SCRIPT(name: String) = async<Unit> {
		setScriptAsync(name).await()
	}

	@WSC.Action(WSC.Opcode.INGAME_SET) fun INGAME_SET(value: Int) = async<Unit> {
		ingame = (value != 0)
	}

	@WSC.Action(WSC.Opcode.UNK_28) fun UNK_28(a: Int, b: Int) = async<Unit> {
	}

	@WSC.Action(WSC.Opcode.UNK_89) fun UNK_89(value: Int) = async<Unit> {
	}

	@WSC.Action(WSC.Opcode.UNK_68) fun UNK_68(a: Int, b: Int, c: Int, d: Int) = async<Unit> {
		println("UNK_68: $a, $b, $c, $d")
	}

	@WSC.Action(WSC.Opcode.UNK_55) fun UNK_55(v: Int) = async<Unit> {
	}

	@WSC.Action(WSC.Opcode.UNK_64) fun UNK_64(v: Int) = async<Unit> {
		println("UNK_64: $v")
	}

	@WSC.Action(WSC.Opcode.UNK_8E) fun UNK_8E(v: Int) = async<Unit> {
	}

	@WSC.Action(WSC.Opcode.JUMP_IF_NOT) fun INGAME_SET(op: WSC.OpsJump, kind: Int, flag: WSC.Flag, value: Int, label: WSC.Address) = async<Unit> {
		val actualValue = if (kind != 0) flags[value] else value

		//println("JUMP_IF: $op, $kind, $flag, $value, $label")
		if (!op.check(flags[flag.id], actualValue)) {
			if (TRACE) println(" --> JUMP ${"%08X".format(label.address)}")
			jump(label.address)
		}
	}

	@WSC.Action(WSC.Opcode.TEXT_SIZE) fun TEXT_SIZE(size: Int) = async<Unit> {
		ui.setTextSize(size)
	}

	@WSC.Action(WSC.Opcode.JUMP) fun JUMP(label: WSC.Address, unk: Int) = async<Unit> {
		jump(label.address)
	}

	@WSC.Action(WSC.Opcode.SET) fun SET(op: WSC.OpsSet, flag: WSC.Flag, kind: Int, value: Int) = async<Unit> {
		val rvalue = if (kind == 0) {
			value
		} else {
			// @TODO: check this!
			flags[value]
		}

		when (op) {
			WSC.OpsSet.RANGE -> {
				//println("RANGE: $flag, $kind, $value")
				for (n in 0 until 1000) {
					flags[n] = 0
				}
			}
			WSC.OpsSet.ASSIGN -> flags[flag.id] = rvalue
			WSC.OpsSet.INC -> flags[flag.id] += rvalue
			WSC.OpsSet.DEC -> flags[flag.id] -= rvalue
			WSC.OpsSet.REM -> flags[flag.id] %= rvalue
			else -> invalidOp("Unsupported operation $op")
		}
	}

	@WSC.Action(WSC.Opcode.EFFECT) fun EFFECT(a: Int, b: Int, c: Int, d: Int) = async<Unit> {
		println("EFFECT: $a, $b, $c, $d")
	}

	@WSC.Action(WSC.Opcode.MUSIC_STOP) fun MUSIC_STOP(a: Int, b: Int, c: Int) = async<Unit> {
	}

	@WSC.Action(WSC.Opcode.MUSIC_PLAY) fun MUSIC_PLAY(a: Int, b: Int, name: String) = async<Unit> {
	}

	private var voiceChannel: A1.Channel? = null
	private var soundChannel: A1.Channel? = null

	@WSC.Action(WSC.Opcode.VOICE_PLAY) fun VOICE_PLAY(a: Int, b: Int, c: Int, d: Int, name: String) = async<Unit> {
		if (!skipping) {
			voiceChannel?.stop()
			val sound = a1.createSound(gameAssets.voiceArc["$name.OGG"].readBytesAsync().await())
			voiceChannel = sound.play()
		}
	}

	@WSC.Action(WSC.Opcode.SOUND_PLAY) fun SOUND_PLAY(a: Int, b: Int, c: Int, d: Int, e: Int, f: Int, name: String) = async<Unit> {
		soundChannel?.stop()
		val sound = a1.createSound(gameAssets.seArc["$name"].readBytesAsync().await())
		soundChannel = sound.play()
		Unit
	}


	@WSC.Action(WSC.Opcode.SOUND_WAIT) fun SOUND_WAIT(value: Int) = async<Unit> {
		while (!skipping && (soundChannel?.isPlaying ?: false)) {
			view.waitSecondsAsync(0.1).await()
		}
		soundChannel?.stop()
		Unit
	}

	@WSC.Action(WSC.Opcode.SOUND_STOP) fun SOUND_STOP(value: Int) = async<Unit> {
		soundChannel?.stop()
		Unit
	}

	fun disposeTree(v: View) {
		if (v is ViewContainer) {
			for (c in v.children) disposeTree(c)
		}
		if (v is Disposable) {
			v.dispose()
		}
	}

	private fun clearLayer(v: ViewContainer) {
		disposeTree(v)
		v.removeChildren()
		v.x = 0.0
		v.y = 0.0
	}

	@WSC.Action(WSC.Opcode.CLEAR_L1) fun CLEAR_L1(index: Int) = async<Unit> {
		clearLayer(l1[index])
	}

	@WSC.Action(WSC.Opcode.CLEAR_L2) fun CLEAR_L2(index: Int) = async<Unit> {
		clearLayer(l2[index])
	}

	@WSC.Action(WSC.Opcode.OBJ_CLEAR) fun OBJ_CLEAR(index: Int) = async<Unit> {
		clearLayer(obj[index])
	}

	@WSC.Action(WSC.Opcode.CHARA_PUT) fun CHARA_PUT(index: Int, x: Int, y: Int, d: Int, e: Int, f: Int, name: String) = async<Unit> {
		val wip = loadWIPMSKAsync(name).await()
		clearLayer(l1[index])
		wip.x = x.toDouble()
		wip.y = y.toDouble()
		l1[index] += wip
	}

	@WSC.Action(WSC.Opcode.OBJ_PUT) fun OBJ_PUT(index: Int, x: Int, y: Int, d: Int, e: Int, name: String) = async<Unit> {
		val wip = loadWIPMSKAsync(name).await()
		clearLayer(obj[index])
		wip.x = x.toDouble()
		wip.y = y.toDouble()
		obj[index] += wip
	}

	@WSC.Action(WSC.Opcode.BACKGROUND) fun BACKGROUND(x: Int, y: Int, unk1: Int, unk2: Int, index: Int, name: String) = async<Unit> {
		clearLayer(viewBackground)

		val wip = loadWIPAsync(name).await()

		viewBackground += wip
		viewBackground.x = x.toDouble()
		viewBackground.y = y.toDouble()
		//waitAsync(5000).await()
	}

	@WSC.Action(WSC.Opcode.TRANS_IMAGE) fun TRANS_IMAGE(image: String) = async<Unit> {
		val msk = loadMSKAsync(image).await()
		transition.setMask(msk.entries[0].bitmap.toBMP32())
		msk.dispose()
	}

	@WSC.Action(WSC.Opcode.TRANSITION) fun TRANSITION(kind: Int, ms: Int) = async<Unit> {
		val finalTime = msToSeconds(ms)
		println("TRANSITION: $kind, $ms, $finalTime")
		transition.drawBack(back)
		if (flags[COMMON_FLAGS.INVERTED] != 0) {
			transition.invert()
		}
		transition.transitionType = when (kind) {
			25 -> TransitionView.Type.MASK
			42 -> TransitionView.Type.MASK_REVERSE
			else -> TransitionView.Type.ALPHA
		}
		transition.tweenThisAsync(TransitionView::step..(0.0..1.0), time = finalTime).await()
		transition.copyBackToFront()
	}

	val skipping: Boolean get() = backend.keys.keyPressed(Keys.CONTROL)

	private fun textInternalAsync(body: String, title: String): Promise<Unit> = async {
		ui.setText(body, title)
		//println(text.str)
		lastText = body
		lastTitle = title
		//println(backend.keys.keys)
		if (skipping) {
			view.waitSecondsAsync(ticksToSeconds(1)).await()
		} else {
			Promise.any(
				backend.keys.onKeyDown.waitOneAsync().unit,
				backend.mouse.onMouseUp.waitOneAsync().unit
			).await()
		}
		voiceChannel?.stop()
		Unit
	}

	@WSC.Action(WSC.Opcode.TEXT) fun TEXT(a: Int, b: Int, text: WSC.Text) = async<Unit> {
		textInternalAsync(text.str, "").await()
	}

	@WSC.Action(WSC.Opcode.TEXT_ADD) fun TEXT_ADD(id: Int, str: WSC.Text) = async<Unit> {
		textInternalAsync(lastText + str.str, lastTitle).await()
	}

	@WSC.Action(WSC.Opcode.TEXT_WITH_TITLE) fun TEXT_WITH_TITLE(id: Int, title: WSC.Text, text: WSC.Text) = async<Unit> {
		textInternalAsync(text.str, title.str).await()
	}

	@WSC.Action(WSC.Opcode.INGAME_SCRIPT_ID) fun INGAME_SCRIPT_ID(id: Int) = async<Unit> {
		scriptId = id
	}

	@WSC.Action(WSC.Opcode.SCRIPT_CALL) fun SCRIPT_CALL(name: String) = async<Unit> {
		scriptStack.push(ScriptPoint(scriptName, scriptStream.position.toInt()))
		setScriptAsync(name).await()
	}

	@WSC.Action(WSC.Opcode.SCRIPT_RET) fun SCRIPT_RET(p: Int) = async<Unit> {
		val point = scriptStack.pop()
		setScriptAsync(point.script, point.offset).await()
	}

	@WSC.Action(WSC.Opcode.EOF) fun EOF() = async<Unit> {
		invalidOp("EOF!")
	}

	@WSC.Action(WSC.Opcode.OPTION_SELECT) fun OPTION_SELECT(itemsRaw: List<List<Any>>) = async<Unit> {
		data class Item(val id: Int, val text: WSC.Text, val unk: Int, val unk2: Int, val script: String)

		val items = itemsRaw.map { Item(it[0] as Int, it[1] as WSC.Text, it[2] as Int, it[3] as Int, it[4] as String) }
		val selectedItem = items[0]
		println("SELECTED: $selectedItem")
		setScriptAsync(selectedItem.script).await()
	}

	class Animation(val layer: View, val x: Double, val y: Double, val time: Double)

	val animations = arrayListOf<Animation>()

	@WSC.Action(WSC.Opcode.ANIMATE_START) fun ANIMATE_START(unk: Int) = async<Unit> {
		println("ANIMATE_START")
		animations.clear()
	}

	@WSC.Action(WSC.Opcode.ANIMATE_ADD) fun ANIMATE_ADD(id: Int, x: Int, y: Int, time: Int, unk1: Int, unk2: Int, unk3: Int) = async<Unit> {
		println("ANIMATE_ADD")

		val layer = if (id == 0) {
			this@ScriptEvaluator.viewBackground
		} else {
			this@ScriptEvaluator.l2[id - 1]
		}

		animations += Animation(layer, x.toDouble(), y.toDouble(), time / 1000.0)
	}

	@WSC.Action(WSC.Opcode.ANIMATE_PLAY) fun ANIMATE_PLAY(unk: Int) = async<Unit> {
		println("ANIMATE_PLAY")

		fun callback(step: Double) {
			//println(step)
			transition.drawBack(back)
			transition.copyBackToFront()
		}

		val promises = animations.map {
			//val view: View = it.layer
			view.tweenTargetAsync(it.layer, View::x..it.x, View::y..it.y, time = it.time, callback = {
				callback(it)
			})
		}

		for (p in promises) {
			p.await()
		}
	}

	@WSC.Action(WSC.Opcode.WAIT) fun WAIT(ms: Int, unk0: Int) = async<Unit> {
		view.waitSecondsAsync(msToSeconds(ms)).await()
	}

	// MENUS

	var timer = 0

	@WSC.Action(WSC.Opcode.TIMER_SET) fun TIMER_SET(count: Int) = async<Unit> {
		timer = count
	}

	@WSC.Action(WSC.Opcode.TIMER_DEC) fun TIMER_GET(flag: Int, unk: Int) = async<Unit> {
		if (timer > 0) timer--
		flags[flag] = if (timer <= 0) 1 else 0
	}

	@WSC.Action(WSC.Opcode.TABLE) fun TABLE(table: String) = async<Unit> {
		val tbl = TBL.read(gameAssets.chipArc["$table.TBL"].readStreamAsync().await())
		this@ScriptEvaluator.tbl = tbl
		tblMsk = loadMSKAsync(tbl.mask).await()

		println("TABLE: $table: $tbl, ${tbl.count}, ${tbl.enableFlags}, ${tbl.mask}")
		for (y in 0 until tbl.keyMap.height) {
			for (x in 0 until tbl.keyMap.width) {
				print("${tbl.keyMap[x, y]}")
			}
			println()
		}
	}

	var lastPressing = false
	var keyOptionIndex = 0

	@WSC.Action(WSC.Opcode.TABLE_SELECT) fun TABLE_SELECT(flagMaskClick: WSC.Flag, flagMaskOver: WSC.Flag, unk1: Int) = async<Unit> {
		flags[flagMaskClick.id] = 0
		flags[flagMaskOver.id] = keyOptionIndex
		val pressingUp = backend.keys.keyPressed(Keys.UP)
		val pressingDown = backend.keys.keyPressed(Keys.DOWN)
		val pressingReturn = backend.keys.keyPressed(Keys.RETURN)

		val pointer = backend.mouse.pointers[0]

		//println("${pointer.x},${pointer.y}")
		if (tblMsk != null) {
			val bmp = tblMsk!!.entries[0].bitmap as Bitmap8
			val value = bmp[pointer.x, pointer.y]
			//println("--->$value")
			if (flags[tbl!!.enableFlags[value]] != 0) {
				flags[flagMaskOver.id] = value
				flags[flagMaskClick.id] = if (pointer.getButton(0)) 1 else 0
			}
		}

		if (!lastPressing) {
			val prevKeyOptionIndex = keyOptionIndex
			if (pressingUp) keyOptionIndex--
			if (pressingDown) keyOptionIndex++
			if (flags[tbl!!.enableFlags[keyOptionIndex]] != 0) {
				keyOptionIndex = prevKeyOptionIndex
			}
			if (pressingReturn) {
				flags[flagMaskClick.id] = 1
			}
		}

		lastPressing = pressingUp || pressingDown || pressingReturn

		//flags[867] = 0

		//flags[867] = 0

		//flags[flagMaskClick.id] = 5
		//flags[flagMaskOver.id] = -1

		//println("TABLE_SELECT: $flagMaskClick, $flagMaskOver, $unk1")
		view.waitSecondsAsync(ticksToSeconds(1)).await()
	}

	@WSC.Action(WSC.Opcode.ANIM_LOAD) fun ANIM_LOAD(a: Int, b: Int, anim: String) = async<Unit> {
		val anm = ANM.read(gameAssets.chipArc["$anim.ANM"].readStreamAsync().await())
		//loadWIPAsync(anim).await()
		val wipView = loadWIPAsync(anm.wipName).await()
		anmWip = wipView
		clearLayer(obj[0])
		obj[0] += wipView
		for (n in 1 until wipView.images.size) {
			wipView.images[n].visible = false
		}
		println(anm.map)
		println("ANIM_LOAD! ${anm.wipName}")
		println(anm)
	}

	@WSC.Action(WSC.Opcode.TABLE_ANIM_OBJECT_PUT) fun TABLE_ANIM_OBJECT_PUT(unk1: Int, index: Int, unk2: Int) = async<Unit> {
		//println("TABLE_ANIM_OBJECT_PUT: $index")
		anmWip?.images?.get(index + 1)?.visible = true
		transition.drawBack(back)
		transition.copyBackToFront()
	}

	@WSC.Action(WSC.Opcode.TABLE_ANIM_OBJECT_UNPUT) fun TABLE_ANIM_OBJECT_UNPUT(unk1: Int, index: Int, unk2: Int) = async<Unit> {
		//println("TABLE_ANIM_OBJECT_UNPUT: $index")
		anmWip?.images?.get(index + 1)?.visible = false
		transition.drawBack(back)
		transition.copyBackToFront()
	}
}
	*/