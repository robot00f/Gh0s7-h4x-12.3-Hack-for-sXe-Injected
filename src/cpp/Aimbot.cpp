/* ==============================================================================
   SEPARATE MODULE: AIMBOT CORE & ANGLE DECAY CHOKE POINT
   Original RVAs in Dump:
     - ApplyAngles:   RVA 0x2090C (0x04C7090C)
     - Constants:     RVA 0x20998..0x209A0
     - ProcessAimbot: RVA 0x200C0
   ============================================================================== */

#include <windows.h>
#include <cmath>

struct Vector {
    float x, y, z;
};

#define IN_ATTACK (1 << 0)

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

extern Vector g_vTargetDelta; // RVA 0x2E6B0 (0x04C7E6B0)
extern bool   g_bHasTarget;
extern int    g_iAimbot;      // RVA 0x2E5FC (0x04C7E5FC)
extern int    g_iNoRecoil;    // RVA 0x2E61C (0x04C7E61C)
extern int    g_iAimKey;      // RVA 0x2E64C (0x04C7E64C)

void NormalizeAngles(Vector& angles)
{
    while (angles.x > 89.0f)  angles.x -= 180.0f;
    while (angles.x < -89.0f) angles.x += 180.0f;
    while (angles.y > 180.0f) angles.y -= 360.0f;
    while (angles.y < -180.0f) angles.y += 360.0f;
    angles.z = 0.0f;
}

// -----------------------------------------------------------------------------
// RVA 0x2090C (0x04C7090C): Core Aimbot Angle Smoothing Choke Point
// -----------------------------------------------------------------------------
void __fastcall ApplyAngles(const Vector* pTargetDelta, Vector* pViewAngles, float flFrameTime)
{
    // Constants extracted from RVA 0x20998..0x209A0
    static const float k_flHalf = 0.5f;   // 0x04C70998
    static const float k_flBase = 10.0f;  // 0x04C7099C
    static const float k_flZero = 0.0f;   // 0x04C709A0

    if (!pTargetDelta || !pViewAngles)
        return;

    // Exponential decay interpolation algorithm
    float flSmoothFactor = pTargetDelta->x;
    float flDecay = (flSmoothFactor * k_flHalf + k_flBase) * flFrameTime;
    flSmoothFactor -= flDecay;

    // Clamp against 0.0 to prevent aim oscillation
    if (flSmoothFactor < k_flZero)
        flSmoothFactor = k_flZero;

    // Direct injection into Pitch and Yaw of usercmd->viewangles
    pViewAngles->x -= (pTargetDelta->x * flSmoothFactor * 2.0f);
    pViewAngles->y -= (pTargetDelta->y * flSmoothFactor * 2.0f);

    NormalizeAngles(*pViewAngles);
}

// -----------------------------------------------------------------------------
// Aimbot Command Dispatcher
// -----------------------------------------------------------------------------
void ProcessAimbot(usercmd_s* cmd, float flFrameTime)
{
    if (!cmd || g_iAimbot == 0)
        return;

    // Aimkey check (Default 1 = IN_ATTACK)
    if (g_iAimKey == 1 && !(cmd->buttons & IN_ATTACK))
        return;

    // If a target is acquired with valid angular delta
    if (g_bHasTarget && (g_vTargetDelta.x != 0.0f || g_vTargetDelta.y != 0.0f))
    {
        // Silent Aim (1) or Continuous Lock (2)
        if (g_iNoRecoil == 1 || g_iNoRecoil == 2)
        {
            ApplyAngles(&g_vTargetDelta, &cmd->viewangles, flFrameTime);
        }
    }
}
