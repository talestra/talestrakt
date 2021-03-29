module tales.media.SDL_image;

import tales.media.SDL;

extern (C):

SDL_Surface * IMG_Load(char *file);
SDL_Surface * IMG_Load_RW(SDL_RWops *src, int freesrc);
SDL_Surface * IMG_LoadTyped_RW(SDL_RWops *src, int freesrc, char *type);
int IMG_InvertAlpha(int on);

int IMG_isBMP(SDL_RWops *src);
int IMG_isPNM(SDL_RWops *src);
int IMG_isXPM(SDL_RWops *src);
int IMG_isXCF(SDL_RWops *src);
int IMG_isPCX(SDL_RWops *src);
int IMG_isGIF(SDL_RWops *src);
int IMG_isJPG(SDL_RWops *src);
int IMG_isTIF(SDL_RWops *src);
int IMG_isPNG(SDL_RWops *src);
int IMG_isLBM(SDL_RWops *src);

SDL_Surface * IMG_LoadBMP_RW(SDL_RWops *src);
SDL_Surface * IMG_LoadPNM_RW(SDL_RWops *src);
SDL_Surface * IMG_LoadXPM_RW(SDL_RWops *src);
SDL_Surface * IMG_LoadXCF_RW(SDL_RWops *src);
SDL_Surface * IMG_LoadPCX_RW(SDL_RWops *src);
SDL_Surface * IMG_LoadGIF_RW(SDL_RWops *src);
SDL_Surface * IMG_LoadJPG_RW(SDL_RWops *src);
SDL_Surface * IMG_LoadTIF_RW(SDL_RWops *src);
SDL_Surface * IMG_LoadPNG_RW(SDL_RWops *src);
SDL_Surface * IMG_LoadTGA_RW(SDL_RWops *src);
SDL_Surface * IMG_LoadLBM_RW(SDL_RWops *src);

SDL_Surface * IMG_ReadXPMFromArray(char **xpm);

alias SDL_GetError IMG_GetError;
