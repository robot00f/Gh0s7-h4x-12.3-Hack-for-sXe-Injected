/* ==============================================================================
   SEPARATE MODULE: VISUALES OPENGL (AsusWallhack, Lambert, WhiteWalls, NightMode)
   RVA Original en Dump: 0x25490 (0x04C75490)
   ============================================================================== */

#include <windows.h>
#include <gl/gl.h>

extern int g_iAsusWallhack;
extern int g_iLambert;
extern int g_iWhiteWalls;
extern int g_iNightMode;

typedef void (APIENTRY *fn_glBegin)(GLenum mode);
extern fn_glBegin g_pfnOriginal_glBegin;

void Hooked_glBegin(GLenum mode)
{
    // A. WhiteWalls (RVA 0x25496)
    if (g_iWhiteWalls == 1 && mode == GL_POLYGON) {
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
    }

    // B. NightMode (RVA 0x254C2)
    if (g_iNightMode == 1 && mode == GL_POLYGON) {
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_BLEND);
    }

    // C. Lambert / Chams en Modelos (RVA 0x254EE: GL_TRIANGLE_STRIP / FAN)
    if (g_iLambert == 1 && (mode == GL_TRIANGLE_STRIP || mode == GL_TRIANGLE_FAN)) {
        glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);
    }

    // D. Asus Wallhack (RVA 0x2553E: glDisable DEPTH_TEST + Alpha 0.5f)
    if (g_iAsusWallhack == 1 && mode == GL_POLYGON) {
        glDisable(GL_DEPTH_TEST);
        glEnable(GL_BLEND);
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        glColor4f(1.0f, 1.0f, 1.0f, 0.5f); // 50% transparencia
    }

    if (g_pfnOriginal_glBegin) {
        g_pfnOriginal_glBegin(mode);
    }
}
