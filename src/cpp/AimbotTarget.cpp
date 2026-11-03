/* ==============================================================================
   SEPARATE MODULE: AIMBOT TARGET SEARCH & FOV CHECK
   Original RVA in Dump: 0x24CE0 (0x04C74CE0)
   ============================================================================== */

#include <windows.h>
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

extern int g_iAimFOV;
extern int g_iAimSpot;
extern int g_iAimTeam;

extern bool WorldToScreen(const Vector& vWorld, Vector2D& vScreen);
extern cl_entity_s* GetEntityByIndex(int index);
extern int GetPlayerTeam(int index);
extern Vector GetPlayerBone(cl_entity_s* ent, int boneIndex);
extern Vector GetLocalPlayerOrigin();

bool FindBestTarget(int iScreenWidth, int iScreenHeight, Vector& vOutTargetAngles)
{
    float flScreenCenterX = (float)(iScreenWidth / 2);  // RVA 0x24CE4
    float flScreenCenterY = (float)(iScreenHeight / 2); // RVA 0x24D0A
    float flFovThreshold  = (float)g_iAimFOV;            // RVA 0x24CEA (0x04C7E648)

    int iBestTargetIndex = -1;
    float flMinDistanceToCrosshair = 999999.0f;

    for (int i = 1; i <= 32; i++)
    {
        cl_entity_s* ent = GetEntityByIndex(i);
        if (!ent || ent->is_dead != 0) // RVA 0x24D8B: dead check
            continue;

        // Friendly Fire Check
        if (g_iAimTeam == 0 && GetPlayerTeam(i) == GetPlayerTeam(0))
            continue;

        // Target Bone: 1 = Head (bone 8), 2 = Chest (bone 7) (RVA 0x23BF5)
        int iTargetBone = (g_iAimSpot == 1) ? 8 : 7;
        Vector vBonePos = GetPlayerBone(ent, iTargetBone);

        Vector2D vScreen;
        if (!WorldToScreen(vBonePos, vScreen))
            continue;

        // 2D Screen-space FOV Box Check (RVA 0x24D04..0x24D85)
        if (vScreen.x < (flScreenCenterX - flFovThreshold) ||
            vScreen.x > (flScreenCenterX + flFovThreshold) ||
            vScreen.y < (flScreenCenterY - flFovThreshold) ||
            vScreen.y > (flScreenCenterY + flFovThreshold))
        {
            continue; // Outside FOV
        }

        float flDistX = vScreen.x - flScreenCenterX;
        float flDistY = vScreen.y - flScreenCenterY;
        float flDistToCrosshair = std::sqrt(flDistX * flDistX + flDistY * flDistY);

        if (flDistToCrosshair < flMinDistanceToCrosshair)
        {
            flMinDistanceToCrosshair = flDistToCrosshair;
            iBestTargetIndex = i;

            Vector vLocalEye = GetLocalPlayerOrigin();
            vLocalEye.z += 64.0f; // Local view offset

            Vector vDir;
            vDir.x = vBonePos.x - vLocalEye.x;
            vDir.y = vBonePos.y - vLocalEye.y;
            vDir.z = vBonePos.z - vLocalEye.z;
            float flHyp = std::sqrt(vDir.x * vDir.x + vDir.y * vDir.y);

            vOutTargetAngles.x = -atan2f(vDir.z, flHyp) * (180.0f / 3.14159265f);
            vOutTargetAngles.y = atan2f(vDir.y, vDir.x) * (180.0f / 3.14159265f);
            vOutTargetAngles.z = 0.0f;
        }
    }

    return (iBestTargetIndex != -1);
}
