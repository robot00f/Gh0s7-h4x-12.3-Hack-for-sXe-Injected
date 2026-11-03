/* ==============================================================================
   SEPARATE MODULE: ADVANCED WALLHACK & ENTITY ESP
   (SimpleWall, Niggers/BlackModels, EntityESP, AimThruWall)
   Original RVAs in Dump:
     - SimpleWall:  RVA 0x1F27D (0x04C6F27D) -> 0x04C7E5D0
     - Niggers:     RVA 0x1F3EC (0x04C6F3EC) -> 0x04C7E5F0 (Silhouette Models)
     - EntityESP:   RVA 0x1FB50 (0x04C6FB50) -> 0x04C7E658
     - AimThruWall: RVA 0x20084 (0x04C70084) -> 0x04C7E638
   ============================================================================== */

#include <windows.h>
#include <gl/gl.h>
#include <cmath>
#include <cstring>

struct Vector { float x, y, z; };
struct Vector2D { float x, y; };

struct cl_entity_s {
    int   index;
    int   player;
    Vector baseline_origin;
    Vector current_origin;
    Vector angles;
    char* model_name;
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

extern int g_iSimpleWall;   // RVA 0x2E5D0 (0x04C7E5D0)
extern int g_iNiggers;      // RVA 0x2E5F0 (0x04C7E5F0: Unlit Silhouette Player Models)
extern int g_iEntityESP;    // RVA 0x2E658 (0x04C7E658)
extern int g_iAimThruWall;  // RVA 0x2E638 (0x04C7E638)

extern bool WorldToScreen(const Vector& vWorld, Vector2D& vScreen);
extern void DrawBox2D(int x, int y, int w, int h, int r, int g, int b);
extern void DrawString(int x, int y, const char* text, int r, int g, int b);
extern cl_entity_s* GetEntityByIndex(int index);
extern void EngineTraceLine(const Vector& start, const Vector& end, int flags, cl_entity_s* skipEnt, trace_t* tr);

// -----------------------------------------------------------------------------
// 1. SIMPLE WALLHACK (Depth Range Modification @ RVA 0x1F27D)
// -----------------------------------------------------------------------------
void BeginSimpleWallhack(bool isPlayerModel)
{
    if (g_iSimpleWall == 1 && isPlayerModel)
    {
        // Force model depth to render in front of world geometry
        glDepthRange(0.0f, 0.45f);
        glDisable(GL_DEPTH_TEST);
    }
}

void EndSimpleWallhack(bool isPlayerModel)
{
    if (g_iSimpleWall == 1 && isPlayerModel)
    {
        glDepthRange(0.0f, 1.0f);
        glEnable(GL_DEPTH_TEST);
    }
}

// -----------------------------------------------------------------------------
// 2. UNLIT SILHOUETTE MODELS (RVA 0x1F3EC)
// -----------------------------------------------------------------------------
void ApplyModelShader(bool isPlayerModel)
{
    if (g_iNiggers == 1 && isPlayerModel)
    {
        // Disable texture mapping and draw pure black high-contrast silhouette
        glDisable(GL_TEXTURE_2D);
        glColor3ub(0, 0, 0);
    }
}

void RestoreModelShader(bool isPlayerModel)
{
    if (g_iNiggers == 1 && isPlayerModel)
    {
        glEnable(GL_TEXTURE_2D);
        glColor3ub(255, 255, 255);
    }
}

// -----------------------------------------------------------------------------
// 3. GROUND ENTITY ESP (Weapons, C4, Hostages @ RVA 0x1FB50)
// -----------------------------------------------------------------------------
void DrawEntityESP(int iScreenWidth, int iScreenHeight)
{
    if (g_iEntityESP == 0)
        return;

    // Non-player entities occupy indices 33 to 256 in GoldSrc
    for (int i = 33; i < 256; i++)
    {
        cl_entity_s* ent = GetEntityByIndex(i);
        if (!ent || !ent->model_name || ent->model_name[0] == '\0')
            continue;

        const char* name = ent->model_name;
        const char* label = nullptr;
        int r = 255, g = 255, b = 255;

        // Identify dropped C4 Bomb
        if (strstr(name, "w_c4") != nullptr)
        {
            label = "[C4 BOMB]";
            r = 255; g = 50; b = 50;
        }
        // Identify Hostages
        else if (strstr(name, "hostage") != nullptr)
        {
            label = "[HOSTAGE]";
            r = 50; g = 255; b = 50;
        }
        // Identify Dropped Weapons
        else if (strstr(name, "models/w_") != nullptr)
        {
            // Strip "models/w_" and ".mdl"
            label = name + 9;
            r = 255; g = 215; b = 0; // Gold
        }

        if (label != nullptr)
        {
            Vector2D sPos;
            if (WorldToScreen(ent->current_origin, sPos))
            {
                if (sPos.x > 0 && sPos.y > 0 && sPos.x < iScreenWidth && sPos.y < iScreenHeight)
                {
                    DrawBox2D((int)sPos.x - 2, (int)sPos.y - 2, 4, 4, r, g, b);
                    DrawString((int)sPos.x + 4, (int)sPos.y - 4, label, r, g, b);
                }
            }
        }
    }
}

// -----------------------------------------------------------------------------
// 4. AUTOWALL PENETRATION CHECK (RVA 0x20084)
// -----------------------------------------------------------------------------
bool CanPenetrateWall(const Vector& vStart, const Vector& vTarget, cl_entity_s* pLocalEnt, cl_entity_s* pTargetEnt)
{
    trace_t tr;
    EngineTraceLine(vStart, vTarget, 0, pLocalEnt, &tr);

    // Direct line of sight: no wall in between
    if (tr.fraction >= 1.0f || tr.ent == pTargetEnt)
        return true;

    // If Autowall is disabled, wall blocks aimbot
    if (g_iAimThruWall == 0)
        return false;

    // Check distance through obstacle
    Vector vWallEntry = tr.endpos;
    trace_t trReverse;
    EngineTraceLine(vTarget, vStart, 0, pTargetEnt, &trReverse);

    Vector vWallExit = trReverse.endpos;
    float dx = vWallExit.x - vWallEntry.x;
    float dy = vWallExit.y - vWallEntry.y;
    float dz = vWallExit.z - vWallEntry.z;
    float flWallThickness = sqrtf(dx * dx + dy * dy + dz * dz);

    // Standard GoldSrc penetration threshold: max ~18 units of wall penetration
    return (flWallThickness <= 18.0f);
}
