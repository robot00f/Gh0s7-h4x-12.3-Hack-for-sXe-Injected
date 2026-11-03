#include <windows.h>
#include <cmath>
#include <cstdio>

/* ==============================================================================
   FORENSIC RECONSTRUCTION & DECOMPILATION: Native C++ (Delphi Equivalent)
   Original Binary: lolwut32.dll / gh0s7h4x11.dll
   Memory Dump Analyzed: payload_memory_dump.bin (Base: 0x04C50000)
   ============================================================================== */

#pragma pack(push, 1)

struct Vector {
    float x; // Pitch or X coordinate
    float y; // Yaw or Y coordinate
    float z; // Roll or Z coordinate
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

#pragma pack(pop)

// Settings Structure (Mapped from RVA 0x2E5D4..0x2E680)
struct CheatConfig {
    int asuswallhack; // 0x04C7E5D4
    int lambert;      // 0x04C7E5D8
    int playerglow;   // 0x04C7E63C
    int playerlight;  // 0x04C7E640
    int whitewalls;   // 0x04C7E5DC
    int fullbright;   // 0x04C7E5E0
    int nightmode;    // 0x04C7E5F4
    int lesssmoke;    // 0x04C7E5E4
    int lessflash;    // 0x04C7E5E8
    int crosshair;    // 0x04C7E5F8
    int norecoil;     // 0x04C7E61C (Aim mode: 0=Off, 1=Silent, 2=Lock)

    int aimbot;       // 0x04C7E5FC
    int aimspeed;     // 0x04C7E66C (Default: 100)
    int silentaim;    // 0x04C7E654
    int aimteam;      // 0x04C7E628 (Default: 1)
    int aimkey;       // 0x04C7E64C (Default: 1)
    int aimspot;      // 0x04C7E600 (Default: 1)
    int drawaimspot;  // 0x04C7E65C
    int aimfov;       // 0x04C7E648 (Default: 450 = 45.0 deg)
    int drawaimfov;   // 0x04C7E644
    int aimthruwall;  // 0x04C7E638

    int boxesp;       // 0x04C7E604
    int nameesp;      // 0x04C7E608
    int weaponesp;    // 0x04C7E630
    int distanceesp;  // 0x04C7E62C
    int entityesp;    // 0x04C7E658
    int glowents;     // 0x04C7E668
    int glownades;    // 0x04C7E664
    int stepesp;      // 0x04C7E5EC

