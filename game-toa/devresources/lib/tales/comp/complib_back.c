#include <stdio.h>
#include <stdlib.h>
#include <memory.h>
#include <string.h>

#include "complib.h"

#define cleanup(err) { error = err; goto _cleanup; }
//#define get(c) { if (insp >= inst) cleanup(SUCCESS); c = *(insp++); }
#define put2(c) { if (ousp >= oust) cleanup(SUCCESS); *(ousp++) = c; }
#define put(c) { put2(c); text_buf[r++] = c; r &= (N - 1); }
#define get(c) { if (insp >= inst) break; c = *(insp++); }
//#define put(c) { if (ousp >= oust) break; *(ousp++) = c; text_buf[r++] = c; r &= (N - 1); }

#define N   0x1000
#define NIL N
#define MF  0x12
#define MAX_DUP (0x100 + 0x12)

int F, T;

unsigned long int textsize = 0, codesize = 0, printcount = 0;
unsigned char text_buf[N + MF - 1];
int match_position, match_length, lson[N + 1], rson[N + 257], dad[N + 1];
FILE *profilef = 0;

char *GetErrorString(int error) {
	switch (error) {
		case SUCCESS:               return "Success";
		case ERROR_FILE_IN:         return "Error with input file";
		case ERROR_FILE_OUT:        return "Error with output file";
		case ERROR_MALLOC:          return "Malloc failure";
		case ERROR_BAD_INPUT:       return "Bad Input";
		case ERROR_UNKNOWN_VERSION: return "Unknown version";
		case ERROR_FILES_MISMATCH:  return "Mismatch";
		default:                    return "Unknown error";
	}
}

void FillTextBuffer(void) {
	int n, p;
	for (n = 0, p = 0; n != 0x100; n++, p += 8) { text_buf[p + 6] = text_buf[p + 4] = text_buf[p + 2] = text_buf[p + 0] = n; text_buf[p + 7] = text_buf[p + 5] = text_buf[p + 3] = text_buf[p + 1] = 0; }
	for (n = 0; n != 0x100; n++, p += 7) { text_buf[p + 6] = text_buf[p + 4] = text_buf[p + 2] = text_buf[p + 0] = n; text_buf[p + 5] = text_buf[p + 3] = text_buf[p + 1] = 0xff; }
	while (p != N) text_buf[p++] = 0;
}

int PrepareVersion(int version) {
	T = 2;
	switch (version) {
		case 1:  F  = 0x12; break;
		case 3:  F  = 0x11; break;
		default: return ERROR_UNKNOWN_VERSION; break;
	}
	return SUCCESS;
}

void InitTree(void) {
	int i;
	for (i = N + 1; i <= N + 256; i++) rson[i] = NIL;
	for (i = 0; i < N; i++) dad[i] = NIL;
}

void InsertNode(int r) {
	int  i, p, cmp;
	unsigned char  *key;

	cmp = 1; key = &text_buf[r]; p = N + 1 + key[0];
	rson[r] = lson[r] = NIL; match_length = 0;

	while (1) {
		if (cmp >= 0) {
			if (rson[p] != NIL) p = rson[p];
			else { rson[p] = r; dad[r] = p; return; }
		} else {
			if (lson[p] != NIL) p = lson[p];
			else { lson[p] = r; dad[r] = p; return; }
		}

		for (i = 1; i < F; i++) if ((cmp = key[i] - text_buf[p + i]) != 0) break;

		if (i > match_length) {
			match_position = p;
			if ((match_length = i) >= F) break;
		}
	}

	dad[r] = dad[p]; lson[r] = lson[p]; rson[r] = rson[p];
	dad[lson[p]] = r; dad[rson[p]] = r;

	if (rson[dad[p]] == p) rson[dad[p]] = r; else lson[dad[p]] = r;

	dad[p] = NIL;
}

void DeleteNode(int p) {
	int  q;

	if (dad[p] == NIL) return;

	if (rson[p] == NIL) q = lson[p];
	else if (lson[p] == NIL) q = rson[p];
	else {
		q = lson[p];
		if (rson[q] != NIL) {
			do { q = rson[q]; } while (rson[q] != NIL);
			rson[dad[q]] = lson[q]; dad[lson[q]] = dad[q];
			lson[q] = lson[p]; dad[lson[p]] = q;
		}
		rson[q] = rson[p]; dad[rson[p]] = q;
	}
	dad[q] = dad[p];

	if (rson[dad[p]] == p) rson[dad[p]] = q; else lson[dad[p]] = q;
	dad[p] = NIL;
}

