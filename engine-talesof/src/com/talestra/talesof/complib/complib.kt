package com.talestra.talesof.complib

import com.soywiz.korio.util.ByteArraySlice
import com.soywiz.korio.util.Pointer
import com.soywiz.korio.util.UByteArray

//fun cleanup(err) {
//	error = err; goto _cleanup; }
//
////#define get(c) { if (insp >= inst) cleanup(SUCCESS); c = *(insp++); }
//fun put2(c) {
//	if (ousp >= oust) cleanup(SUCCESS); *(ousp++) = c; }
//
//fun put(c) {
//	put2(c); text_buf[r++] = c; r & = (N-1)
//}
//
//fun get(c) {
//	if (insp >= inst) break
//	c = *(insp++)
//}


//#define put(c) { if (ousp >= oust) break; *(ousp++) = c; text_buf[r++] = c; r &= (N - 1); }

const val N = 0x1000
const val N_MASK = N - 1
const val NIL = N
const val MF = 0x12
const val MAX_DUP = (0x100 + 0x12)

var F: Int = 0
var T: Int = 0

var textsize = 0
var codesize = 0
var printcount = 0
val text_buf = UByteArray(N + MF - 1)

var match_position: Int = 0
var match_length: Int = 0
var lson = IntArray(N + 1)
var rson = IntArray(N + 257)
var dad = IntArray(N + 1)

fun FillTextBuffer() {
	var n: Int = 0
	var p: Int = 0

	n = 0
	p = 0
	while (n != 0x100) {
		text_buf[p + 6] = n
		text_buf[p + 4] = n
		text_buf[p + 2] = n
		text_buf[p + 0] = n
		text_buf[p + 7] = 0
		text_buf[p + 5] = 0
		text_buf[p + 3] = 0
		text_buf[p + 1] = 0
		n++
		p += 8
	}

	n = 0
	while (n != 0x100) {
		text_buf[p + 6] = n
		text_buf[p + 4] = n
		text_buf[p + 2] = n
		text_buf[p + 0] = n
		text_buf[p + 5] = 0xFF
		text_buf[p + 3] = 0xFF
		text_buf[p + 1] = 0xff
		n++
		p += 7
	}

	while (p != N) text_buf[p++] = 0
}

fun PrepareVersion(version: Int) {
	T = 2
	when (version) {
		1 -> F = 0x12
		3 -> F = 0x11
		else -> throw RuntimeException("Unknown version")
	}
}

fun InitTree() {
	for (i in N + 1..N + 256) rson[i] = NIL
	for (i in 0 until N) dad[i] = NIL
}

fun InsertNode(r: Int) {
	var i: Int
	var p: Int
	var cmp: Int
	val key = r

	cmp = 1
	p = N + 1 + text_buf[key]
	rson[r] = NIL
	lson[r] = NIL
	match_length = 0

	while (true) {
		if (cmp >= 0) {
			if (rson[p] != NIL) p = rson[p]
			else {
				rson[p] = r; dad[r] = p; return; }
		} else {
			if (lson[p] != NIL) p = lson[p]
			else {
				lson[p] = r; dad[r] = p; return; }
		}

		i = 1
		while (i < F) {
			cmp = text_buf[key + i] - text_buf[p + i]
			if (cmp != 0) break
			i++
		}

		if (i > match_length) {
			match_position = p
			match_length = i
			if (match_length >= F) break
		}
	}

	dad[r] = dad[p]; lson[r] = lson[p]; rson[r] = rson[p]
	dad[lson[p]] = r; dad[rson[p]] = r

	if (rson[dad[p]] == p) rson[dad[p]] = r; else lson[dad[p]] = r

	dad[p] = NIL
}

fun DeleteNode(p: Int) {
	var q: Int = 0

	if (dad[p] == NIL) return

	if (rson[p] == NIL) q = lson[p]
	else if (lson[p] == NIL) q = rson[p]
	else {
		q = lson[p]
		if (rson[q] != NIL) {
			do {
				q = rson[q]; } while (rson[q] != NIL)
			rson[dad[q]] = lson[q]; dad[lson[q]] = dad[q]
			lson[q] = lson[p]; dad[lson[p]] = q
		}
		rson[q] = rson[p]; dad[rson[p]] = q
	}
	dad[q] = dad[p]

	if (rson[dad[p]] == p) rson[dad[p]] = q; else lson[dad[p]] = q
	dad[p] = NIL
}

