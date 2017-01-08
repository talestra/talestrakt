module tales.media.SDL_mixer;

import tales.media.SDL;

extern (C):

const int MIX_MAJOR_VERSION = 1;
const int MIX_MINOR_VERSION = 2;
const int MIX_PATCHLEVEL = 5;

SDL_version * Mix_Linked_Version();


const int MIX_CHANNELS = 8;

const int MIX_DEFAULT_FREQUENCY = 22050;
version (LittleEndian) {
	const int MIX_DEFAULT_FORMAT = AUDIO_S16LSB;
}
version (BigEndian) {
	const int MIX_DEFAULT_FORMAT = AUDIO_S16MSB;
}
const int MIX_DEFAULT_CHANNELS = 2;
const int MIX_MAX_VOLUME = 128;

struct Mix_Chunk {
	int allocated;
	Uint8 *abuf;
	Uint32 alen;
	Uint8 volume;
}

alias int Mix_Fading;
enum {
	MIX_NO_FADING,
	MIX_FADING_OUT,
	MIX_FADING_IN
}

alias int  Mix_MusicType;
enum {
	MUS_NONE,
	MUS_CMD,
	MUS_WAV,
	MUS_MOD,
	MUS_MID,
	MUS_OGG,
	MUS_MP3
}

struct Mix_Music {}

int Mix_OpenAudio(int frequency, Uint16 format, int channels, int chunksize);
int Mix_AllocateChannels(int numchans);
int Mix_QuerySpec(int *frequency,Uint16 *format,int *channels);
Mix_Chunk * Mix_LoadWAV_RW(SDL_RWops *src, int freesrc);
Mix_Chunk * Mix_LoadWAV(char *file) { return Mix_LoadWAV_RW(SDL_RWFromFile(file, "rb"), 1); }
Mix_Music * Mix_LoadMUS(char *file);
Mix_Chunk * Mix_QuickLoad_WAV(Uint8 *mem);
Mix_Chunk * Mix_QuickLoad_RAW(Uint8 *mem, Uint32 len);
void Mix_FreeChunk(Mix_Chunk *chunk);
void Mix_FreeMusic(Mix_Music *music);
Mix_MusicType Mix_GetMusicType(Mix_Music *music);
void Mix_SetPostMix(void (*mix_func)(void *udata, Uint8 *stream, int len), void *arg);
void Mix_HookMusic(void (*mix_func)(void *udata, Uint8 *stream, int len), void *arg);
void Mix_HookMusicFinished(void (*music_finished)());
void * Mix_GetMusicHookData();
void Mix_ChannelFinished(void (*channel_finished)(int channel));
const int MIX_CHANNEL_POST = -2;
typedef void (*Mix_EffectFunc_t)(int chan, void *stream, int len, void *udata);
typedef void (*Mix_EffectDone_t)(int chan, void *udata);
int Mix_RegisterEffect(int chan, Mix_EffectFunc_t f, Mix_EffectDone_t d, void *arg);
int Mix_UnregisterEffect(int channel, Mix_EffectFunc_t f);
int Mix_UnregisterAllEffects(int channel);
const char[] MIX_EFFECTSMAXSPEED = "MIX_EFFECTSMAXSPEED";
int Mix_SetPanning(int channel, Uint8 left, Uint8 right);
int Mix_SetPosition(int channel, Sint16 angle, Uint8 distance);
int Mix_SetDistance(int channel, Uint8 distance);
int Mix_SetReverseStereo(int channel, int flip);
int Mix_ReserveChannels(int num);
int Mix_GroupChannel(int which, int tag);
int Mix_GroupChannels(int from, int to, int tag);
int Mix_GroupAvailable(int tag);
int Mix_GroupCount(int tag);
int Mix_GroupOldest(int tag);
int Mix_GroupNewer(int tag);
int Mix_PlayChannelTimed(int channel, Mix_Chunk *chunk, int loops, int ticks);
int Mix_PlayChannel(int channel, Mix_Chunk* chunk, int loops) { return Mix_PlayChannelTimed(channel,chunk,loops,-1); }
int Mix_PlayMusic(Mix_Music *music, int loops);
int Mix_FadeInMusic(Mix_Music *music, int loops, int ms);
int Mix_FadeInMusicPos(Mix_Music *music, int loops, int ms, double position);
int Mix_FadeInChannelTimed(int channel, Mix_Chunk *chunk, int loops, int ms, int ticks);
int Mix_FadeInChannel(int channel, Mix_Chunk* chunk, int loops, int ms) { return Mix_FadeInChannelTimed(channel,chunk,loops,ms,-1); }
int Mix_Volume(int channel, int volume);
int Mix_VolumeChunk(Mix_Chunk *chunk, int volume);
int Mix_VolumeMusic(int volume);
int Mix_HaltChannel(int channel);
int Mix_HaltGroup(int tag);
int Mix_HaltMusic();
int Mix_ExpireChannel(int channel, int ticks);
int Mix_FadeOutChannel(int which, int ms);
int Mix_FadeOutGroup(int tag, int ms);
int Mix_FadeOutMusic(int ms);
Mix_Fading Mix_FadingMusic();
Mix_Fading Mix_FadingChannel(int which);
void Mix_Pause(int channel);
void Mix_Resume(int channel);
int Mix_Paused(int channel);
void Mix_PauseMusic();
void Mix_ResumeMusic();
void Mix_RewindMusic();
int Mix_PausedMusic();
int Mix_SetMusicPosition(double position);
int Mix_Playing(int channel);
int Mix_PlayingMusic();
int Mix_SetMusicCMD(char *command);
int Mix_SetSynchroValue(int value);
int Mix_GetSynchroValue();
Mix_Chunk * Mix_GetChunk(int channel);
void Mix_CloseAudio();

alias SDL_GetError Mix_GetError;
