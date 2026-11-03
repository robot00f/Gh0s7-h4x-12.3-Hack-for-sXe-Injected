unit VisualsOpenGL;

{ ==============================================================================
  SEPARATE MODULE: VISUALES OPENGL (AsusWallhack, Lambert, WhiteWalls, NightMode)
  RVA Original en Dump: 0x25490 (0x04C75490)
  ============================================================================== }

interface

uses
  Windows, Config;

const
  GL_POLYGON             = 9;
  GL_TRIANGLE_STRIP      = 5;
  GL_TRIANGLE_FAN        = 6;
  GL_DEPTH_TEST          = $0B71;
  GL_BLEND               = $0BE2;
  GL_TEXTURE_ENV         = $2300;
  GL_TEXTURE_ENV_MODE    = $2200;
  GL_DECAL               = $2101;
  GL_SRC_ALPHA           = $0302;
  GL_ONE_MINUS_SRC_ALPHA = $0303;

procedure Hooked_glBegin(mode: Cardinal); stdcall;

implementation

procedure glEnable(cap: Cardinal); stdcall; external 'opengl32.dll';
procedure glDisable(cap: Cardinal); stdcall; external 'opengl32.dll';
procedure glBlendFunc(sfactor, dfactor: Cardinal); stdcall; external 'opengl32.dll';
procedure glColor4f(red, green, blue, alpha: Single); stdcall; external 'opengl32.dll';
procedure glTexEnvi(target, pname, param: Integer); stdcall; external 'opengl32.dll';

procedure Hooked_glBegin(mode: Cardinal); stdcall;
begin
  // A. WhiteWalls (RVA 0x25496)
  if (g_Config.WhiteWalls = 1) and (mode = GL_POLYGON) then
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);

  // B. NightMode (RVA 0x254C2)
  if (g_Config.Nightmode = 1) and (mode = GL_POLYGON) then
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_BLEND);

  // C. Lambert / Chams (RVA 0x254EE)
  if (g_Config.Lambert = 1) and ((mode = GL_TRIANGLE_STRIP) or (mode = GL_TRIANGLE_FAN)) then
    glTexEnvi(GL_TEXTURE_ENV, GL_TEXTURE_ENV_MODE, GL_DECAL);

  // D. Asus Wallhack (RVA 0x2553E)
  if (g_Config.AsusWallhack = 1) and (mode = GL_POLYGON) then
  begin
    glDisable(GL_DEPTH_TEST);
    glEnable(GL_BLEND);
    glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    glColor4f(1.0, 1.0, 1.0, 0.5); // RVA 0x255EC: 0x3F000000 = 50% de opacidad
  end;
end;

end.
