package com.talestra.tod

/*
class PAK(
	private val p: Stream2,
	private val d: Stream2,
	private val load: Boolean = true
) : Iterable<Stream2> {
	@Struct(size = 8) private data class Pointer(
		@Element(offset = 0) val pos: Int,
		@Element(offset = 4) val len: Int
	) {
		val end: Int get() = pos + len
	}

	private val pointers = arrayListOf<Pointer>()

	init {
		if (load) loadBasePointers()
	}

	fun close() {
		p.close()
		d.close()
	}

	fun loadBasePointers() {
		pointers.clear()

		try {
			while (!p.eof) {
				pointers += Pointer(p.readS32_le(), p.readS32_le())
			}
		} catch(e: Throwable) {
		}
	}

	override fun iterator(): Iterator<Stream2> = generate<Stream2> {
		for (pointer in pointers) yield(extractFile(pointer))
	}

	operator fun get(index: Int): Stream2 = extractFile(index)

	val length: Int get() = pointers.size

	fun extractFile(id: Int): Stream2 {
		assert((id >= 0) && (id < pointers.size)) { "Invalid ID" }
		return SliceStream2(d, pointers[id].pos, pointers[id].end)
	}

	private fun extractFile(pointer: Pointer): Stream2 = SliceStream2(d, pointer.pos, pointer.end)

	fun addFileDummy() {
		p.writeU32(0)
		p.writeU32(0)
	}

	fun addFile(f: Stream2) {
		while ((d.position % 0x800L) != 0L) d.writeU8(0)
		val pos = d.position
		p.writeU32(pos)
		d.copyFrom(f)
		while ((d.position % 0x800L) != 0L) d.writeU8(0)
		p.writeU32(d.position - pos)
	}
}
*/