package com.talestra.rhcommon.translations

import org.junit.Assert
import org.junit.Test

class POTest {
	val TEST_PO1 = """
		msgid ""
		msgstr ""
		"Language: es\n"
		"Content-Type: text/plain; charset=UTF-8\n"

		# no estoy seguro
		#: demo@1
		msgid "test"
		msgstr "prueba"

		#: demo@2
		msgid "test2"
		msgstr "prueba 2"

		#: demo@3
		msgid "test3"
		msgstr "prueba 3áé"

		#: demo@5
		msgid "test"
		msgid_plural "tests"
		msgstr[0] "prueba"
		msgstr[1] ""
		"pruebas\n"
		"multilinea"

		#: demo@4
		msgid "test"
		msgstr ""
		"prueba en otro contexto\n"
		"demo\n"

	""".trimIndent().replace("\r\n", "\n")

	@Test
	fun name() {
		val entries = PO.read(TEST_PO1)
		for (entry in entries) {
			println(entry)
		}

		Assert.assertEquals(TEST_PO1, PO.generate(entries))
	}
}