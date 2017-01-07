import com.jtransc.JTranscSystem
import com.jtransc.target.Js
import com.soywiz.korim.bitmap.Bitmap
import com.soywiz.korim.bitmap.Bitmap32
import com.soywiz.korim.bitmap.Bitmap8
import com.soywiz.korim.color.RGBA
import com.soywiz.korio.async.asyncFun
import com.soywiz.korio.stream.*
import com.soywiz.korio.vfs.VfsFile
import com.talestra.rhcommon.lang.invalidOp
import com.talestra.yume.formats.WillLZ

object WIP {
    const val MAGIC = 0x46504957

    private data class HEADER(
            val magic: Int,
            val count: Int,
            val bpp: Int
    ) {
        constructor(s: SyncStream) : this(magic = s.readS32_le(), count = s.readS16_le(), bpp = s.readS16_le())

        init {
            if (magic != MAGIC) invalidOp("Not a WIP file 0x%08X".format(magic))
        }

        val bytes = bpp / 8
    }

    data class Entry(val bitmap: Bitmap, val x: Int, val y: Int)

    private data class ENTRY_HEADER(
            val w: Int,
            val h: Int,
            val x: Int,
            val y: Int,
            val unknown: Int,
            val compressed: Int
    ) {
        constructor(s: SyncStream) : this(
                w = s.readS32_le(),
                h = s.readS32_le(),
                x = s.readS32_le(),
                y = s.readS32_le(),
                unknown = s.readS32_le(),
                compressed = s.readS32_le()
        )

        val area = w * h
    }

    private fun SyncStream.write(h: HEADER) {
        write32_le(h.magic)
        write16_le(h.count)
        write16_le(h.bpp)
    }

    private fun SyncStream.write(h: ENTRY_HEADER) {
        write32_le(h.w)
        write32_le(h.h)
        write32_le(h.x)
        write32_le(h.y)
        write32_le(h.unknown)
        write32_le(h.compressed)
    }

    fun read(s: ByteArray): List<Entry> = read(s.openSync())

    suspend fun read(s: VfsFile): List<Entry> = asyncFun { read(s.readAsSyncStream()) }

    fun read(s: SyncStream): List<Entry> {
        val header = HEADER(s)
        val entries: List<ENTRY_HEADER> = (0 until header.count).map { ENTRY_HEADER(s) }
        val result = entries.map { entry ->
            val palette = if (header.bpp == 8) s.readIntArray_le(0x100) else intArrayOf()
            val compressed = s.readBytes(entry.compressed)
            val uncompressed = ByteArray(entry.area * header.bytes)
            WillLZ.decompress(compressed, uncompressed)
            val img = when (header.bpp) {
                8 -> {
                    Bitmap8(entry.w, entry.h, uncompressed, palette)
                }
                24 -> {
                    Bitmap32(entry.w, entry.h).apply {
                        if (JTranscSystem.isJs()) {
                            readBmp32Js(uncompressed, data, entry.area)
                        } else {
                            readBmp32(uncompressed, data, entry.area)
                        }
                    }
                }
                else -> invalidOp("Not supported bpp: ${header.bpp}")
            }
            Entry(img, entry.x, entry.y)
        }
        return result
    }

    private fun readBmp32Js(uncompressed: ByteArray, data: IntArray, area: Int) {
        Js.v_raw("""
			var uncompressed = new Uint8Array(p0.getBuffer());
			var data = p1.data;
			var area = p2|0;
			var rp = area * 0;
			var gp = area * 1;
			var bp = area * 2;
			for (var n = 0; n < area; n++) {
				data[n] = (uncompressed[rp + n] << 0) | (uncompressed[gp + n] << 8) | (uncompressed[bp + n] << 16) | 0xFF000000;
			}
		""")
    }

    private fun readBmp32(uncompressed: ByteArray, data: IntArray, area: Int) {
        val rp = area * 0
        val gp = area * 1
        val bp = area * 2
        for (n in 0 until area) {
            val r = uncompressed[rp + n].toInt() and 0xFF
            val g = uncompressed[gp + n].toInt() and 0xFF
            val b = uncompressed[bp + n].toInt() and 0xFF
            data[n] = (r shl 0) or (g shl 8) or (b shl 16) or (0xFF shl 24)
        }
    }

    fun write(entries: List<Entry>): ByteArray {
        val s = MemorySyncStream()
        val indexed = entries.first().bitmap is Bitmap8
        val bpp = if (indexed) 8 else 24
        s.write(HEADER(magic = MAGIC, count = entries.size, bpp = bpp))

        fun packData(bitmap: Bitmap): ByteArray = MemorySyncStreamToByteArray {
            when (bitmap) {
                is Bitmap8 -> {
                    writeBytes(bitmap.data)
                }
                is Bitmap32 -> {
                    for (n in 0 until bitmap.area) write8(RGBA.getR(bitmap.data[n]))
                    for (n in 0 until bitmap.area) write8(RGBA.getG(bitmap.data[n]))
                    for (n in 0 until bitmap.area) write8(RGBA.getB(bitmap.data[n]))
                }
                else -> invalidOp("Unsupported bitmap type")
            }
        }

        fun packAndCompressData(bitmap: Bitmap): ByteArray = WillLZ.compress(packData(bitmap))

        val s_head = MemorySyncStream()
        val s_data = MemorySyncStream()

        for (entry in entries) {
            val compressedData = packAndCompressData(entry.bitmap)
            val bitmap = entry.bitmap
            s_head.write(ENTRY_HEADER(
                    w = bitmap.width, h = bitmap.height,
                    x = entry.x, y = entry.y,
                    unknown = 0, compressed = compressedData.size
            ))
            s_data.writeBytes(compressedData)
        }

        s.writeBytes((s_head.base as MemorySyncStreamBase).data.toByteArraySlice())
        s.writeBytes((s_data.base as MemorySyncStreamBase).data.toByteArraySlice())

        return (s.base as MemorySyncStreamBase).data.toByteArray()
    }

    fun combine(color: Bitmap32, mask: Bitmap8): Bitmap32 {
        val out = Bitmap32(color.width, color.height)
        for (n in 0 until out.area) {
            out.data[n] = (color.data[n] and 0xFFFFFF) or ((mask.data[n].toInt() and 0xFF) shl 24)
        }
        return out
    }

    fun combine(color: Entry, mask: Entry): Entry {
        return Entry(combine(color.bitmap as Bitmap32, mask.bitmap as Bitmap8), color.x, color.y)
    }

    fun combine(color: List<Entry>, mask: List<Entry>): List<Entry> {
        return color.zip(mask).map { combine(it.first, it.second) }
    }
}
