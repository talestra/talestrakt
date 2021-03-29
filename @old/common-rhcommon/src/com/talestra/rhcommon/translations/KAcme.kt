package com.talestra.rhcommon.translations

import com.soywiz.korio.util.StrReader
import com.talestra.rhcommon.text.readQuotedString

object KAcme {
	fun read(translations: List<String>): List<PO.Entry> {
		val out = arrayListOf<PO.Entry>()
		out += PO.Entry(msgid = "", msgstrList = listOf(
			listOf(
				"Language: es\n",
				"Content-Type: text/plain; charset=UTF-8\n"
			).joinToString("")
		))
		for (t in translations) {
			val s = StrReader(t)
			val text_id = s.readWhile { it != ':' }
			s.expect(':')
			val original = s.readQuotedString()
			s.expect(':')
			val trans = s.readQuotedString()
			out += PO.Entry(
				msgid = original,
				msgstrList = listOf(if (trans == original) "" else trans),
				comments = listOf(
					": $text_id"
				)
			)
		}
		return out
	}
}