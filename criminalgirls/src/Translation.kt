import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.stream.AsyncStream
import java.util.*

object Translation {
	data class CharMap(val from: Char, val to: Char, val width: Int)

	suspend fun translate(mod: AsyncStream) = asyncFun {
		val files = PS3FS.read(mod)

		patchImage(files, "bt_ui05.0000.imy")
		patchImage(files, "bt_ui_07.0000.imy")
		patchImage(files, "order_ui00.0000.imy")
		patchImage(files, "bt_ui_00.0000.imy")
		patchImage(files, "bt_ui_07.0001.imy")
		patchImage(files, "st_ui01.0000.imy")
		patchImage(files, "bt_ui_00.0001.imy")
		patchImage(files, "ev_ui_00.0000.imy")
		patchImage(files, "st_ui05.ptm.imy")
		patchImage(files, "bt_ui_00.0002.imy")
		patchImage(files, "fl_ui03.imy")
		patchImage(files, "title.0001.imy")
		patchImage(files, "bt_ui_01.0000.imy")
		patchImage(files, "bt_ui_02.0000.imy")
		patchImage(files, "omake.0000.imy")
		patchImage(files, "bt_ui_06.0000.imy")
		patchImage(files, "option.0000.imy")

		updateFontDatWidths(files)
		patchImage(files, "font_00.imy")
		translateText(files)
	}

	val charMapList by lazy {
		Translation.getResourceBytes("font.map.tbl").toString(Charsets.UTF_8).lines().map {
			val parts = it.split(',')
			CharMap(parts[0][0], parts[1][0], parts[2].toInt())
		}
	}
	val charMap by lazy { charMapList.associate { it.from to it.to } }

	fun patchImage(files: Map<String, Stream2>, original: String) {
		patchImage(files, "$original.png", original)
	}

	fun patchImage(files: Map<String, Stream2>, png: String, original: String) {
		val ss = files[original]!!.slice()
		print("Patching '$original'... ${ss.length}")
		val ORIGINAL = IMY.decode(ss.slice().readAll())
		val ORIGINAL_HAS_PALETTE = ORIGINAL is Bitmap8
		val TRANSLATED = PNG.read(Translation.getResourceBytes(png));
		val TRANSLATED_HAS_PALETTE = TRANSLATED is Bitmap8

		if (ORIGINAL_HAS_PALETTE != TRANSLATED_HAS_PALETTE) {
			invalidOp("Palette mismatch! Original image palette:$ORIGINAL_HAS_PALETTE, Translated image palette:$TRANSLATED_HAS_PALETTE")
		}

		val encoded = IMY.encode(TRANSLATED)
		print(" -> ${encoded.size}")
		if (encoded.size > ss.length) invalidOp("Font size is bigger than original! That would require reconstruct the whole DAT file!")
		ss.writeBytes(encoded)
		println("...Ok")
	}

	fun updateFontDatWidths(files: Map<String, Stream2>) {
		val file = files["font.bin"]!!

		val map = charMapList.associate { it.to to it }

		val chars = FONT_WIDTHS.read(file.slice())

		for (c in chars) {
			val cc = map[c.char]
			if (cc != null) {
				val ss = c.slice.slice(2)
				ss.writeU8(0)
				ss.writeU8(cc.width)
			}
		}
	}

	fun translateText(files: Map<String, Stream2>) {
		val charMap = this.charMap
		for ((name, data) in files) {
			try {
				if (name.endsWith(".tpk")) {
					for ((name2, dsar) in DSARCIDX.read(data)) {
						if (BSCR.check(dsar)) {
							val script = BSCR.read(dsar.slice())

							val out = arrayListOf<String>()

							val translationFile = "$name@$name2@${script.name}.txt"

							val translations = getResourceBytes("text/$translationFile").toString(Charsets.UTF_8).lines()

							println("$name")

							val trans2 = hashMapOf<String, String>()

							fun String.transformChars(): String {
								var oo = ""
								for (c in this) oo += charMap[c] ?: c
								return oo
							}

							for (t in translations) {
								val s = StrReader(t)
								val text_id = s.readWhile { it != ':' }
								s.expect(':')
								s.readQuotedString()
								s.expect(':')
								val trans = s.readQuotedString()
								trans2[text_id] = trans.transformChars()
								//println("$function_index @ $ori  @ $trans")
							}

							//println(translations)

							val uniqueTexts = LinkedHashSet<String>()
							for (f in script.funcs) {
								for ((n, i) in f.ins.withIndex()) {
									if (i is BSCR.II.PushString) {
										if (i.str != " ") {
											val text_id = "${f.name}@$n"
											val trans = trans2[text_id]
											if (trans != null && i.str != trans) {
												//println("Translated: ${i.str} -> $trans")
												i.str = trans
											}
										}
										uniqueTexts += i.str
										//out += "${f.name}@$n:\"${i.str.escape()}\":\"${i.str.escape()}\""
									}
								}
							}

							if (uniqueTexts.isNotEmpty()) {
								script.strings = uniqueTexts.toList()

								//dsar.size

								val original = dsar.slice().readAll()
								val modified = script.gen()

								if (modified.size > original.size) {
									invalidOp("Modified size should be equal or smaller than original!")
								}

								//if (modified.size != original.size) println("${modified.size} != ${original.size}")

								dsar.slice().writeBytes(modified)

								//if (Arrays.equals(original, modified)) {
								//	println("${dsar.length} -> ${script.gen().size}")
								//}
								//val crim2 = File("c:/temp/crim2")
								//crim2.mkdirs()
								//File(crim2, "$name@$name2@${script.name}.txt").writeBytes(out.joinToString("\n").toByteArray(Charsets.UTF_8))
							}
						}
					}
				}
			} catch (t: Throwable) {
				t.printStackTrace()
			}
		}
	}
}