package com.talestra.rhcommon

import com.talestra.rhcommon.text.explode

object ACME {
	class Entry(
		val id: Int,
		val text: String,
		val attribs: Map<String, String>,
		val attrib_names: List<String>
	) {
		override fun toString(): String {
			var r = ""
			r += "## POINTER $id"
			if (attribs.isNotEmpty()) {
				r += " ["
				var nfirst = true
				for (key in attrib_names) {
					if (nfirst) r += ";"
					r += key
					r += ":"
					r += attribs[key]
					nfirst = true
				}
				r += "]"
			}
			r += "\n"
			r += text
			r += "\n\n"
			return r
		}
	}

	fun get(acme: String): Map<Int, Entry> {
		val r = hashMapOf<Int, Entry>()
		//char[][] pointers = explode("## POINTER ", acme);
		val pointers = acme.split("## POINTER ")
		if (pointers.size > 1) {
			for (pointer in pointers.drop(1)) {
				//printf("%s", toStringz(cast(char[])pointer));
				val part = explode("\n", pointer, 2)
				if (part.size < 2) continue

				val id = part[0].toInt()

				val attribs = hashMapOf<String, String>()
				val attrib_names = arrayListOf<String>()

				val atr2 = explode("[", part[0], 2)
				//writefln("'%s'", part[0]);
				if (atr2.size >= 2) {
					val atr3 = explode("]", atr2[1], 2)
					for (atr4 in explode(";", atr3[0])) {
						val zz = explode(":", atr4, 2)
						if (zz.size >= 2) {
							attribs[zz[0]] = zz[1]
							attrib_names += zz[0]
						} else {
							//writefln(atr4);
							throw RuntimeException("error")
						}
					}
				}

				r[id] = Entry(
					id = id,
					text = part[1].trim(),
					attribs = attribs,
					attrib_names = attrib_names
				)
				//writefln(id);
			}
		}
		return r
	}
}
