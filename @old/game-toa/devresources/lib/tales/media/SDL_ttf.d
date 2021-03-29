module tales.media.SDL_ttf;

import tales.media.SDL;

extern (C) :

struct TTF_Font {}

int TTF_Init();
TTF_Font * TTF_OpenFont(char *file, int ptsize);
TTF_Font * TTF_OpenFontIndex(char *file, int ptsize, long index);
TTF_Font * TTF_OpenFontRW(SDL_RWops *src, int freesrc, int ptsize);
TTF_Font * TTF_OpenFontIndexRW(SDL_RWops *src, int freesrc, int ptsize, long index);
const int TTF_STYLE_NORMAL = 0x00;
const int TTF_STYLE_BOLD = 0x01;
const int TTF_STYLE_ITALIC = 0x02;
const int TTF_STYLE_UNDERLINE = 0x04;
int TTF_GetFontStyle(TTF_Font *font);
void TTF_SetFontStyle(TTF_Font *font, int style);
int TTF_FontHeight(TTF_Font *font);
int TTF_FontAscent(TTF_Font *font);
int TTF_FontDescent(TTF_Font *font);
int TTF_FontLineSkip(TTF_Font *font);
long TTF_FontFaces(TTF_Font *font);
int TTF_FontFaceIsFixedWidth(TTF_Font *font);
char * TTF_FontFaceFamilyName(TTF_Font *font);
char * TTF_FontFaceStyleName(TTF_Font *font);
int TTF_GlyphMetrics(TTF_Font *font, Uint16 ch, int *minx, int *maxx, int *miny, int *maxy, int *advance);
int TTF_SizeText(TTF_Font *font, char *text, int *w, int *h);
int TTF_SizeUTF8(TTF_Font *font, char *text, int *w, int *h);
int TTF_SizeUNICODE(TTF_Font *font, Uint16 *text, int *w, int *h);
SDL_Surface * TTF_RenderText_Solid(TTF_Font *font, char *text, SDL_Color fg);
SDL_Surface * TTF_RenderUTF8_Solid(TTF_Font *font, char *text, SDL_Color fg);
SDL_Surface * TTF_RenderUNICODE_Solid(TTF_Font *font, Uint16 *text, SDL_Color fg);
SDL_Surface * TTF_RenderGlyph_Solid(TTF_Font *font, Uint16 ch, SDL_Color fg);
SDL_Surface * TTF_RenderText_Shaded(TTF_Font *font, char *text, SDL_Color fg, SDL_Color bg);
SDL_Surface * TTF_RenderUTF8_Shaded(TTF_Font *font, char *text, SDL_Color fg, SDL_Color bg);
SDL_Surface * TTF_RenderUNICODE_Shaded(TTF_Font *font, Uint16 *text, SDL_Color fg, SDL_Color bg);
SDL_Surface * TTF_RenderGlyph_Shaded(TTF_Font *font, Uint16 ch, SDL_Color fg, SDL_Color bg);
SDL_Surface * TTF_RenderText_Blended(TTF_Font *font, char *text, SDL_Color fg);
SDL_Surface * TTF_RenderUTF8_Blended(TTF_Font *font, char *text, SDL_Color fg);
SDL_Surface * TTF_RenderUNICODE_Blended(TTF_Font *font, Uint16 *text, SDL_Color fg);
SDL_Surface * TTF_RenderGlyph_Blended(TTF_Font *font, Uint16 ch, SDL_Color fg);
SDL_Surface* TTF_RenderText(TTF_Font* font, char* text, SDL_Color fg, SDL_Color bg) { return TTF_RenderText_Shaded(font, text, fg, bg); }
SDL_Surface* TTF_RenderUTF8(TTF_Font* font, char* text, SDL_Color fg, SDL_Color bg) { return TTF_RenderUTF8_Shaded(font, text, fg, bg); }
SDL_Surface* TTF_RenderUNICODE(TTF_Font* font, Uint16* text, SDL_Color fg, SDL_Color bg) { return TTF_RenderUNICODE_Shaded(font, text, fg, bg); }
void TTF_CloseFont(TTF_Font *font);
void TTF_Quit();

alias SDL_GetError TTF_GetError;