class DoneException : RuntimeException()

val done: Nothing get() = run { throw DoneException() }
inline fun breakOnDone(callback: () -> Unit) {
	try {
		callback()
	} catch (e: DoneException) {
	}
}

fun Encode(version: Int, `in`: Pointer, inl: Int, `out`: Pointer, outl: Int): ByteArraySlice {
	var c: Int
	var r: Int = 0
	var s: Int
	var last_match_length: Int
	var dup_match_length = 0
	var code_buf_ptr: Int
	var dup_last_match_length = 0
	val code_buf = UByteArray(1 + 8 * 5)
	var mask: Int

	val insp = `in`
	val inspb = `in`
	val insplb = `in`
	val ousp = out
	val inst = `in` + inl
	val oust = `out` + outl

	fun put2(c: Int) {
		if (ousp >= oust) done
		ousp.writeU8(c)
	}

	fun put(c: Int) {
		put2(c)
		text_buf[r++] = c
		r = r and (N - 1)
	}

	fun get(): Int {
		if (insp >= inst) done
		return insp.readU8()
	}


	if (version == 0) {
		while (true) {
			put2(0xff)
			for (i in 0 until 8) put2(get())
			if (insp >= inst) break
		}

		if (insp != inst) throw RuntimeException("Bad Input")

		return ByteArraySlice.create(out, ousp)
	}

	FillTextBuffer()
	PrepareVersion(version)
	InitTree()

	code_buf[0] = 0x00
	code_buf_ptr = 1
	mask = 1
	s = 0
	r = N - F

	//printf("%d\n", r)

	for (len in 0 until F) {
		text_buf[r + len] = get()
	}
	var len = F
	textsize = len
	breakOnDone {
		if (textsize == 0) done

		for (i in 1..F) InsertNode(r - i)
		InsertNode(r)


		do {
			if (version >= 3) {
				if (insplb - inspb <= 0) {
					insplb.setAdd(inspb, 1)
					while ((insplb < inst) && (insplb.getU8() == inspb.getU8())) insplb.inc()
				}

				dup_match_length = insplb - inspb
			}

			if (match_length > len) match_length = len

			if (version >= 3 && dup_match_length > MAX_DUP) dup_match_length = MAX_DUP

			if (version >= 3 && dup_match_length > (T + 1) && dup_match_length >= match_length) {
				if (dup_match_length >= (inst - insp)) dup_match_length--
			} else {
				if (match_length >= (inst - insp)) match_length--
			}
			/*
		if (version >= 3 && dup_match_length > (T + 1) && dup_match_length >= match_length) {
			if (dup_match_length >= (inst - insp)) dup_match_length -= 8
		} else {
			if (match_length >= (inst - insp)) match_length -= 8
		}
		*/

			if (version >= 3 && dup_match_length > (T + 1) && dup_match_length >= match_length) {
				match_length = dup_match_length
				match_position = r

				if (match_length <= 0x12) {
					code_buf[code_buf_ptr++] = text_buf[r]
					code_buf[code_buf_ptr++] = (0x0f or (((match_length - (T + 1)) and 0xf) shl 4))
				} else {
					code_buf[code_buf_ptr++] = (match_length - 0x13)
					code_buf[code_buf_ptr++] = 0x0f
					code_buf[code_buf_ptr++] = text_buf[r]
				}
			} else if (match_length > T) {
				code_buf[code_buf_ptr++] = match_position
				code_buf[code_buf_ptr++] = (((match_position ushr 4) and 0xf0) or ((match_length - (T + 1)) and 0x0f))
			} else {
				code_buf[0] = (code_buf[0].toInt() or mask)
				match_length = 1
				code_buf[code_buf_ptr++] = text_buf[r]
			}

			mask = mask shl 1
			if (mask == 0) {
				for (i in 0 until code_buf_ptr) put2(code_buf[i])
				codesize += code_buf_ptr
				code_buf[0] = 0x00
				code_buf_ptr = 1
				mask = 1
			}

			last_match_length = match_length
			for (i in 0 until last_match_length) {
				val c = get()
				DeleteNode(s)
				text_buf[s] = c
				if (s < F - 1) text_buf[s + N] = c
				s = (s + 1) % N
				r = (r + 1) % N
				inspb.inc()
				InsertNode(r)
			}
			var i = last_match_length

			textsize += i

			while (i++ < last_match_length) {
				DeleteNode(s)
				s = (s + 1) % N
				r = (r + 1) % N
				inspb.inc()
				if (--len > 0) InsertNode(r)
			}
		} while (len > 0)

		if (code_buf_ptr > 1) {
			for (i in 0 until code_buf_ptr) put2(code_buf[i])
			codesize += code_buf_ptr
		}
	}

	return ByteArraySlice.create(out, ousp)
}

