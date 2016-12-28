#include <assert.h>
#include <io.h>
#include <assert.h>
#include <fcntl.h>

#include <Handle.h>
#include <Input.h>
#include <Output.h>

#include <dvdabstract.h>
#include <cdutils.h>
#include <isobuilder.h>
#include <complib.h>


#pragma warning (disable : 4996)
#pragma pack(1)

Handle *i;
Handle *o;

cdfile *is;
Output *os;

cdutils *cdutil;
isobuilder *iso;
cdutils::DirEntry dirent;
isobuilder::PVD pvd;
isobuilder::DirTree *root;
isobuilder::DirTree *xadirtree;
isobuilder::DirTree *dir1;

// Comprueba si existe un archivo
bool file_exists(char *name) { FILE *f = fopen(name, "rb"); if (f) fclose(f); return (f != NULL); }

// Copia un archivo
bool _copy(char *a, char *b) {
	char temp[0x800];
	FILE *fa, *fb;
	if ((fa = fopen(a, "rb")) == NULL) return false;
	if ((fb = fopen(b, "wb")) == NULL) { fclose(fa); return false; }
	while (!feof(fa)) { int l = fread(temp, 1, sizeof(temp), fa); fwrite(temp, 1, l, fb); }
	fclose(fb);
	fclose(fa);
	return true;
}

bool exists_direntry(cdutils::DirEntry &dirent) {
	return dirent.R != 0 || dirent.NExt != 0 || dirent.Sector != 0;
}


#define COPY_DIR(d)               { dirent = cdutil->find_path("/"d); dir1 = iso->createdir(root, d); }
#define COPY_FROM_DIR(d,s)        { Handle *cdf1; dirent = cdutil->find_path(d"/"s";1");iso->createfile(dir1, cdf1 = new cdfile(cdutil, &dirent), s); cdf1->close(); delete cdf1; }
//#define COPY_FROM_DIR(d,s)        { Handle *cdf1; dirent = cdutil->find_path(d"/"s";1");iso->createfile(dir1, cdf1 = new cdfile(cdutil, &dirent), s); cdf1->close(); delete cdf1; }
#define COPY_FROM_FILE(s,f)       { Handle *cdf1; dirent = cdutil->find_path(s";1");iso->createfile(dir1, cdf1 = new Input(f), s); cdf1->close(); delete cdf1; }
#define COPY_FROM_FILE_DIR(d,s,f) { Handle *cdf1; dirent = cdutil->find_path(d"/"s";1");iso->createfile(dir1, cdf1 = new Input(f), s); cdf1->close(); delete cdf1; }
#define COPY_FROM_DIR_XA(d,s)     { Handle *cdf1; dirent = cdutil->find_path(d"/"s";1");(iso->createfile(dir1, cdf1 = new cdfile(cdutil, &dirent), s))->setbasicsxa(); cdf1->close(); delete cdf1; }
#define COPY_FROM_ROOT(s)         { Handle *cdf1; dirent = cdutil->find_path(s";1");iso->createfile(root, cdf1 = new cdfile(cdutil, &dirent), s); cdf1->close(); delete cdf1; }


extern "C" isobuilder *isowrite_open(char *name) {
	return new isobuilder(new Output(name), MODE2_FORM1);
}

extern "C" void isowrite_close(isobuilder *iso) {
	{ // Dummy
		unsigned char void_sector[2352];
		memset(void_sector, 0, sizeof(void_sector));
		for (int n = 0; n < 15000; n++) iso->createsector(void_sector, MODE2_FORM1);
		for (int n = 0; n < 150  ; n++) iso->createsector(void_sector, MODE2);	
	}	
	
	iso->close();
	iso->w->close();
	delete iso->w;
	delete iso;		
}

extern "C" cdutils *isoread_open(char *name) {
	return new cdutils(new Input(name));	
}

extern "C" void isoread_close(cdutils *cdutil) {
	cdutil->f_iso_r->close();
	delete cdutil->f_iso_r;
	delete cdutil;
}

extern "C" isobuilder::DirTree *isowrite_isoread_copy_basics(isobuilder *iso, cdutils *cdutil) {
	isobuilder::DirTree *root;
	cdutils::DirEntry dirent;
	iso->foreword(cdutil);	
	root = iso->setbasics(iso->createpvd(cdutil));
	dirent = cdutil->find_path("/");
	root->setbasicsxa();	
	root->fromdir(&dirent);	
	return root;
}

extern "C" isobuilder::DirTree *isowrite_create_dir(isobuilder *iso, isobuilder::DirTree *dir, char *name) {
	return iso->createdir(dir, name);
}

extern "C" void isowrite_create_file(isobuilder *iso, isobuilder::DirTree *dir, char *name, char *input) {
	Input *i = new Input(input);
	iso->createfile(dir, i, name);	
	i->close();
	delete i;
}

extern "C" void isowrite_copy_file(isobuilder *iso, cdutils *cdutil, isobuilder::DirTree *dir, char *name, char *input, int mode = -1) {
	cdutils::DirEntry dirent = cdutil->find_path(input);		
	Handle *cdf1;
	iso->createfile(dir, cdf1 = new cdfile(cdutil, &dirent), name);
	//iso->createfile(dir, cdf1 = new cdfile(cdutil, &dirent), name, NULL, mode);
	cdf1->close();
	delete cdf1;
}

// void isobuilder::copydir(isobuilder::DirTree * r, cdutils * cd, cdutils::DirEntry * d, int mode, const String & checkdir) {
extern "C" void isowrite_copy_dir(isobuilder *iso, cdutils *cdutil, isobuilder::DirTree *dir, char *name, char *input, int mode, char *checkdir) {
	cdutils::DirEntry dirent = cdutil->find_path(input);		
	isobuilder::DirTree *xadirtree = iso->createdir(dir, name, 1, &dirent);
	xadirtree->setbasicsxa();
	iso->copydir(xadirtree, cdutil, &dirent, mode, checkdir);
	
	// iso->copydir(xadirtree, cdutil, &dirent, -1, "MOVIE");
}

extern "C" int isoread_extract(cdutils *cdutil, char *input, char *output) {
	cdutils::DirEntry dirent = cdutil->find_path(input);		
	if (dirent.Sector == 0) return 0;
		
	Handle *in = new cdfile(cdutil, &dirent);
	Handle *out = new Output(output);
	
	copy(in, out);
	
	/*char temp[0x8000];
	while (1) {
		int r = in->read(temp, sizeof(temp));
		if (r <= 0) break;
		out->write(temp, r);
	}*/
	
	in->close();
	out->close();
	delete in;
	delete out;
	
	return 1;
}

extern "C" int isoread_exists(cdutils *cdutil, char *input) {
	cdutils::DirEntry dirent = cdutil->find_path(input);	
	return (dirent.Sector != NULL);
}

extern "C" void isowrite_create_cue(isobuilder *iso, char *cue, char *bin) {
	int zsector = iso->lastdispsect + 150;
	FILE *fcue;
	if ((fcue = fopen(cue, "wb")) != NULL) {
		fprintf(fcue, "FILE \"%s\" BINARY\r\n  TRACK 01 MODE2/2352\r\n    INDEX 01 00:00:00\r\n", bin);
		fprintf(
			fcue,
			"  TRACK 02 AUDIO\r\n    PREGAP 00:02:00\r\n    INDEX 01 %02d:%02d:%02d\r\n",
			((zsector / 75) / 60),
			(zsector / 75) % 60,
			(zsector % 75)
		);
		fclose(fcue);	
	}
}
