import com.soywiz.korio.async.sync
import com.soywiz.korio.vfs.LocalVfs
import com.talestra.games.toa.n3ds.TOFHDB
import org.junit.Test

class TOFHDBTest {
	@Test
	fun name() = sync {
		val s = LocalVfs("""C:\projects\ctr\ctr\Project_CTR\ctrtool\romfs\DVDDATA\CTR\FILEHEADER.TOFHDB""").readAsSyncStream()
		TOFHDB.read(s)
	}
}