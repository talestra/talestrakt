#ifndef __COMPLIB_H
	#define __COMPLIB_H

	#define SUCCESS                0
	#define ERROR_BAD_INPUT       -4
	#define ERROR_UNKNOWN_VERSION -5

	int toencode(int version, void *in, int inl, void *out, int *outl);
	int todecode(int version, void *in, int inl, void *out, int *outl);
	int tocheckver(int version);

#endif
