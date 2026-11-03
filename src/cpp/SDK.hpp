#pragma once

#ifndef SDK_HPP
#define SDK_HPP

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#include <gl/gl.h>
#include <cmath>
#include <cstring>
#include <string>

// Button Bitmasks (GoldSrc / Half-Life SDK)
#define IN_ATTACK    (1 << 0)
#define IN_JUMP      (1 << 1)
#define IN_DUCK      (1 << 2)
#define IN_FORWARD   (1 << 3)
#define IN_BACK      (1 << 4)
#define IN_USE       (1 << 5)
#define IN_MOVELEFT  (1 << 9)
#define IN_MOVERIGHT (1 << 10)
#define IN_ATTACK2   (1 << 11)

// Engine Flags
#define FL_ONGROUND  (1 << 9)

#pragma pack(push, 1)

struct Vector {
    float x, y, z;

    Vector() : x(0.0f), y(0.0f), z(0.0f) {}
    Vector(float _x, float _y, float _z) : x(_x), y(_y), z(_z) {}

    inline Vector operator+(const Vector& v) const { return Vector(x + v.x, y + v.y, z + v.z); }
    inline Vector operator-(const Vector& v) const { return Vector(x - v.x, y - v.y, z - v.z); }
    inline Vector operator*(float fl) const { return Vector(x * fl, y * fl, z * fl); }
    inline Vector& operator+=(const Vector& v) { x += v.x; y += v.y; z += v.z; return *this; }
    inline Vector& operator-=(const Vector& v) { x -= v.x; y -= v.y; z -= v.z; return *this; }

    inline float Length() const {
        return std::sqrt(x * x + y * y + z * z);
    }
};

struct Vector2D {
    float x, y;
    Vector2D() : x(0.0f), y(0.0f) {}
    Vector2D(float _x, float _y) : x(_x), y(_y) {}
};

struct usercmd_s {
    short           lerp_msec;
    unsigned char   msec;
    Vector          viewangles;
    float           forwardmove;
    float           sidemove;
    float           upmove;
    unsigned char   lightlevel;
    unsigned short  buttons;
    unsigned char   impulse;
    unsigned char   weaponselect;
    int             impact_index;
    Vector          impact_position;
};

struct cl_entity_s {
    int   index;
    int   player;
    Vector baseline_origin;
    Vector current_origin;
    Vector angles;
    char* model_name;
    unsigned char padding[0x360 - sizeof(Vector)*3 - 12];
    int   is_dead; // Offset 0x360: 0 = Alive, != 0 = Dead
};

struct trace_t {
    int     allsolid;
    int     startsolid;
    int     inopen;
    int     inwater;
    float   fraction;
    Vector  endpos;
    float   planenormal[3];
    float   planedist;
    int     hitgroup;
    cl_entity_s* ent;
};

struct screenfade_s {
    float fadeSpeed;
    float fadeEnd;
    float fadeTotalEnd;
    float fadeReset;
    unsigned char fader;
    unsigned char fadeg;
    unsigned char fadeb;
    unsigned char fadealpha;
    int fadeFlags;
};

struct ref_params_s {
    Vector vieworg;
    Vector viewangles;
    Vector forward;
    Vector right;
    Vector up;
    float  frametime;
    float  time;
    int    intermission;
    int    paused;
    int    spectator;
    int    onground;
    int    waterlevel;
    Vector simvel;
    Vector simorg;
    Vector viewheight;
    float  idealpitch;
    Vector cl_viewangles;
    int    health;
    Vector crosshairangle;
    float  viewsize;
    float  punchangle[3];
    int    maxclients;
    int    viewentity;
    int    playermodel;
    Vector cmd_angles;
    int    hardware;
    int    onlyclientdraw;
};

#pragma pack(pop)

#endif // SDK_HPP
