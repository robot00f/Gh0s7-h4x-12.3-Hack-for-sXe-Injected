/* ==============================================================================
   SEPARATE MODULE: ESP (BoxESP, NameESP, WeaponESP, DistanceESP)
   Original RVA in Dump: 0x224D0 (0x04C724D0)
   ============================================================================== */

#include <windows.h>
#include <cstdio>
#include <cmath>

struct Vector { float x, y, z; };
struct Vector2D { float x, y; };

struct cl_entity_s {
    int   index;
    int   player;
    Vector baseline_origin;
    Vector current_origin;
    Vector angles;
    unsigned char padding[0x360 - sizeof(Vector)*3 - 8];
    int   is_dead; // Offset 0x360: 0=Alive, !=0=Dead (RVA 0x24D8B)
};

extern int g_iBoxESP;
extern int g_iNameESP;
extern int g_iWeaponESP;
extern int g_iDistanceESP;

extern bool WorldToScreen(const Vector& vWorld, Vector2D& vScreen);
extern void DrawString(int x, int y, const char* text, int r, int g, int b);
extern void DrawBox2D(int x, int y, int w, int h, int r, int g, int b);
extern float VectorDistance(const Vector& a, const Vector& b);
extern cl_entity_s* GetEntityByIndex(int index);
extern int GetPlayerTeam(int index);
extern const char* GetPlayerName(int index);
extern const char* GetPlayerWeapon(int index);
extern Vector GetLocalPlayerOrigin();

void DrawPlayerESP(int iScreenWidth, int iScreenHeight)
{
    Vector vLocalOrigin = GetLocalPlayerOrigin();

    for (int i = 1; i <= 32; i++)
    {
        cl_entity_s* ent = GetEntityByIndex(i);
        if (!ent || ent->is_dead != 0)
            continue;

        Vector vBottom = ent->current_origin;
        Vector vTop = vBottom;
        vTop.z += 72.0f; // Standard Half-Life player model height

        Vector2D sBottom, sTop;
        if (!WorldToScreen(vBottom, sBottom) || !WorldToScreen(vTop, sTop))
            continue;

        if (sBottom.x <= 0 || sBottom.y <= 0 || sBottom.x >= iScreenWidth || sBottom.y >= iScreenHeight)
            continue;

        int iHeight = (int)(sBottom.y - sTop.y);
        int iWidth  = iHeight / 2;
        int iLeft   = (int)(sTop.x - (iWidth / 2));
        int iTopY   = (int)sTop.y;

        int iTeam = GetPlayerTeam(i);
        int r = (iTeam == 1) ? 255 : 0; // Terrorist: Red
        int g = 0;
        int b = (iTeam == 2) ? 255 : 0; // CT: Blue
        if (iTeam != 1 && iTeam != 2) { r = 255; g = 255; b = 255; }

        // Box ESP (RVA 0x224D4)
        if (g_iBoxESP > 0) {
            DrawBox2D(iLeft, iTopY, iWidth, iHeight, r, g, b);
        }

        // Name ESP (RVA 0x22516)
        if (g_iNameESP == 1) {
            DrawString((int)sTop.x, iTopY - 12, GetPlayerName(i), 255, 255, 255);
        }

        // Weapon ESP (RVA 0x22558)
        if (g_iWeaponESP == 1) {
            DrawString((int)sTop.x, (int)sBottom.y + 2, GetPlayerWeapon(i), 255, 255, 0);
        }

        // Distance ESP (RVA 0x225A8)
        if (g_iDistanceESP == 1) {
            float flDist = VectorDistance(vLocalOrigin, ent->current_origin);
            char szDist[32];
            sprintf_s(szDist, "%.0f m", flDist / 39.37f);
            DrawString((int)sTop.x, (int)sBottom.y + 14, szDist, 0, 255, 0);
        }
    }
}
