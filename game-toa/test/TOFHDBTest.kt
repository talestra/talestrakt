import com.soywiz.korio.async.sync
import com.soywiz.korio.vfs.LocalVfs
import com.talestra.games.toa.n3ds.TOFHDB
import com.talestra.talesof.complib.CompTalesOf
import org.junit.Test

class TOFHDBTest {
	val root = LocalVfs("""C:\projects\ctr\ctr\Project_CTR\ctrtool\romfs\DVDDATA\CTR""")
	//val root = LocalVfs("""C:\projects\ctr\ctr\Project_CTR\ctrtool\romfs\DVDDATA_SKIT\CTR""")
	//val root = LocalVfs("""C:\projects\ctr\ctr\Project_CTR\ctrtool\romfs\DVDDATA_FD\CTR""")
	//val root = LocalVfs("""C:\projects\ctr\ctr\Project_CTR\ctrtool\romfs\DVDDATA_W1A\CTR""")

	val target = root["out"]
	@Test
	fun name() = sync<Unit> {
		val db = root["FILEHEADER.TOFHDB"].open()
		val dat = root["TLFILE.TLDAT"].open()
		target.mkdirs()
		val info = TOFHDB.read(db, dat)
		//var count = 0
		//for (v in info.list()) {
		//	println("${v.fullname} : ${v.size()} : ${v.isDirectory()}")
		//	println(v.read().toList())
		//	v.copyTo(target[v.basename])
		//	if (count++ >= 2) break
		//}
		for (f in info.listRecursive()) {
			val data = f.read()
			target["${f.basename}.c"].write(data)
			if (CompTalesOf.isCompressed(data)) {
				target[f.basename].write(data)
				println("uncompressing (1-3)... ${f.fullname} ${data.size}")
				val udata = CompTalesOf.deepDecompressWhileRequired(data)
				target[f.basename].write(udata)
				println("uncompressed!")
			} else {
				println("none!")
			}
		}
		//info.copyToTree(target) { (src, dst) ->
		//	println("$src -> $dst")
		//}
	}
}