    int speedhack;    // 0x04C7E634
    int barrelhack;   // 0x04C7E660
    int radar;        // 0x04C7E624
};

// Reconstructed Global Variables
CheatConfig g_Config;
Vector      g_vTargetDelta;   // 0x04C7E6B0
int         g_iAimMode;       // 0x04C7E61C
bool        g_bMenuVisible = false;

// -----------------------------------------------------------------------------
// 3D Vector Math Subroutines
// -----------------------------------------------------------------------------

// RVA 0x13728: VectorLength
float VectorLength(const Vector& v) {
    return std::sqrt(v.x * v.x + v.y * v.y + v.z * v.z);
}

// RVA 0x13764: VectorSubtract
void VectorSubtract(const Vector& a, const Vector& b, Vector& out) {
    out.x = a.x - b.x;
    out.y = a.y - b.y;
    out.z = a.z - b.z;
}

// RVA 0x138E0: VectorScale
void VectorScale(const Vector& in, float scale, Vector& out) {
    out.x = in.x * scale;
    out.y = in.y * scale;
    out.z = in.z * scale;
}

// -----------------------------------------------------------------------------
// Aimbot Angle Smoothing Choke Point
// RVA 0x2090C (0x04C7090C)
// -----------------------------------------------------------------------------
void __fastcall ApplyAngles(const Vector* pTargetAngles, Vector* pViewAngles, float flFrameTime) {
    static const float k_flHalf = 0.5f;   // 0x04C70998
    static const float k_flBase = 10.0f;  // 0x04C7099C
    static const float k_flZero = 0.0f;   // 0x04C709A0

    if (!pTargetAngles || !pViewAngles)
        return;

    Vector vDelta = *pTargetAngles;

    // Exponential decay and smoothing calculation
    float flSmoothFactor = vDelta.x;
    float flDecay = (flSmoothFactor * k_flHalf + k_flBase) * flFrameTime;
    flSmoothFactor -= flDecay;

    // Clamp to prevent overshoot
    if (flSmoothFactor < k_flZero) {
        flSmoothFactor = k_flZero;
    }

    Vector vScaled;
    VectorScale(vDelta, flSmoothFactor, vScaled);

    // Final injection into command angles
    pViewAngles->x -= (vScaled.x * 2.0f);
    pViewAngles->y -= (vScaled.y * 2.0f);
}

// -----------------------------------------------------------------------------
// INI Configuration Reader
// RVA 0x26120 (0x04C76120)
// -----------------------------------------------------------------------------
void LoadSettings(const char* pszIniPath) {
    const char* sec = "SETTINGS";

    g_Config.asuswallhack = GetPrivateProfileIntA(sec, "asuswallhack", 0, pszIniPath);
    g_Config.lambert      = GetPrivateProfileIntA(sec, "lambert", 0, pszIniPath);
    g_Config.playerglow   = GetPrivateProfileIntA(sec, "playerglow", 0, pszIniPath);
    g_Config.playerlight  = GetPrivateProfileIntA(sec, "playerlight", 0, pszIniPath);
    g_Config.whitewalls   = GetPrivateProfileIntA(sec, "whitewalls", 0, pszIniPath);
    g_Config.fullbright   = GetPrivateProfileIntA(sec, "fullbright", 0, pszIniPath);
    g_Config.nightmode    = GetPrivateProfileIntA(sec, "nightmode", 0, pszIniPath);
    g_Config.lesssmoke    = GetPrivateProfileIntA(sec, "lesssmoke", 0, pszIniPath);
    g_Config.lessflash    = GetPrivateProfileIntA(sec, "lessflash", 0, pszIniPath);
    g_Config.crosshair    = GetPrivateProfileIntA(sec, "crosshair", 0, pszIniPath);
    g_Config.norecoil     = GetPrivateProfileIntA(sec, "norecoil", 0, pszIniPath);

    g_Config.aimbot       = GetPrivateProfileIntA(sec, "aimbot", 0, pszIniPath);
    g_Config.aimspeed     = GetPrivateProfileIntA(sec, "aimspeed", 100, pszIniPath);
    g_Config.silentaim    = GetPrivateProfileIntA(sec, "silentaim", 0, pszIniPath);
    g_Config.aimteam      = GetPrivateProfileIntA(sec, "aimteam", 1, pszIniPath);
    g_Config.aimkey       = GetPrivateProfileIntA(sec, "aimkey", 1, pszIniPath);
    g_Config.aimspot      = GetPrivateProfileIntA(sec, "aimspot", 1, pszIniPath);
    g_Config.drawaimspot  = GetPrivateProfileIntA(sec, "drawaimspot", 0, pszIniPath);
    g_Config.aimfov       = GetPrivateProfileIntA(sec, "aimfov", 450, pszIniPath);
    g_Config.drawaimfov   = GetPrivateProfileIntA(sec, "drawaimfov", 0, pszIniPath);
    g_Config.aimthruwall  = GetPrivateProfileIntA(sec, "aimthruwall", 0, pszIniPath);

    g_Config.boxesp       = GetPrivateProfileIntA(sec, "boxesp", 0, pszIniPath);
    g_Config.nameesp      = GetPrivateProfileIntA(sec, "nameesp", 0, pszIniPath);
    g_Config.weaponesp    = GetPrivateProfileIntA(sec, "weaponesp", 0, pszIniPath);
    g_Config.distanceesp  = GetPrivateProfileIntA(sec, "distanceesp", 0, pszIniPath);
    g_Config.entityesp    = GetPrivateProfileIntA(sec, "entityesp", 0, pszIniPath);
    g_Config.glowents     = GetPrivateProfileIntA(sec, "glowents", 0, pszIniPath);
    g_Config.glownades    = GetPrivateProfileIntA(sec, "glownades", 0, pszIniPath);
    g_Config.stepesp      = GetPrivateProfileIntA(sec, "stepesp", 0, pszIniPath);

    g_Config.speedhack    = GetPrivateProfileIntA(sec, "speedhack", 0, pszIniPath);
    g_Config.barrelhack   = GetPrivateProfileIntA(sec, "barrelhack", 0, pszIniPath);
    g_Config.radar        = GetPrivateProfileIntA(sec, "radar", 0, pszIniPath);

    g_iAimMode = g_Config.norecoil;
}

// -----------------------------------------------------------------------------
// Engine Keyboard Hook (INSERT / F12 Menu Toggle)
// RVA 0x21133
// -----------------------------------------------------------------------------
int Hooked_HUD_Key_Event(int eventcode, int keynum, const char* pszCurrentBinding) {
    // 0x92 = F12, 0x2D / 0x93 = INSERT in GoldSrc
    if (eventcode == 1 && (keynum == 0x92 || keynum == 0x2D || keynum == 0x93)) {
        g_bMenuVisible = !g_bMenuVisible;
        return 0; // Consume keyboard event
    }
    return 1; // Pass event to engine
}

// -----------------------------------------------------------------------------
// CL_CreateMove Hook (Silent Aim)
// RVA 0x2530D
// -----------------------------------------------------------------------------
void Hooked_CL_CreateMove(float flFrameTime, struct usercmd_s* cmd, int active) {
    if (!cmd || !active)
        return;

    // Mode 1 = Silent Aim
    if (g_iAimMode == 1) {
        if (g_vTargetDelta.x != 0.0f || g_vTargetDelta.y != 0.0f) {
            ApplyAngles(&g_vTargetDelta, &cmd->viewangles, flFrameTime);
        }
    }
}