int Encode(int version, void *in, int inl, void *out, int *outl) {
	unsigned char *insp, *inst, *ousp, *oust, *inspb, *insplb;
	int i, c, len, r, s, last_match_length, dup_match_length = 0, code_buf_ptr, dup_last_match_length = 0;
	unsigned char code_buf[1 + 8 * 5], mask;
	int error = SUCCESS;

	inst = (insplb = inspb = insp = (unsigned char *)in) + inl; oust = (ousp = (unsigned char *)out) + *outl;

	if (version == 0) {
		while (1) {
			put2(0xff);

			for (i = 0; i < 8; i++) {
				get(c);
				put2(c);
			}

			if (insp >= inst) break;
		}

		if (insp != inst) return ERROR_BAD_INPUT;

		*outl = ousp - (unsigned char *)out;

		return error;
	}

	FillTextBuffer();
	PrepareVersion(version);
	InitTree();

	code_buf[0] = 0x00;
	code_buf_ptr = mask = 1;
	s = 0; r = N - F;

	//printf("%d\n", r);

	for (len = 0; len < F; len++) { get(c); text_buf[r + len] = c; }
	if ((textsize = len) == 0) return SUCCESS;

	for (i = 1; i <= F; i++) InsertNode(r - i); InsertNode(r);

	do {
		if (version >= 3) {
			if (insplb - inspb <= 0) {
				insplb = inspb + 1;
				while ((insplb < inst) && (*insplb == *inspb)) insplb++;
			}

			dup_match_length = insplb - inspb;
		}

		if (match_length > len) match_length = len;

		if (version >= 3 && dup_match_length > MAX_DUP) dup_match_length = MAX_DUP;

		if (version >= 3 && dup_match_length > (T + 1) && dup_match_length >= match_length) {
			if (dup_match_length >= (inst - insp)) dup_match_length--;
		} else {
			if (match_length >= (inst - insp)) match_length--;
		}
		/*
		if (version >= 3 && dup_match_length > (T + 1) && dup_match_length >= match_length) {
			if (dup_match_length >= (inst - insp)) dup_match_length -= 8;
		} else {
			if (match_length >= (inst - insp)) match_length -= 8;
		}
		*/

		if (version >= 3 && dup_match_length > (T + 1) && dup_match_length >= match_length) {
			match_length = dup_match_length;
			match_position = r;

			if (match_length <= 0x12) {
				code_buf[code_buf_ptr++] = text_buf[r];
				code_buf[code_buf_ptr++] = 0x0f | (((match_length - (T + 1)) & 0xf) << 4);
			} else {
				code_buf[code_buf_ptr++] = match_length - 0x13;
				code_buf[code_buf_ptr++] = 0x0f;
				code_buf[code_buf_ptr++] = text_buf[r];
			}
		} else if (match_length > T) {
			code_buf[code_buf_ptr++] = (unsigned char)match_position;
			code_buf[code_buf_ptr++] = (unsigned char)(((match_position >> 4) & 0xf0) | ((match_length - (T + 1)) & 0x0f));
		} else {
			code_buf[0] |= mask;
			match_length = 1;
			code_buf[code_buf_ptr++] = text_buf[r];
		}

		if ((mask <<= 1) == 0) {
			for (i = 0; i < code_buf_ptr; i++) put2(code_buf[i]);
			codesize += code_buf_ptr;
			code_buf[0] = 0x00; code_buf_ptr = mask = 1;
		}

		last_match_length = match_length;
		for (i = 0; i < last_match_length; i++) {
			get(c); DeleteNode(s); text_buf[s] = c;
			if (s < F - 1) text_buf[s + N] = c;
			s = (s + 1) & (N - 1);  r = (r + 1) & (N - 1);
			inspb++;
			InsertNode(r);
		}

		textsize += i;

		while (i++ < last_match_length) {
			DeleteNode(s); s = (s + 1) & (N - 1); r = (r + 1) & (N - 1);
			inspb++;
			if (--len) InsertNode(r);
		}
	} while (len > 0);

	if (code_buf_ptr > 1) {
		for (i = 0; i < code_buf_ptr; i++) put2(code_buf[i]);
		codesize += code_buf_ptr;
	}

_cleanup:

	if (insp != inst) return ERROR_BAD_INPUT;

	*outl = ousp - (unsigned char *)out;

	return SUCCESS;
}

