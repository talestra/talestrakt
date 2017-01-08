package com.talestra.criminalgirls

import com.soywiz.korim.bitmap.Bitmap8
import com.soywiz.korim.format.PNG
import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.async.sync
import com.soywiz.korio.stream.*
import com.soywiz.korio.vfs.ResourcesVfs
import com.soywiz.korio.vfs.VfsFile
import com.soywiz.korio.vfs.VfsOpenMode
import com.talestra.rhcommon.lang.invalidOp
import com.talestra.rhcommon.text.StrReader
import com.talestra.rhcommon.translations.PO
import java.util.*

object Translation {
    val resources = ResourcesVfs["com/talestra/criminalgirls"]

    data class CharMap(val from: Char, val to: Char, val width: Int)

    suspend fun translate(mod: AsyncStream) = asyncFun {
        val root = PS3FS.read(mod)

        patchImage(root, "bt_ui05.0000.imy")
        patchImage(root, "bt_ui_07.0000.imy")
        patchImage(root, "order_ui00.0000.imy")
        patchImage(root, "bt_ui_00.0000.imy")
        patchImage(root, "bt_ui_07.0001.imy")
        patchImage(root, "st_ui01.0000.imy")
        patchImage(root, "bt_ui_00.0001.imy")
        patchImage(root, "ev_ui_00.0000.imy")
        patchImage(root, "st_ui05.ptm.imy")
        patchImage(root, "bt_ui_00.0002.imy")
        patchImage(root, "fl_ui03.imy")
        patchImage(root, "title.0001.imy")
        patchImage(root, "bt_ui_01.0000.imy")
        patchImage(root, "bt_ui_02.0000.imy")
        patchImage(root, "omake.0000.imy")
        patchImage(root, "bt_ui_06.0000.imy")
        patchImage(root, "option.0000.imy")

        updateFontDatWidths(root)
        patchImage(root, "font_00.imy")
        translateText(root)
    }

    val charMapList by lazy {
        sync { resources["font/font.map.tbl"].readString() }.lines().map {
            val parts = it.split(',')
            CharMap(parts[0][0], parts[1][0], parts[2].toInt())
        }
    }
    val charMap by lazy { charMapList.associate { it.from to it.to } }

    suspend fun patchImage(root: VfsFile, original: String) = asyncFun {
        patchImage(root, "$original.png", original)
    }

    suspend fun patchImage(root: VfsFile, png: String, original: String) = asyncFun {
        val ss = root[original]!!.open(VfsOpenMode.WRITE).slice()
        print("Patching '$original'... ${ss.getLength()}")
        val ORIGINAL = IMY.decode(ss.slice().readAll())
        val ORIGINAL_HAS_PALETTE = ORIGINAL is Bitmap8
        val TRANSLATED = PNG.read(resources["images/$png"].read());
        val TRANSLATED_HAS_PALETTE = TRANSLATED is Bitmap8

        if (ORIGINAL_HAS_PALETTE != TRANSLATED_HAS_PALETTE) {
            invalidOp("Palette mismatch! Original image palette:$ORIGINAL_HAS_PALETTE, Translated image palette:$TRANSLATED_HAS_PALETTE")
        }

        val encoded = IMY.encode(TRANSLATED)
        print(" -> ${encoded.size}")
        if (encoded.size > ss.getLength()) invalidOp("Font size is bigger than original! That would require reconstruct the whole DAT file!")
        ss.writeBytes(encoded)
        println("...Ok")
    }

    suspend fun updateFontDatWidths(root: VfsFile) = asyncFun {
        val file = root["font.bin"]

        val map = charMapList.associate { it.to to it }

        val chars = FONT_WIDTHS.read(file.read().openSync())

        for (c in chars) {
            val cc = map[c.char]
            if (cc != null) {
                val ss = c.slice.sliceWithStart(2)
                ss.write8(0)
                ss.write8(cc.width)
            }
        }
    }

    suspend fun translateText(root: VfsFile) = asyncFun {
        val charMap = this.charMap
        for (file in root.listRecursive()) {
            val name = file.basename
            try {
                if (file.extension.toLowerCase() == "tpk") {
                    for (file in file.openAsDsarCidx().listRecursive()) {
                        val name2 = file.basename
                        val dsar = file.read().openSync()
                        if (BSCR.check(dsar)) {
                            val script = BSCR.read(dsar)

                            val out = arrayListOf<String>()

                            val translationFile = "$name@$name2@${script.name}.po"

                            val translations = PO.read(resources["text/$translationFile"].readString())

                            println(name)

                            val trans2 = hashMapOf<String, String>()

                            fun String.transformChars(): String {
                                var oo = ""
                                for (c in this) oo += charMap[c] ?: c
                                return oo
                            }

                            for (t in translations.filter { it.references.isNotEmpty() }) {
								val text_id = t.references.first()
								val trans = t.msgstrList.first()
								trans2[text_id] = trans.transformChars()
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