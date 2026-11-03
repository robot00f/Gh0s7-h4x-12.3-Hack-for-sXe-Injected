/* ==============================================================================
   SEPARATE MODULE: REMOVALS & VIEWMODELS
   (LessSmoke, LessFlash, ChaseCam, QuakeGuns)
   Original RVAs in Dump:
     - LessSmoke:  RVA 0x2565B (0x04C7565B)
     - LessFlash:  RVA 0x25100 (0x04C75100)
     - ChaseCam:   RVA 0x212CC (0x04C712CC)
     - QuakeGuns:  RVA 0x2457B (0x04C7457B)
   ============================================================================== */

#include <windows.h>
#include <gl/gl.h>
#include <cmath>
#include <cstring>

struct Vector { float x, y, z; };

// Screen fade structure for flashbang effect in GoldSrc (screenfade_s)
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

// View configuration parameters (ref_params_s)
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

extern int g_iLessSmoke;  // RVA 0x2E5E4 (0x04C7E5E4)
extern int g_iLessFlash;  // RVA 0x2E5E8 (0x04C7E5E8)
extern int g_iChaseCam;   // RVA 0x2E620 (0x04C7E620)
extern int g_iQuakeGuns;  // RVA 0x2E614 (0x04C7E614)

// -----------------------------------------------------------------------------
// 1. LESS SMOKE / NO SMOKE FILTER (RVA 0x2565B)
// -----------------------------------------------------------------------------
bool FilterSmokeSprite(const char* pszModelName)
{
    if (g_iLessSmoke == 0 || pszModelName == nullptr)
        return false;

    // Filter gas puff and smoke grenade particle sprites
    if (strstr(pszModelName, "gas_puff") != nullptr ||
        strstr(pszModelName, "smokepuff") != nullptr ||
        strstr(pszModelName, "black_smoke") != nullptr)
    {
        return true; // Suppress rendering this sprite particle
    }

    return false;
}

// -----------------------------------------------------------------------------
// 2. LESS FLASH / NO FLASH SUPPRESSION (RVA 0x25100)
// -----------------------------------------------------------------------------
void ProcessLessFlash(screenfade_s* pFade)
{
    if (g_iLessFlash == 0 || pFade == nullptr)
        return;

    // Mode 1: Completely eliminate screen blindness
    if (g_iLessFlash == 1)
    {
        pFade->fadealpha = 0;
        pFade->fadeEnd   = 0.0f;
    }
    // Mode 2: Transparent tint (max 50/255 alpha)
    else if (g_iLessFlash >= 2)
    {
        if (pFade->fadealpha > 50)
            pFade->fadealpha = 50;
    }
}

// -----------------------------------------------------------------------------
// 3. CHASE CAM / THIRDPERSON CAMERA (RVA 0x212CC)
// -----------------------------------------------------------------------------
void ProcessChaseCam(ref_params_s* pParams)
{
    if (g_iChaseCam == 0 || pParams == nullptr)
        return;

    // Pull camera backwards along negative forward vector
    const float flChaseDistance = 120.0f;
    pParams->vieworg.x -= pParams->forward.x * flChaseDistance;
    pParams->vieworg.y -= pParams->forward.y * flChaseDistance;
    pParams->vieworg.z -= pParams->forward.z * flChaseDistance + 10.0f; // slight height offset
}

// -----------------------------------------------------------------------------
// 4. QUAKE GUNS / CENTERED VIEWMODEL (RVA 0x2457B)
// -----------------------------------------------------------------------------
void ProcessQuakeGuns(Vector& vViewModelOrigin, const Vector& vForward, const Vector& vRight, const Vector& vUp)
{
    if (g_iQuakeGuns == 0)
        return;

    // Shift viewmodel from standard right-handed stance to exact screen center
    // Offsets: zero out lateral shift (Right vector) and slightly lower down
    vViewModelOrigin.x -= vRight.x * 4.0f;
    vViewModelOrigin.y -= vRight.y * 4.0f;
    vViewModelOrigin.z -= vRight.z * 4.0f + 2.0f;
}
