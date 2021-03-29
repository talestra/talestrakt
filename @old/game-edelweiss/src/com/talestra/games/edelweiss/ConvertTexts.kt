package com.talestra.games.edelweiss

import com.soywiz.korio.async.EventLoop
import com.soywiz.korio.vfs.ResourcesVfs
import com.talestra.rhcommon.translations.PO

fun main(args: Array<String>) = EventLoop.main {
	val root = ResourcesVfs["com/talestra/edelweiss"]
	val texts = EdTexts.read(root["text/007a6.txt"].readString())
	println(PO.generate(texts))
}