int Decode(int version, void *in, int inl, void *out, int *outl) {
	unsigned char *insp, *inst, *ousp, *oust;
	unsigned int flags = 0, i, j, k, r, c;
	int error = SUCCESS;
	inst = (insp = (unsigned char *)in) + inl; oust = (ousp = (unsigned char *)out) + *outl;

	FillTextBuffer(); if ((error = PrepareVersion(version)) != SUCCESS) return error; r = N - F;

	for (;;) {
		if (((flags >>= 1) & 0x100) == 0) { get(c); if (profilef) fprintf(profilef, "-------- %02X -------- [%08X:%08X]\n", c, insp - (unsigned char *)in, ousp - (unsigned char *)out); flags = c | 0xff00; }
		if (flags & 1) { get(c); if (profilef) fprintf(profilef, "BYTE[%02X]\n", c); put(c); continue; }
		get(i); get(j); i |= (j & 0xf0) << 4; j = (j & 0x0f) + T;
		if (version == 1 || j < (F)) { if (profilef) fprintf(profilef, "WINDOW[%03X,*%02X] : (", j + 1, i); for (k = 0; k <= j; k++) { c = text_buf[(i + k) & (N - 1)]; put(c); if (profilef && k != 0) fprintf(profilef, ", "); if (profilef) fprintf(profilef, "%02X", c); } if (profilef) fprintf(profilef, ")\n"); continue; }
		if (i < 0x100) { get(j); i += F + 1; } else { j = i & 0xff; i = (i >> 8) + T; }
		if (profilef) fprintf(profilef, "REPEAT[%03X,%02X] : (", i + 1, j); for (k = 0; k <= i; k++) { put(j);  if (profilef && k != 0) fprintf(profilef, ", "); if (profilef) fprintf(profilef, "%02X", j); } if (profilef) fprintf(profilef, ")\n");
	}

_cleanup:

	if (insp != inst) {
		fprintf(stderr, "insp != inst (%d != %d)\n", insp, inst);
		return ERROR_BAD_INPUT;
	}

	*outl = ousp - (unsigned char *)out;

	return error;
}

int DecodeFile(char *in, char *out, int raw, int version) {
	unsigned int inl, outl; int error = SUCCESS;
	void *ind = 0, *outd = 0; FILE *fin = 0, *fout = 0;

	printf("Decoding[%02X] %s -> %s...", version, in, out);

	if ((fin = fopen(in, "rb")) == 0) cleanup(ERROR_FILE_IN);

	if (raw) {
		fseek(fin, 0, SEEK_END);
		inl = ftell(fin);
		fseek(fin, 0, SEEK_SET);
		outl = inl * 10;
	} else {
		version = getc(fin);
		fread(&inl, 4, 1, fin);
		fread(&outl, 4, 1, fin);
		if (PrepareVersion(version) != SUCCESS) cleanup(ERROR_FILE_IN);
	}

	if ((ind  = (void *)malloc(inl )) == SUCCESS) cleanup(ERROR_MALLOC);
	if ((outd = (void *)malloc(outl)) == SUCCESS) cleanup(ERROR_MALLOC);

	memset(ind, 0, inl);
	memset(outd, 0, outl);

	if (fread(ind, 1, inl, fin) == 0) cleanup(ERROR_FILE_IN);

	error = Decode(version, ind, inl, outd, (int *)&outl);

	if (out != NULL) {
		if ((fout = fopen(out, "wb")) == 0) cleanup(ERROR_FILE_OUT);
		if (fwrite(outd, 1, outl, fout) == 0) cleanup(ERROR_FILE_OUT);
	}

_cleanup:

	if (outd) free(outd);
	if (ind ) free(ind);

	if (fout) fclose(fout);
	if (fin ) fclose(fin);

	printf("%s\n", GetErrorString(error));

	return error;
}

