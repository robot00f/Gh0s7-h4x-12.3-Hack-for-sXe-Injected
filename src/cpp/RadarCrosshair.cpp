/* ==============================================================================
   SEPARATE MODULE: RADAR, CROSSHAIR & AIM VISUALS
   (Radar, Crosshair, DrawAimSpot, DrawAimFov)
   Original RVAs in Dump:
     - Crosshair:   RVA 0x219C3..0x21D5D
     - Radar:       RVA 0x1FE0B (0x04C6FE0B)
     - DrawAimSpot: RVA 0x23C20 (0x04C73C20)
     - DrawAimFov:  RVA 0x200A7 (0x04C700A7)
   ============================================================================== */

#include <windows.h>
#include <cmath>

struct Vector { float x, y, z; };
struct Vector2D { float x, y; };

extern int g_iRadar;       // RVA 0x2E624 (0x04C7E624)
extern int g_iCrosshair;   // RVA 0x2E5F8 (0x04C7E5F8: 0=Off, 1=Dot, 2=Cross)
extern int g_iDrawAimSpot; // RVA 0x2E65C (0x04C7E65C)
extern int g_iDrawAimFov;  // RVA 0x2E644 (0x04C7E644)
extern int g_iAimFOV;      // RVA 0x2E648 (0x04C7E648)

extern void DrawBox2D(int x, int y, int w, int h, int r, int g, int b);
extern void DrawCircle(int x, int y, int radius, int r, int g, int b);
extern void DrawLine2D(int x1, int y1, int x2, int y2, int r, int g, int b);
extern bool WorldToScreen(const Vector& vWorld, Vector2D& vScreen);
extern Vector GetLocalPlayerOrigin();
extern Vector GetLocalPlayerViewAngles();
extern Vector GetEntityOrigin(int index);
extern int GetPlayerTeam(int index);
extern bool IsPlayerAlive(int index);

// -----------------------------------------------------------------------------
// 1. CUSTOM 2D CROSSHAIR (RVA 0x219C3..0x21D5D)
// -----------------------------------------------------------------------------
void DrawCustomCrosshair(int iScreenWidth, int iScreenHeight)
{
    if (g_iCrosshair == 0)
        return;

    int cx = iScreenWidth / 2;
    int cy = iScreenHeight / 2;

    // Mode 1: Center Red Dot
    if (g_iCrosshair == 1)
    {
        DrawBox2D(cx - 1, cy - 1, 3, 3, 255, 0, 0);
    }
    // Mode 2: Classic Cross (+ crosshair)
    else if (g_iCrosshair == 2)
    {
        int size = 6;
        int gap  = 2;
        // Horizontal bars
        DrawLine2D(cx - size - gap, cy, cx - gap, cy, 0, 255, 0);
        DrawLine2D(cx + gap, cy, cx + size + gap, cy, 0, 255, 0);
        // Vertical bars
        DrawLine2D(cx, cy - size - gap, cx, cy - gap, 0, 255, 0);
        DrawLine2D(cx, cy + gap, cx, cy + size + gap, 0, 255, 0);
    }
}

// -----------------------------------------------------------------------------
// 2. 2D RADAR WINDOW (RVA 0x1FE0B)
// -----------------------------------------------------------------------------
void DrawRadar(int rx, int ry, int rsize)
{
    if (g_iRadar == 0)
        return;

    // Draw radar background box and center lines
    DrawBox2D(rx, ry, rsize, rsize, 20, 20, 20);
    DrawLine2D(rx + rsize / 2, ry, rx + rsize / 2, ry + rsize, 50, 50, 50);
    DrawLine2D(rx, ry + rsize / 2, rx + rsize, ry + rsize / 2, 50, 50, 50);

    Vector vLocalOrigin = GetLocalPlayerOrigin();
    Vector vLocalAngles = GetLocalPlayerViewAngles();

    float flYawRad = vLocalAngles.y * (3.14159265f / 180.0f);
    float cosYaw = cosf(flYawRad);
    float sinYaw = sinf(flYawRad);

    int rcx = rx + rsize / 2;
    int rcy = ry + rsize / 2;
    float flRadarScale = 0.05f; // Zoom factor

    for (int i = 1; i <= 32; i++)
    {
        if (!IsPlayerAlive(i))
            continue;

        Vector vEntOrigin = GetEntityOrigin(i);
        float dx = vEntOrigin.x - vLocalOrigin.x;
        float dy = vEntOrigin.y - vLocalOrigin.y;

        // Rotate delta relative to local player Yaw orientation
        float rX = (dy * cosYaw - dx * sinYaw) * flRadarScale;
        float rY = (dx * cosYaw + dy * sinYaw) * flRadarScale;

        int px = rcx + (int)rX;
        int py = rcy - (int)rY;

        // Clamp inside radar boundary
        if (px >= rx && px <= (rx + rsize) && py >= ry && py <= (ry + rsize))
        {
            int iTeam = GetPlayerTeam(i);
            int r = (iTeam == 1) ? 255 : 0; // T: Red
            int b = (iTeam == 2) ? 255 : 0; // CT: Blue
            DrawBox2D(px - 1, py - 1, 3, 3, r, 50, b);
        }
    }
}

// -----------------------------------------------------------------------------
// 3. AIMBOT FOV CIRCLE & AIM SPOT VISUALS
// -----------------------------------------------------------------------------
void DrawAimbotVisuals(int iScreenWidth, int iScreenHeight, const Vector& vTargetBonePos, bool bHasTarget)
{
    int cx = iScreenWidth / 2;
    int cy = iScreenHeight / 2;

    // Draw FOV radius circle around crosshair (RVA 0x200A7)
    if (g_iDrawAimFov == 1 && g_iAimFOV > 0)
    {
        DrawCircle(cx, cy, g_iAimFOV, 255, 255, 255);
    }

    // Draw Aim Spot dot on the target bone (RVA 0x23C20)
    if (g_iDrawAimSpot == 1 && bHasTarget)
    {
        Vector2D sSpot;
        if (WorldToScreen(vTargetBonePos, sSpot))
        {
            DrawBox2D((int)sSpot.x - 2, (int)sSpot.y - 2, 5, 5, 255, 0, 0); // Red dot on target bone
        }
    }
}
