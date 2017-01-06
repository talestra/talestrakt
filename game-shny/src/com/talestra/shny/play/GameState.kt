package com.talestra.shny.play

import com.talestra.rhcommon.inject.Singleton

@Singleton class GameState {
	class Chara(val id: Int) {
		var suit: Int = 0
	}

	val flags = IntArray(1024)
	val chars = (0 until 10).map { Chara(it) }
}