int EncodeFile(char *in, char *out, int raw, int version) {
	unsigned int inl, outl; int error = SUCCESS;
	void *ind = 0, *outd = 0; FILE *fin = 0, *fout = 0;
	int eversion = 0;

	if (version < 0) {
		version = -version;
		eversion = 0;
	} else {
		eversion = version;
	}

	//printf("%d, %d\n", version, eversion);

	printf("Encoding[%02X] %s -> %s...", version, in, out);

	if ((fin = fopen(in, "rb")) == 0) cleanup(ERROR_FILE_IN);

	fseek(fin, 0, SEEK_END);
	inl = ftell(fin); outl = ((inl * 9) / 8) + 10;
	fseek(fin, 0, SEEK_SET);

	if ((ind  = (void *)malloc(inl )) == SUCCESS) cleanup(ERROR_MALLOC);
	if ((outd = (void *)malloc(outl)) == SUCCESS) cleanup(ERROR_MALLOC);

	memset(ind, 0, inl); memset(outd, 0, outl);

	if (fread(ind, 1, inl, fin) == 0) cleanup(ERROR_FILE_IN);

	error = Encode(eversion, ind, inl, outd, (int *)&outl);

	if (out != NULL) {
		if ((fout = fopen(out, "wb")) == 0) cleanup(ERROR_FILE_OUT);

		if (!raw) {
			putc(version, fout);
			fwrite(&outl, 4, 1, fout);
			fwrite(&inl, 4, 1, fout);
		}

		if (fwrite(outd, 1, outl, fout) == 0) cleanup(ERROR_FILE_OUT);
	}

_cleanup:

	if (outd) free(outd);
	if (ind ) free(ind);

	if (fout) fclose(fout);
	if (fin ) fclose(fin);

	printf("%s\n", GetErrorString(error));

	return error;
}

int DumpTextBuffer(char *out) {
	int error = SUCCESS;
	FILE *fout = 0;

	printf("Dumping text buffer...");

	FillTextBuffer();

	if ((fout = fopen(out, "wb")) == 0) cleanup(ERROR_FILE_OUT);

	fwrite(text_buf, 1, N, fout);

_cleanup:

	if (fout) fclose(fout);

	printf("%s\n", GetErrorString(error));

	return error;
}

void ProfileStart(char *out) {
	profilef = fopen(out, "wb");
}

void ProfileEnd() {
	if (profilef == 0) return;
	fclose(profilef);
	profilef = 0;
}

int CheckCompression(char *in, int version) {
	FILE *fin = 0; void *ind = 0, *outd = 0, *outd2 = 0;
	int error = SUCCESS, inl, outl, outl2;

	printf("Checking compression [%02X] (%s) ...", version, in);

	if ((fin = fopen(in, "rb")) == 0) cleanup(ERROR_FILE_IN);

	fseek(fin, 0, SEEK_END);
	outl2 = inl = ftell(fin); outl = ((inl * 9) / 8) + 10;
	fseek(fin, 0, SEEK_SET);

	if ((ind   = (void *)malloc(inl  )) == SUCCESS) cleanup(ERROR_MALLOC);
	if ((outd  = (void *)malloc(outl )) == SUCCESS) cleanup(ERROR_MALLOC);
	if ((outd2 = (void *)malloc(outl2)) == SUCCESS) cleanup(ERROR_MALLOC);

	memset(ind, 0, inl); memset(outd, 0, outl); memset(outd2, 0, outl2);

	fread(ind, 1, inl, fin);

	if ((error = Encode(version, ind, inl, outd, &outl)) != SUCCESS) cleanup(error);

	if ((error = Decode(version, outd, outl, outd2, &outl2)) != SUCCESS) cleanup(error);

	if (inl != outl2) cleanup(ERROR_FILES_MISMATCH);
	if (memcmp(ind, outd2, inl) != 0) cleanup(ERROR_FILES_MISMATCH);

_cleanup:

	if (outd2) free(outd2);
	if (outd) free(outd);
	if (ind) free(ind);

	if (fin) fclose(fin);

	printf("%s\n", GetErrorString(error));

	return error;
}