fun Decode(version: Int, `in`: ByteArray, inl: Int, `out`: ByteArray, outl: Int): ByteArraySlice {
	var flags = 0
	var c: Int
	val insp = Pointer(`in`)
	val ousp = Pointer(`out`)

	val inst = insp + inl
	val oust = ousp + outl

	FillTextBuffer()
	PrepareVersion(version)
	var r = N - F

	fun get(): Int {
		if (insp.offset >= inst.offset) done
		return insp.readU8()
	}

	fun put(v: Int) {
		ousp.writeU8(v)
		text_buf[r++] = v
		r %= N
	}

	breakOnDone {
		while (true) {
			flags = flags ushr 1
			if ((flags and 0x100) == 0) {
				flags = get() or 0xff00
			}
			if ((flags and 1) != 0) {
				put(get())
				continue
			}
			var i = get()
			var j = get()
			i = i or ((j and 0xf0) shl 4)
			j = (j and 0x0f) + T
			if (version == 1 || j < (F)) {
				//if (profilef) fprintf(profilef, "WINDOW[%03X,*%02X] : (", j + 1, i)
				for (k in 0..j) {
					c = text_buf[(i + k) and (N - 1)]
					put(c)
					//if (profilef && k != 0) fprintf(profilef, ", ")
					//if (profilef) fprintf(profilef, "%02X", c)
				}
				continue
			}
			if (i < 0x100) {
				j = get()
				i += F + 1
			} else {
				j = i and 0xff
				i = (i ushr 8) + T
			}
			for (k in 0..i) put(j)
		}
	}

	if (insp.offset != inst.offset) throw RuntimeException("Bad Input $insp != $inst")

	return ByteArraySlice.create(Pointer(out, 0), ousp)
}

fun DecodeFile(`in`: String, out: String?, raw: Int, version: Int) {
	TODO()
//	unsigned int inl, outl; int error = SUCCESS
//	void * ind = 0, *outd = 0; FILE * fin = 0, *fout = 0
//
//	printf("Decoding[%02X] %s -> %s...", version, in, out)
//
//	if ((fin = fopen(in, "rb")) == 0) cleanup(ERROR_FILE_IN)
//
//	if (raw) {
//		fseek(fin, 0, SEEK_END)
//		inl = ftell(fin)
//		fseek(fin, 0, SEEK_SET)
//		outl = inl * 10
//	} else {
//		version = getc(fin)
//		fread(& inl, 4, 1, fin)
//		fread(& outl, 4, 1, fin)
//		if (PrepareVersion(version) != SUCCESS) cleanup(ERROR_FILE_IN)
//	}
//
//	if ((ind = (void *) malloc (inl)) == SUCCESS) cleanup(ERROR_MALLOC)
//	if ((outd = (void *) malloc (outl)) == SUCCESS) cleanup(ERROR_MALLOC)
//
//	memset(ind, 0, inl)
//	memset(outd, 0, outl)
//
//	if (fread(ind, 1, inl, fin) == 0) cleanup(ERROR_FILE_IN)
//
//	error = Decode(version, ind, inl, outd, & outl)
//
//	if (out != NULL) {
//		if ((fout = fopen(out, "wb")) == 0) cleanup(ERROR_FILE_OUT)
//		if (fwrite(outd, 1, outl, fout) == 0) cleanup(ERROR_FILE_OUT)
//	}
//
//	_cleanup:
//
//	if (outd) free(outd)
//	if (ind) free(ind)
//
//	if (fout) fclose(fout)
//	if (fin) fclose(fin)
//
//	printf("%s\n", GetErrorString(error))
//
//	return error
}

