module sqlite3;

import std.string, std.stdio, std.c.string;

version(Windows) {
	//pragma(lib, "sqlite3.lib");
}

private import std.c.stdarg;

char[] sqlite_escape_string(char[] i) {
	char[] r;
	for (int n = 0, l = i.length; n < l; n++) {
		switch (i[n]) {
			case '\'': r ~= '\'';
			default: r ~= i[n];
		}
	}

	return r;
}

char[] sqlite_encode_binary(char[] i) {
	char[] r; r.length = i.length * 2 + 10;
	r.length = sqlite_encode_binary(i.ptr, i.length, r.ptr);
	return r;
}

int sqlite_encode_binary(char *inp, int n, char *outp){
	int i, j, e, m;
	char x;
	int cnt[256];

	if (n <= 0) {
		if (outp) outp[0..2] = ['x', 0];
		return 1;
	}

	cnt[] = 0;
	for (i = n - 1; i >= 0; i--) cnt[inp[i]]++;
	m = n;
	for (i = 1; i < 0x100; i++){
		int sum;
		if (i == '\'') continue;
		sum = cnt[i] + cnt[(i + 1) & 0xff] + cnt[(i + '\'') & 0xff];
		if (sum >= m) continue;
		e = i;
		if ((m = sum) == 0) break;
	}

	if (outp == null) return n + m + 1;

	outp[0] = e;
	j = 1;
	for (i = 0; i < n; i++) {
		x = inp[i] - e;
		if (x == 0 || x == 1 || x == '\'') {
			outp[j++] = 1;
			x++;
		}
		outp[j++] = x;
	}

	outp[j] = 0;
	assert(j == n + m + 1);

	return j;
}

char[] sqlite_decode_binary(char[] i) {
	if (i[0] != 1) return i;
	char[] r; r.length = i.length + 1;
	r.length = sqlite_decode_binary(toStringz(i), r.ptr);
	return r;
}

int sqlite_decode_binary(char *inp, char *outp){
	int i = 0, e = *(inp++); char c;

	while ((c = *(inp++)) != 0) {
		if (c == 1) c = *(inp++) - 1;
		outp[i++] = c + e;
	}

	return i;
}

