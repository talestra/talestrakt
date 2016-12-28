import com.soywiz.korio.stream.*
import com.talestra.rhcommon.lang.invalidOp
import java.util.*

object DSARCIDX {
	fun read(s: SyncStream): Map<String, SyncStream> {
		val magic = s.readStringz(8)
		if (magic != "DSARCIDX") invalidOp("Not a DSARCIDX file, but '$magic'")
		val count = s.readS64_le()
		s.readShortArray_le(count.toInt())
		while (s.position % 4L != 0L) {
			val ff = s.readU8()
			if (ff != 0xff) invalidOp("Expected 0xFF for padding")
		}
		val sh = s.readBytes((0x28 + 4 + 4) * count.toInt()).openSync("r")
		val out = LinkedHashMap<String, SyncStream>()
		for (n in 0 until count) {
			val name = sh.readStringz(0x28)
			val length = sh.readS32_le()
			val start = sh.readS32_le()
			out[name] = s.slice(start until start + length)
			//println("$name: $start..$length")
		}
		return out
	}
}