fun EncodeFile(`in`: String, `out`: String, raw: Int, version: Int) {
	TODO()
//	unsigned int inl, outl; int error = SUCCESS
//	void * ind = 0, *outd = 0; FILE * fin = 0, *fout = 0
//	int eversion = 0
//
//	if (version < 0) {
//		version = -version
//		eversion = 0
//	} else {
//		eversion = version
//	}
//
//	//printf("%d, %d\n", version, eversion)
//
//	printf("Encoding[%02X] %s -> %s...", version, in, out)
//
//	if ((fin = fopen(in, "rb")) == 0) cleanup(ERROR_FILE_IN)
//
//	fseek(fin, 0, SEEK_END)
//	inl = ftell(fin); outl = ((inl * 9) / 8) + 10
//	fseek(fin, 0, SEEK_SET)
//
//	if ((ind = (void *) malloc (inl)) == SUCCESS) cleanup(ERROR_MALLOC)
//	if ((outd = (void *) malloc (outl)) == SUCCESS) cleanup(ERROR_MALLOC)
//
//	memset(ind, 0, inl); memset(outd, 0, outl)
//
//	if (fread(ind, 1, inl, fin) == 0) cleanup(ERROR_FILE_IN)
//
//	error = Encode(eversion, ind, inl, outd, & outl)
//
//	if (out != NULL) {
//		if ((fout = fopen(out, "wb")) == 0) cleanup(ERROR_FILE_OUT)
//
//		if (!raw) {
//			putc(version, fout)
//			fwrite(& outl, 4, 1, fout)
//			fwrite(& inl, 4, 1, fout)
//		}
//
//		if (fwrite(outd, 1, outl, fout) == 0) cleanup(ERROR_FILE_OUT)
//	}
//
//	_cleanup:
//
//	if (outd) free(outd)
//	if (ind) free(ind)
//
//	if (fout) fclose(fout)
//	if (fin) fclose(fin)
//
//	printf("%s\n", GetErrorString(error))
//
//	return error

}

fun DumpTextBuffer(`out`: String) {
	TODO()

//	int error = SUCCESS
//	FILE * fout = 0
//
//	printf("Dumping text buffer...")
//
//	FillTextBuffer()
//
//	if ((fout = fopen(out, "wb")) == 0) cleanup(ERROR_FILE_OUT)
//
//	fwrite(text_buf, 1, N, fout)
//
//	_cleanup:
//
//	if (fout) fclose(fout)
//
//	printf("%s\n", GetErrorString(error))
//
//	return error
}

fun ProfileStart(`out`: String) {
//	profilef = fopen(out, "wb")
}
//

fun ProfileEnd() {
//	if (profilef == 0) return
//	fclose(profilef)
//	profilef = 0
}

fun CheckCompression(`int`: String, version: Int) {
	TODO()
//	FILE * fin = 0; void * ind = 0, *outd = 0, *outd2 = 0
//	int error = SUCCESS, inl, outl, outl2
//
//	printf("Checking compression [%02X] (%s) ...", version, in)
//
//	if ((fin = fopen(in, "rb")) == 0) cleanup(ERROR_FILE_IN)
//
//	fseek(fin, 0, SEEK_END)
//	outl2 = inl = ftell(fin); outl = ((inl * 9) / 8) + 10
//	fseek(fin, 0, SEEK_SET)
//
//	if ((ind = (void *) malloc (inl)) == SUCCESS) cleanup(ERROR_MALLOC)
//	if ((outd = (void *) malloc (outl)) == SUCCESS) cleanup(ERROR_MALLOC)
//	if ((outd2 = (void *) malloc (outl2)) == SUCCESS) cleanup(ERROR_MALLOC)
//
//	memset(ind, 0, inl); memset(outd, 0, outl); memset(outd2, 0, outl2)
//
//	fread(ind, 1, inl, fin)
//
//	if ((error = Encode(version, ind, inl, outd, & outl)) != SUCCESS) cleanup(error)
//
//	if ((error = Decode(version, outd, outl, outd2, & outl2)) != SUCCESS) cleanup(error)
//
//	if (inl != outl2) cleanup(ERROR_FILES_MISMATCH)
//	if (memcmp(ind, outd2, inl) != 0) cleanup(ERROR_FILES_MISMATCH)
//
//	_cleanup:
//
//	if (outd2) free(outd2)
//	if (outd) free(outd)
//	if (ind) free(ind)
//
//	if (fin) fclose(fin)
//
//	printf("%s\n", GetErrorString(error))
//
//	return error
}
