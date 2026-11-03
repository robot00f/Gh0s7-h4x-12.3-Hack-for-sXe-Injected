/* ==============================================================================
   SEPARATE MODULE: BARRELHACK (3D Forward Laser Beam)
   Original RVA in Dump: 0x217B0 (0x04C717B0)
   ============================================================================== */

#include <windows.h>
#include <cmath>

struct Vector { float x, y, z; };

typedef void (*fnR_BeamPoints)(Vector* start, Vector* end, int modelIndex, 
                               float life, float width, float amplitude, float brightness, float speed, 
                               int startFrame, float framerate, float r, float g, float b);

extern int g_iBarrelHack;
extern int GetPlayerTeam(int index);

void DrawBarrelHack(int entIndex, const Vector& origin, const Vector& angles, 
                    int iBeamModelIndex, fnR_BeamPoints pfnBeamPoints)
{
    if (g_iBarrelHack == 0 || !pfnBeamPoints)
        return;

    Vector vStart = origin;
    vStart.z += 60.0f; // Eye level

    float sp = sinf(angles.x * (3.14159265f / 180.0f));
    float cp = cosf(angles.x * (3.14159265f / 180.0f));
    float sy = sinf(angles.y * (3.14159265f / 180.0f));
    float cy = cosf(angles.y * (3.14159265f / 180.0f));

    Vector vForward;
    vForward.x = cp * cy;
    vForward.y = cp * sy;
    vForward.z = -sp;

    // 8192 units forward reach (RVA 0x217A5)
    Vector vEnd;
    vEnd.x = vStart.x + vForward.x * 8192.0f;
    vEnd.y = vStart.y + vForward.y * 8192.0f;
    vEnd.z = vStart.z + vForward.z * 8192.0f;

    int iTeam = GetPlayerTeam(entIndex);
    float r = (iTeam == 1) ? 255.0f : 0.0f; // Terrorist = Red (RVA 0x217EA)
    float g = 0.0f;
    float b = (iTeam == 2) ? 255.0f : 0.0f; // CT = Blue (RVA 0x21836)

    pfnBeamPoints(&vStart, &vEnd, iBeamModelIndex, 
                  0.02f, 2.0f, 0.0f, 255.0f, 0.0f, 0, 30.0f, r, g, b);
}