extern(C) {
	struct sqlite3_stmt {}
	struct sqlite3_context {}
	struct sqlite3_value {}
	struct sqlite3 {}
	alias sqlite3 sqlite;

	alias int function(void*,int,char**, char**) sqlite_callback;

	private alias void function(void *) _func;
	const _func SQLITE_STATIC     = cast(_func)0;
	const _func SQLITE_TRANSIENT  = cast(_func)-1;

	const int SQLITE_OK         =  0;
	const int SQLITE_ERROR      =  1;
	const int SQLITE_INTERNAL   =  2;
	const int SQLITE_PERM       =  3;
	const int SQLITE_ABORT      =  4;
	const int SQLITE_BUSY       =  5;
	const int SQLITE_LOCKED     =  6;
	const int SQLITE_NOMEM      =  7;
	const int SQLITE_READONLY   =  8;
	const int SQLITE_INTERRUPT  =  9;
	const int SQLITE_IOERR      = 10;
	const int SQLITE_CORRUPT    = 11;
	const int SQLITE_NOTFOUND   = 12;
	const int SQLITE_FULL       = 13;
	const int SQLITE_CANTOPEN   = 14;
	const int SQLITE_PROTOCOL   = 15;
	const int SQLITE_EMPTY      = 16;
	const int SQLITE_SCHEMA     = 17;
	const int SQLITE_TOOBIG     = 18;
	const int SQLITE_CONSTRAINT = 19;
	const int SQLITE_MISMATCH   = 20;
	const int SQLITE_MISUSE     = 21;
	const int SQLITE_NOLFS      = 22;
	const int SQLITE_AUTH       = 23;
	const int SQLITE_FORMAT     = 24;
	const int SQLITE_RANGE      = 25;
	const int SQLITE_NOTADB     = 26;
	const int SQLITE_ROW        = 100;
	const int SQLITE_DONE       = 101;

	const int SQLITE_COPY                =  0;
	const int SQLITE_CREATE_INDEX        =  1;
	const int SQLITE_CREATE_TABLE        =  2;
	const int SQLITE_CREATE_TEMP_INDEX   =  3;
	const int SQLITE_CREATE_TEMP_TABLE   =  4;
	const int SQLITE_CREATE_TEMP_TRIGGER =  5;
	const int SQLITE_CREATE_TEMP_VIEW    =  6;
	const int SQLITE_CREATE_TRIGGER      =  7;
	const int SQLITE_CREATE_VIEW         =  8;
	const int SQLITE_DELETE              =  9;
	const int SQLITE_DROP_INDEX          = 10;
	const int SQLITE_DROP_TABLE          = 11;
	const int SQLITE_DROP_TEMP_INDEX     = 12;
	const int SQLITE_DROP_TEMP_TABLE     = 13;
	const int SQLITE_DROP_TEMP_TRIGGER   = 14;
	const int SQLITE_DROP_TEMP_VIEW      = 15;
	const int SQLITE_DROP_TRIGGER        = 16;
	const int SQLITE_DROP_VIEW           = 17;
	const int SQLITE_INSERT              = 18;
	const int SQLITE_PRAGMA              = 19;
	const int SQLITE_READ                = 20;
	const int SQLITE_SELECT              = 21;
	const int SQLITE_TRANSACTION         = 22;
	const int SQLITE_UPDATE              = 23;
	const int SQLITE_ATTACH              = 24;
	const int SQLITE_DETACH              = 25;

	const int SQLITE_DENY   = 1;
	const int SQLITE_IGNORE = 2;

	const int SQLITE_INTEGER = 1;
	const int SQLITE_FLOAT   = 2;
	const int SQLITE_TEXT    = 3;
	const int SQLITE_BLOB    = 4;
	const int SQLITE_NULL    = 5;

	const int SQLITE_UTF8    = 1;
	const int SQLITE_UTF16LE = 2;
	const int SQLITE_UTF16BE = 3;
	const int SQLITE_UTF16   = 4;
	const int SQLITE_ANY     = 5;

	void   sqlite3_close(sqlite *);
	int    sqlite3_exec(sqlite *db, char *zSql, sqlite_callback xCallback, void *pArg, char **pzErrMsg);
	long   sqlite3_last_insert_rowid(sqlite*);
	int    sqlite3_changes(sqlite*);
	int    sqlite3_last_statement_changes(sqlite*);
	void   sqlite3_interrupt(sqlite*);
	int    sqlite3_complete(char *sql);
	int    sqlite3_complete16(wchar *sql);
	void   sqlite3_busy_handler(sqlite*, int function(void*,int), void*);
	void   sqlite3_busy_timeout(sqlite*, int ms);
	int    sqlite3_get_table( sqlite*, char *sql, char ***resultp, int *nrow, int *ncolumn, char **errmsg);
	void   sqlite3_free_table(char **result);
	char  *sqlite3_mprintf(char*,...);
	char  *sqlite3_vmprintf(char*, va_list);
	void   sqlite3_free(char *z);
	int    sqlite3_set_authorizer(sqlite*, int function(void*,int, char*, char*, char*, char*) xAuth, void *pUserData);
	void  *sqlite3_trace(sqlite*, void function(void*,char*) xTrace, void*);
	void   sqlite3_progress_handler(sqlite*, int, int function(void*), void*);
	void  *sqlite3_commit_hook(sqlite*, int function(void*), void*);
	int    sqlite3_open(char *filename, sqlite3 **ppDb);
	int    sqlite3_open16(wchar *filename, sqlite3 **ppDb);
	int    sqlite3_errcode(sqlite3 *db);
	char  *sqlite3_errmsg(sqlite3*);
	wchar *sqlite3_errmsg16(sqlite3*);
	int    sqlite3_prepare(sqlite3 *db, char *zSql, int nBytes, sqlite3_stmt **ppStmt, char **pzTail);
	int    sqlite3_prepare16(sqlite3 *db, wchar *zSql, int nBytes, sqlite3_stmt **ppStmt, wchar **pzTail);
	int    sqlite3_bind_blob(sqlite3_stmt*, int, void*, int n, void function(void*));
	int    sqlite3_bind_double(sqlite3_stmt*, int, double);
	int    sqlite3_bind_int(sqlite3_stmt*, int, int);
	int    sqlite3_bind_int64(sqlite3_stmt*, int, long);
	int    sqlite3_bind_null(sqlite3_stmt*, int);
	int    sqlite3_bind_text(sqlite3_stmt*, int, char*, int n, void function(void*));
	int    sqlite3_bind_text16(sqlite3_stmt*, int, wchar*, int, void function(void*));
	int    sqlite3_bind_value(sqlite3_stmt*, int, sqlite3_value*);
	int    sqlite3_column_count(sqlite3_stmt *pStmt);
	char  *sqlite3_column_name(sqlite3_stmt*,int);
	wchar *sqlite3_column_name16(sqlite3_stmt*,int);
	char  *sqlite3_column_decltype(sqlite3_stmt *, int i);
	wchar *sqlite3_column_decltype16(sqlite3_stmt*,int);
	int    sqlite3_step(sqlite3_stmt*);
	int    sqlite3_data_count(sqlite3_stmt *pStmt);
	void  *sqlite3_column_blob(sqlite3_stmt*, int iCol);
	int    sqlite3_column_bytes(sqlite3_stmt*, int iCol);
	int    sqlite3_column_bytes16(sqlite3_stmt*, int iCol);
	double sqlite3_column_double(sqlite3_stmt*, int iCol);
	int    sqlite3_column_int(sqlite3_stmt*, int iCol);
	long   sqlite3_column_int64(sqlite3_stmt*, int iCol);
	char  *sqlite3_column_text(sqlite3_stmt*, int iCol);
	wchar *sqlite3_column_text16(sqlite3_stmt*, int iCol);
	int    sqlite3_column_type(sqlite3_stmt*, int iCol);
	int    sqlite3_finalize(sqlite3_stmt *pStmt);
	int    sqlite3_reset(sqlite3_stmt *pStmt);
	int    sqlite3_create_function(sqlite3 *, char *zFunctionName, int nArg, int eTextRep, int iCollateArg, void*, void function(sqlite3_context*,int,sqlite3_value**) xFunc, void function(sqlite3_context*,int,sqlite3_value**) xStep, void function(sqlite3_context*) xFinal);
	int    sqlite3_create_function16(sqlite3*, wchar *zFunctionName, int nArg, int eTextRep, int iCollateArg, void*, void function(sqlite3_context*,int,sqlite3_value**) xFunc, void function(sqlite3_context*,int,sqlite3_value**) xStep, void function(sqlite3_context*) xFinal);
	int    sqlite3_aggregate_count(sqlite3_context*);
	void  *sqlite3_value_blob(sqlite3_value*);
	int    sqlite3_value_bytes(sqlite3_value*);
	int    sqlite3_value_bytes16(sqlite3_value*);
	double sqlite3_value_double(sqlite3_value*);
	int    sqlite3_value_int(sqlite3_value*);
	long   sqlite3_value_int64(sqlite3_value*);
	char  *sqlite3_value_text(sqlite3_value*);
	wchar *sqlite3_value_text16(sqlite3_value*);
	void  *sqlite3_value_text16le(sqlite3_value*);
	void  *sqlite3_value_text16be(sqlite3_value*);
	int    sqlite3_value_type(sqlite3_value*);
	void  *sqlite3_aggregate_context(sqlite3_context*, int nBytes);
	void  *sqlite3_user_data(sqlite3_context*);
	void  *sqlite3_get_auxdata(sqlite3_context*, int);
	void   sqlite3_set_auxdata(sqlite3_context*, int, void*, void function(void*));
	void   sqlite3_result_blob(sqlite3_context*, void*, int, void function(void*));
	void   sqlite3_result_double(sqlite3_context*, double);
	void   sqlite3_result_error(sqlite3_context*, char*, int);
	void   sqlite3_result_error16(sqlite3_context*, wchar*, int);
	void   sqlite3_result_int(sqlite3_context*, int);
	void   sqlite3_result_int64(sqlite3_context*, long);
	void   sqlite3_result_null(sqlite3_context*);
	void   sqlite3_result_text(sqlite3_context*, char*, int, void function(void*));
	void   sqlite3_result_text16(sqlite3_context*, wchar*, int, void function(void*));
	void   sqlite3_result_text16le(sqlite3_context*, void*, int,void function(void*));
	void   sqlite3_result_text16be(sqlite3_context*, void*, int,void function(void*));
	void   sqlite3_result_value(sqlite3_context*, sqlite3_value*);
	int    sqlite3_create_collation(sqlite3*, char *zName, int eTextRep, void*, int function(void*,int,void*,int,void*) xCompare);
	int    sqlite3_create_collation16(sqlite3*, wchar *zName, int eTextRep, void*, int function(void*,int,void*,int,void*) xCompare);
	int    sqlite3_collation_needed(sqlite3*,  void*, void function(void*,sqlite3*,int eTextRep,char*));
	int    sqlite3_collation_needed16(sqlite3*,  void*, void function(void*,sqlite3*,int eTextRep,wchar*));

	char  *sqlite3_libversion();
}

