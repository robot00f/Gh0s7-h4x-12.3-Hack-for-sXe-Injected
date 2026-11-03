/* ==============================================================================
   SEPARATE MODULE: MOVEMENT (Bhop, FastRun, Speedhack)
   Original RVAs in Dump:
     - Bhop:      RVA 0x252BF (0x04C752BF)
     - FastRun:   RVA 0x25131 (0x04C75131)
     - Speedhack: RVA 0x24754 (0x04C74754)
   ============================================================================== */

#include <windows.h>

struct Vector { float x, y, z; };

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

#define IN_ATTACK   (1 << 0)
#define IN_JUMP     (1 << 1)
#define IN_FORWARD  (1 << 3)
#define FL_ONGROUND (1 << 9) // 0x200 flag in GoldSrc

extern int g_iBhop;       // RVA 0x2E60C (0x04C7E60C)
extern int g_iFastRun;    // RVA 0x2E610 (0x04C7E610)
extern int g_iSpeedhack;  // RVA 0x2E634 (0x04C7E634: e.g. 5)

extern int GetLocalPlayerFlags(); // Returns entity flags (e.g., FL_ONGROUND)

// -----------------------------------------------------------------------------
// 1. AUTO BUNNYHOP (RVA 0x252BF)
// -----------------------------------------------------------------------------
void ProcessBhop(usercmd_s* cmd)
{
    if (g_iBhop != 1 || !cmd)
        return;

    // Check if the user is holding down the JUMP button
    if (cmd->buttons & IN_JUMP)
    {
        int flags = GetLocalPlayerFlags();

        // If player is airborne (NOT on the ground), release jump key to prevent deceleration
        if (!(flags & FL_ONGROUND))
        {
            cmd->buttons &= ~IN_JUMP;
        }
        // When player touches the ground, IN_JUMP remains pressed -> instant auto jump
    }
}

// -----------------------------------------------------------------------------
// 2. FASTRUN / STRAFE ACCELERATOR (RVA 0x25131)
// -----------------------------------------------------------------------------
void ProcessFastRun(usercmd_s* cmd)
{
    if (g_iFastRun != 1 || !cmd)
        return;

    int flags = GetLocalPlayerFlags();
    if (!(flags & FL_ONGROUND))
        return;

    // If moving forward and on ground, alternate sideways movement to maximize speed
    if (cmd->buttons & IN_FORWARD)
    {
        static bool bStrafeToggle = false;
        bStrafeToggle = !bStrafeToggle;

        if (bStrafeToggle) {
            cmd->sidemove = 250.0f;
        } else {
            cmd->sidemove = -250.0f;
        }
    }
}

// -----------------------------------------------------------------------------
// 3. SPEEDHACK (RVA 0x24754)
// -----------------------------------------------------------------------------
void ProcessSpeedhack(usercmd_s* cmd)
{
    if (g_iSpeedhack <= 1 || !cmd)
        return;

    // In GoldSrc, speedhack scales the usercmd msec and frametime tick
    // Default msec is typically 10..25 ms
    unsigned int scaledMsec = (unsigned int)(cmd->msec * g_iSpeedhack);
    if (scaledMsec > 255) {
        scaledMsec = 255;
    }
    cmd->msec = (unsigned char)scaledMsec;
}
