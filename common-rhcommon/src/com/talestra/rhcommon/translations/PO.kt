package com.talestra.rhcommon.translations

import com.talestra.rhcommon.text.unquote

// https://www.gnu.org/software/gettext/manual/html_node/PO-Files.html
object PO {
	data class Entry(
		val msgid: String,
		val msgid_plural: String? = null,
		val msgstrList: List<String> = listOf(),
		val comments: List<String> = listOf()
	) {
		val references = comments.filter {
			it.startsWith(':')
		}.map {
			it.substring(1).trim()
		}
	}

	private val REGEX_ID_LINE = Regex("^(\\w+)(\\[(\\d+)\\])?\\s*(\".*\")$")

	fun read(s: String): List<Entry> {
		val out = arrayListOf<Entry>()
		var buildType = ""
		var buildIndex: Int = 0
		var buildStr = ""

		var msgid = ""
		var msgid_plural = ""
		var msgstrList = arrayListOf<String>()
		var comments = ""

		fun tryflush(newBuildType: String, newBuildIndex: Int) {
			if (buildType != "" && (buildType != newBuildType || buildIndex != newBuildIndex)) {
				when (buildType) {
					"msgid" -> msgid = buildStr
					"msgid_plural" -> msgid_plural = buildStr
					"comments" -> comments = buildStr
					"msgstr" -> {
						while (msgstrList.size <= buildIndex) msgstrList.add("")
						msgstrList[buildIndex] = buildStr
					}
					"" -> Unit
					else -> throw IllegalStateException("newBuildType: $newBuildType")
				}

				buildStr = ""

				if (newBuildType != "msgstr" && buildType == "msgstr") {
					out += Entry(msgid, if (msgid_plural.isEmpty()) null else msgid_plural, msgstrList, if (comments.isEmpty()) listOf() else comments.trimEnd().lines())
					msgid = ""
					msgid_plural = ""
					msgstrList = arrayListOf<String>()
					comments = ""
				}
			}

			buildType = newBuildType
			buildIndex = newBuildIndex
		}

		for (rline in s.lines()) {
			val line = rline.trim()
			if (line.startsWith('#')) {
				tryflush("comments", 0)
				buildStr += line.substring(1) + "\n"
			}
			val res = REGEX_ID_LINE.find(line)
			if (res != null) {
				val (_, kind, _, index, text) = res.groupValues
				tryflush(kind, index.toIntOrNull() ?: 0)
				buildStr += text.unquote()
			}
			if (line.startsWith('"')) {
				buildStr += line.trim().unquote()
			}
		}
		tryflush("", 0)
		return out
	}

	fun String.escapePo(): String {
		var out = ""
		for (c in this) {
			when (c) {
				'\n' -> out += "\\n"
				'\r' -> out += "\\r"
				'\t' -> out += "\\t"
				'"' -> out += "\\\""
				'\\' -> out += "\\\\"
				else -> out += c
			}
		}
		return out
	}

	fun String.quotePo(): String = "\"" + this.escapePo() + "\""

	fun generate(entries: List<Entry>): String {
		val out = arrayListOf<String>()

		fun gen1(type: String, str: String) {
			val lines3 = str.split('\n')
			val lines2 = lines3.withIndex().map { if (it.index == lines3.lastIndex) it.value else "${it.value}\n" }.filter { it.isNotEmpty() }
			val lines = if (lines2.size != 1) listOf("") + lines2 else lines2
			var first = true
			for (line in lines) {
				if (first) {
					first = false
					out += type + " " + line.quotePo()
				} else {
					out += line.quotePo()
				}
			}
		}

		for (e in entries) {
			for (c in e.comments) out += "#$c"
			gen1("msgid", e.msgid)
			if (e.msgid_plural != null) gen1("msgid_plural", e.msgid_plural)
			if (e.msgstrList.size == 1) {
				gen1("msgstr", e.msgstrList[0])
			} else {
				for ((i, str) in e.msgstrList.withIndex()) gen1("msgstr[$i]", str)
			}
			out += ""
		}

		return out.joinToString("\n")
	}
}