class Sqlite3Error : Exception {
	this(int id, char[] s) {
		super(std.string.format("Sqlite3 Error (%d): '%s'", id, s));
	}
}

class Sqlite3Result {
	sqlite3_stmt* stmt;
	bool more = true;

	this(sqlite3_stmt* stmt) {
		if ((this.stmt = stmt) !is null) new Sqlite3Error(SQLITE_ERROR, "Invalid Sqlite3Result");
		execute();
	}

	~this() {
		sqlite3_finalize(stmt);
	}

	void execute() {
		reset();
		step();
	}

	int reset() { return sqlite3_reset(stmt); }

	int step() {
		int stepr = sqlite3_step(stmt);
		if (stepr == SQLITE_DONE) more = false;
		return stepr;
	}

	alias step next;

	int columnCount() { return sqlite3_column_count(stmt); }

	char[] getText(int column) {
		char[] r; char* c; int len;
		c = sqlite3_column_text(stmt, column);
		r.length = len = strlen(c);
		r[0..len] = c[0..len];
		//return sqlite_decode_binary(r);
		return r;
	}

	int  getInt32(int column) { return sqlite3_column_int(stmt, column); }
	long getInt64(int column) { return sqlite3_column_int64(stmt, column); }

	char[][] fetchRow() {
		char[][] r;
		if (!more) return r;
		r.length = sqlite3_column_count(stmt);
		for (int n = 0; n < r.length; n++) {
			char* c = sqlite3_column_text(stmt, n);
			r[n] = c[0..strlen(c)].dup;
		}
		step();
		return r;
	}

