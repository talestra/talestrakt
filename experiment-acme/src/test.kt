import com.soywiz.korio.async.EventLoop
import com.soywiz.korio.async.asyncGenerate
import org.tmatesoft.sqljet.core.SqlJetTransactionMode
import org.tmatesoft.sqljet.core.table.ISqlJetTable
import org.tmatesoft.sqljet.core.table.SqlJetDb
import java.io.File

fun ISqlJetTable.iterate() = asyncGenerate {
	val table = this@iterate
	val db = table.dataBase
	val def = table.definition

	//table.dataBase.runReadTransaction {
	db.beginTransaction(SqlJetTransactionMode.READ_ONLY)
	//val out = arrayListOf<Map<String, Any?>>()
	try {
		val cur = table.open()

		if (!cur.eof()) {
			do {
				val row = hashMapOf<String, Any?>()
				for (col in def.columns) row[col.name] = cur.getValue(col.index)
				//println(row)
				////println(cur.rowId)
				//println(cur.getInteger(0))
				//yield(row)
				//out += row
				yield(row)
			} while (cur.next())
			cur.close()
		}
	} finally {
		println("-------------")
		db.commit()
	}
	//println(projects.open().getInteger(0))
	//println(projects.definition.columns.first().name)
	//}

	//return out
}

fun main(args: Array<String>) = EventLoop {
	val acme = SqlJetDb.open(File("experiment-acme/acme.db"), false)
	println(acme.schema.tableNames)
	val projects = acme.getTable("tr_projects")
	for (i in projects.iterate()) {
		println(i)
	}
}