package com.talestra.dividead.play

class State {
	val script = "AASTART"
	var title = ""
	var background = ""
	var foreground = ""
	val flags = IntArray(1024)
	val options = arrayListOf<Option>()
	val optionsMap = arrayListOf<MapOption>()
}