    int opApply(int delegate(inout int) dg) {
    	int count = 1;
		for (; more; next(), count++) {
			int r; if ((r = dg(count)) != 0) return r;
		}
		return 0;
    }
}

class Sqlite3 {
	sqlite3 *db;

	void check_error() {
		int id = sqlite3_errcode(db);
		if (id == SQLITE_OK) return;
		throw(new Sqlite3Error(id, std.string.toString(sqlite3_errmsg(db))));
	}

	this(char[] name) {
		sqlite3_open(std.string.toStringz(name), &db);
		check_error();
	}

	long getLastId() {
		return sqlite3_last_insert_rowid(db);
	}

	Sqlite3Result query(char[] query, char[][] params = null) {
		if (params !is null) {
			char[] pquery;
			int cparam = 0;
			try {
				foreach (c; query) {
					if (c == '?') {
						//pquery ~= "'" ~ sqlite_encode_binary(params[cparam++]) ~ "'";
						pquery ~= "'" ~ sqlite_escape_string(params[cparam++]) ~ "'";
					} else {
						pquery ~= c;
					}
				}
			} catch (Exception e) {
				writefln("QUERY: %s", e.toString());
				writefln("MALFORMED: '%s',%s", query, params);
			}
			return Sqlite3.query(pquery);
		}
		sqlite3_stmt* stmt;
		sqlite3_prepare(db, query.ptr, query.length, &stmt, null);
		//writefln(query);
		check_error();
		return new Sqlite3Result(stmt);

		//writefln(query); return null;
	}

	void performQuery(char[] query, char[][] params = null) {
		Sqlite3Result result = this.query(query, params);
		if (result) delete result;
	}

	~this() {
		sqlite3_close(db);
		//check_error();
	}

	static char[] libVersion() {
		return std.string.toString(sqlite3_libversion());
	}
}

/*
int main(char[][] args) {
	Sqlite3 db = new Sqlite3("test.db");

	try {
		try {
			db.performQuery("DROP TABLE [test];");
		} catch (Exception e) {
		}

		try {
			db.performQuery(
				"CREATE TABLE [test] ("
					"[id] INTEGER  NOT NULL,"
					"[nombre] VARCHAR(128) NULL"
				");"
			);
		} catch (Exception e) {
		}

		db.performQuery(std.string.format("INSERT INTO [test] ([id], [nombre]) VALUES (%d, '%s');", 1, "prueba"));
		db.performQuery(std.string.format("INSERT INTO [test] ([id], [nombre]) VALUES (%d, '%s');", 2, "test"));
		db.performQuery(std.string.format("INSERT INTO [test] ([id], [nombre]) VALUES (%d, '%s');", 3, "demo"));
		db.performQuery(std.string.format("INSERT INTO [test] ([id], [nombre]) VALUES (%d, '%s');", 4, "lol"));

		Sqlite3Result r = db.query(
			"SELECT [id],[nombre] FROM [test] ORDER BY id DESC;"
		);

		while (r.more) {
			writefln("%s", r.fetchRow());
		}

		delete r;

		//r.step();
	} finally {
		delete db;
	}

	return 0;
}
*/
/*
*/
