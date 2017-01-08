package com.talestra.games.edelweiss

import com.talestra.rhcommon.text.unescape
import com.talestra.rhcommon.translations.PO

object EdTexts {
	val TEXT_REGEX = Regex("^<(\\w+)>(.*)$")

	fun read(file: String): List<PO.Entry> {
		val fileComments = arrayListOf<String>()
		val comments = arrayListOf<String>()
		var id = ""
		val texts = hashMapOf<String, String>()
		var mustFlush = false

		val out = arrayListOf<PO.Entry>()

		fun flushFile() {
			out += PO.Entry("", null, listOf(
				listOf(
					"Language: es\n",
					"Content-Type: text/plain; charset=UTF-8\n"
				).joinToString("")
			), fileComments)
		}

		fun flush() {
			if (id.isNotEmpty()) {
				out += PO.Entry(texts["en"] ?: "", null, listOf(texts["es"] ?: ""), comments + listOf(": $id"))
			}
			texts.clear()
			id = "-"
			comments.clear()
			mustFlush = false
		}

		for (rline in file.lines()) {
			val line = rline.trim()

			if (line.startsWith("#") || line.startsWith("@")) {
				if (mustFlush) {
					flush()
				}
				if (line.startsWith("#")) {
					comments += " " + line.substring(1).trim()
				} else {
					// File comments
					if (id == "") {
						fileComments += comments
						comments.clear()
						flushFile()
					}
					id = line.substring(1).trim()
				}
			} else if (line.startsWith("<")) {
				val (_, lang, text) = TEXT_REGEX.find(line)?.groupValues ?: throw IllegalArgumentException("Invalid text line '$line'")
				texts[lang] = text.unescape()
				mustFlush = true
			}
		}
		flush()
		return out
	}
}