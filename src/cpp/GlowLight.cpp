/* ==============================================================================
   SEPARATE MODULE: GLOW & DYNAMIC LIGHTS
   (LocalGlow, PlayerGlow, PlayerLight, GlowEnts, GlowNades)
   Original RVAs in Dump:
     - LocalGlow:  RVA 0x22313 (0x04C72313)
     - PlayerGlow: RVA 0x2236C (0x04C7236C)
     - PlayerLight/Nades/Ents: RVA 0x223D0..0x22480
   ============================================================================== */

#include <windows.h>

struct Vector { float x, y, z; };

// GoldSrc Render Effects Enum
enum RenderFx {
    kRenderFxNone = 0,
    kRenderFxPulseFast,
    kRenderFxGlowShell = 19 // 0x13 in dump @ 0x04C7231C
};

struct cl_entity_s {
    int   index;
    int   player;
    Vector baseline_origin;
    Vector current_origin;
    Vector angles;
    // ...
    unsigned char padding[0x2FC - sizeof(Vector)*3 - 8];
    int   renderamt;        // Offset 0x2FC: Thickness (5 @ 0x04C7233B)
    unsigned char rendercolor[3]; // Offset 0x300: RGB (50, 50, 255 @ 0x04C72347)
    unsigned char renderfx;       // Offset 0x304: kRenderFxGlowShell (19 @ 0x04C7231C)
};

// Dynamic light structure (dlight_t)
struct dlight_t {
    Vector origin;
    float  radius;
    unsigned char color[3]; // R, G, B
    float  die;
    float  decay;
    float  minlight;
    int    key;
    bool   dark;
};

extern int g_iLocalGlow;   // RVA 0x2E618 (0x04C7E618)
extern int g_iPlayerGlow;  // RVA 0x2E63C (0x04C7E63C)
extern int g_iPlayerLight; // RVA 0x2E640 (0x04C7E640)
extern int g_iGlowEnts;    // RVA 0x2E668 (0x04C7E668)
extern int g_iGlowNades;   // RVA 0x2E664 (0x04C7E664)

typedef dlight_t* (*fnCL_AllocDlight)(int key);
extern fnCL_AllocDlight g_pfnCL_AllocDlight;
extern int GetPlayerTeam(int index);

// -----------------------------------------------------------------------------
// 1. PLAYER & LOCAL GLOW SHELL (RVA 0x22313)
// -----------------------------------------------------------------------------
void ApplyEntityGlow(cl_entity_s* ent, bool isLocalPlayer)
{
    if (!ent)
        return;

    // Check if local glow or player glow is active
    bool bShouldGlow = (isLocalPlayer && g_iLocalGlow == 1) ||
                       (!isLocalPlayer && g_iPlayerGlow == 1);

    if (bShouldGlow)
    {
        ent->renderfx  = kRenderFxGlowShell; // 0x13 (19)
        ent->renderamt = 5;                  // 5 thickness units

        int iTeam = GetPlayerTeam(ent->index);
        if (iTeam == 1) { // Terrorist: Red glow
            ent->rendercolor[0] = 255;
            ent->rendercolor[1] = 50;
            ent->rendercolor[2] = 50;
        } else { // CT or Local: Blue glow (RVA 0x22347: 0x32, 0x32, 0xFF)
            ent->rendercolor[0] = 50;
            ent->rendercolor[1] = 50;
            ent->rendercolor[2] = 255;
        }
    }
}

// -----------------------------------------------------------------------------
// 2. DYNAMIC LIGHT (PlayerLight & GlowNades)
// -----------------------------------------------------------------------------
void ApplyDynamicLight(int key, const Vector& origin, int r, int g, int b, float radius)
{
    if (!g_pfnCL_AllocDlight)
        return;

    dlight_t* dl = g_pfnCL_AllocDlight(key);
    if (dl)
    {
        dl->origin = origin;
        dl->radius = radius;
        dl->color[0] = (unsigned char)r;
        dl->color[1] = (unsigned char)g;
        dl->color[2] = (unsigned char)b;
        dl->die = 0.05f; // Fast refresh
        dl->decay = 300.0f;
    }
}

void ProcessGlowAndLights(cl_entity_s* ent, bool isLocalPlayer, bool isGrenade, bool isGroundEntity)
{
    if (!ent)
        return;

    // Player Glow
    ApplyEntityGlow(ent, isLocalPlayer);

    // Player Dynamic Light
    if (g_iPlayerLight == 1 && ent->player)
    {
        int iTeam = GetPlayerTeam(ent->index);
        int r = (iTeam == 1) ? 255 : 50;
        int b = (iTeam == 2) ? 255 : 50;
        ApplyDynamicLight(ent->index, ent->current_origin, r, 50, b, 200.0f);
    }

    // Grenade Glow Light
    if (g_iGlowNades == 1 && isGrenade)
    {
        ApplyDynamicLight(ent->index + 100, ent->current_origin, 0, 255, 0, 150.0f); // Green light
    }

    // Ground Weapon / C4 Glow Shell
    if (g_iGlowEnts == 1 && isGroundEntity)
    {
        ent->renderfx  = kRenderFxGlowShell;
        ent->renderamt = 3;
        ent->rendercolor[0] = 255;
        ent->rendercolor[1] = 255;
        ent->rendercolor[2] = 0; // Yellow glow on ground weapons
    }
}
