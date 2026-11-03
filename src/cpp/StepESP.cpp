/* ==============================================================================
   SEPARATE MODULE: STEPESP (SOUND ESP / FOOTSTEPS)
   Decompiled directly from payload_memory_dump.bin
   Forensic RVAs:
     - Sound capture hook: RVA 0x21190 (0x04C71190)
     - Footstep rendering: RVA 0x22108 (0x04C72108)
     - Circular buffer:    RVA 0x2D414 (0x04C7D414)
     - Mode selector:      RVA 0x201FB (0x04C701FB)
   ============================================================================== */

#include <windows.h>
#include <cmath>
#include <cstring>

// -----------------------------------------------------------------------------
// 1. DATA STRUCTURES & CIRCULAR BUFFER
// -----------------------------------------------------------------------------

struct Vector {
    float x, y, z;
};

struct Vector2D {
    float x, y;
};

// Record for each footstep entry in circular buffer (RVA 0x2D414)
struct StepEntry {
    Vector origin; // 3D coordinates (X, Y, Z) @ offset -0xC
    DWORD  dwTime; // GetTickCount() timestamp @ offset +0x0
};

// 32-step circular buffer (RVA 0x2D414)
static const int MAX_STEP_ENTRIES = 32;
static StepEntry g_StepBuffer[MAX_STEP_ENTRIES];
static int       g_iStepIndex = 0; // Rotating index (0..31) @ 0x04C7B068

// Configuration mode: 0 = Off, 1 = Text mode ("step"), 2 = 2D Circle
extern int g_iStepESP_Mode; // RVA 0x2E5EC (0x04C7E5EC)

typedef void (*fnPlaySoundByName)(int entindex, const char* szSample, float volume, 
                                  float attenuation, int fFlags, int pitch, Vector* origin);
extern fnPlaySoundByName g_pfnOriginalPlaySoundByName; // 0x04C7E744

extern bool WorldToScreen(const Vector& vWorld, Vector2D& vScreen);          // RVA 0x20668
extern void DrawString(int x, int y, const char* text, int r, int g, int b);  // RVA 0x20E48
extern void DrawCircle(int x, int y, int radius, int r, int g, int b);        // RVA 0x20D84
extern float VectorDistance(const Vector& a, const Vector& b);
extern Vector GetLocalPlayerOrigin();

// -----------------------------------------------------------------------------
// 2. SOUND CAPTURE (Hook of pfnPlaySoundByName @ RVA 0x21190)
// -----------------------------------------------------------------------------

void Hooked_PlaySoundByName(int entindex, const char* szSample, float volume, 
                            float attenuation, int fFlags, int pitch, Vector* pOrigin)
{
    // Replay original sound in engine
    if (g_pfnOriginalPlaySoundByName) {
        g_pfnOriginalPlaySoundByName(entindex, szSample, volume, attenuation, fFlags, pitch, pOrigin);
    }

    if (!pOrigin || !szSample)
        return;

    // Filter footstep sound samples: checks "step" (RVA 0x212B4) or "dirt" (RVA 0x212BC)
    bool bIsFootstep = (strstr(szSample, "step") != nullptr) || 
                       (strstr(szSample, "dirt") != nullptr);

    if (bIsFootstep) {
        // Increment rotating index (modulo 32)
        g_iStepIndex++;
        if (g_iStepIndex >= MAX_STEP_ENTRIES) {
            g_iStepIndex = 0;
        }

        // Store 3D coordinates and current time
        g_StepBuffer[g_iStepIndex].origin = *pOrigin;
        g_StepBuffer[g_iStepIndex].dwTime = GetTickCount(); // RVA 0x25C28
    }
}

// -----------------------------------------------------------------------------
// 3. STEP RENDERING (Invoked in HUD_Redraw @ RVA 0x22108)
// -----------------------------------------------------------------------------

void DrawStepESP(int iScreenWidth, int iScreenHeight)
{
    if (g_iStepESP_Mode == 0)
        return;

    DWORD dwNow = GetTickCount();
    Vector vLocalOrigin = GetLocalPlayerOrigin();

    for (int i = 0; i < MAX_STEP_ENTRIES; i++)
    {
        // 1. Timeout / Decay: 300 milliseconds (RVA 0x22137: cmp eax, 0x12C)
        DWORD dwDeltaTime = dwNow - g_StepBuffer[i].dwTime;
        if (dwDeltaTime >= 300) {
            continue;
        }

        // 2. World-to-Screen projection (RVA 0x20668)
        Vector2D vScreen;
        if (!WorldToScreen(g_StepBuffer[i].origin, vScreen)) {
            continue;
        }

        // 3. Clip points outside visible screen bounds
        if (vScreen.x <= 0.0f || vScreen.y <= 0.0f ||
            vScreen.x >= (float)iScreenWidth || vScreen.y >= (float)iScreenHeight) {
            continue;
        }

        int iScreenX = (int)std::floor(vScreen.x);
        int iScreenY = (int)std::floor(vScreen.y);

        // MODE 1: White text "step" (RVA 0x221AC)
        if (g_iStepESP_Mode == 1)
        {
            DrawString(iScreenX, iScreenY, "step", 255, 255, 255);
        }
        // MODE 2: Distance-scaled 2D Circle (RVA 0x221E0)
        else if (g_iStepESP_Mode == 2)
        {
            float flDistance = VectorDistance(vLocalOrigin, g_StepBuffer[i].origin);
            
            // Original scale constants: 22.0f (RVA 0x22280) and 150.0f (RVA 0x22284)
            float flRadius = 150.0f / (flDistance / 22.0f);

            if (flRadius < 2.0f)   flRadius = 2.0f;
            if (flRadius > 40.0f)  flRadius = 40.0f;

            DrawCircle(iScreenX, iScreenY, (int)flRadius, 255, 255, 255);
        }
    }
}
