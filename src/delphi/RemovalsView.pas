unit RemovalsView;

{ ==============================================================================
  SEPARATE MODULE: REMOVALS & VIEWMODELS
  (LessSmoke, LessFlash, ChaseCam, QuakeGuns)
  Original RVAs in Dump:
    - LessSmoke:  RVA 0x2565B (0x04C7565B)
    - LessFlash:  RVA 0x25100 (0x04C75100)
    - ChaseCam:   RVA 0x212CC (0x04C712CC)
    - QuakeGuns:  RVA 0x2457B (0x04C7457B)
  ============================================================================== }

interface

uses
  Windows, SysUtils, Types, Config;

type
  PScreenFade = ^TScreenFade;
  TScreenFade = packed record
    FadeSpeed: Single;
    FadeEnd: Single;
    FadeTotalEnd: Single;
    FadeReset: Single;
    FadeR: Byte;
    FadeG: Byte;
    FadeB: Byte;
    FadeAlpha: Byte;
    FadeFlags: Integer;
  end;

  PRefParams = ^TRefParams;
  TRefParams = packed record
    ViewOrg: TVector3D;
    ViewAngles: TVector3D;
    Forward: TVector3D;
    Right: TVector3D;
    Up: TVector3D;
    Frametime: Single;
    Time: Single;
    Intermission: Integer;
    Paused: Integer;
    Spectator: Integer;
    OnGround: Integer;
    WaterLevel: Integer;
    SimVel: TVector3D;
    SimOrg: TVector3D;
    ViewHeight: TVector3D;
    IdealPitch: Single;
    ClViewAngles: TVector3D;
    Health: Integer;
    CrosshairAngle: TVector3D;
    ViewSize: Single;
    PunchAngle: array[0..2] of Single;
    MaxClients: Integer;
    ViewEntity: Integer;
    PlayerModel: Integer;
    CmdAngles: TVector3D;
    Hardware: Integer;
    OnlyClientDraw: Integer;
  end;

function FilterSmokeSprite(pszModelName: PAnsiChar): Boolean;
procedure ProcessLessFlash(pFade: PScreenFade);
procedure ProcessChaseCam(pParams: PRefParams);
procedure ProcessQuakeGuns(var ViewModelOrigin: TVector3D; const Forward, Right, Up: TVector3D);

implementation

{ -----------------------------------------------------------------------------
  1. LESS SMOKE / NO SMOKE FILTER (RVA 0x2565B)
  ----------------------------------------------------------------------------- }
function FilterSmokeSprite(pszModelName: PAnsiChar): Boolean;
var
  sName: AnsiString;
begin
  Result := False;
  if (g_Config.LessSmoke = 0) or (pszModelName = nil) then
    Exit;

  sName := AnsiString(pszModelName);
  if (Pos('gas_puff', sName) > 0) or
     (Pos('smokepuff', sName) > 0) or
     (Pos('black_smoke', sName) > 0) then
  begin
    Result := True; // Suppress rendering this smoke particle
  end;
end;

{ -----------------------------------------------------------------------------
  2. LESS FLASH / NO FLASH SUPPRESSION (RVA 0x25100)
  ----------------------------------------------------------------------------- }
procedure ProcessLessFlash(pFade: PScreenFade);
begin
  if (g_Config.LessFlash = 0) or (pFade = nil) then
    Exit;

  // Mode 1: Completely eliminate screen blindness
  if g_Config.LessFlash = 1 then
  begin
    pFade^.FadeAlpha := 0;
    pFade^.FadeEnd   := 0.0;
  end
  // Mode 2: Minimal tint (max 50/255 alpha)
  else if g_Config.LessFlash >= 2 then
  begin
    if pFade^.FadeAlpha > 50 then
      pFade^.FadeAlpha := 50;
  end;
end;

{ -----------------------------------------------------------------------------
  3. CHASE CAM / THIRDPERSON CAMERA (RVA 0x212CC)
  ----------------------------------------------------------------------------- }
procedure ProcessChaseCam(pParams: PRefParams);
const
  flChaseDistance: Single = 120.0;
begin
  if (g_Config.ChaseCam = 0) or (pParams = nil) then
    Exit;

  // Pull camera backwards along negative forward vector
  pParams^.ViewOrg.X := pParams^.ViewOrg.X - (pParams^.Forward.X * flChaseDistance);
  pParams^.ViewOrg.Y := pParams^.ViewOrg.Y - (pParams^.Forward.Y * flChaseDistance);
  pParams^.ViewOrg.Z := pParams^.ViewOrg.Z - (pParams^.Forward.Z * flChaseDistance) + 10.0;
end;

{ -----------------------------------------------------------------------------
  4. QUAKE GUNS / CENTERED VIEWMODEL (RVA 0x2457B)
  ----------------------------------------------------------------------------- }
procedure ProcessQuakeGuns(var ViewModelOrigin: TVector3D; const Forward, Right, Up: TVector3D);
begin
  if g_Config.QuakeGuns = 0 then
    Exit;

  // Center viewmodel horizontally
  ViewModelOrigin.X := ViewModelOrigin.X - (Right.X * 4.0);
  ViewModelOrigin.Y := ViewModelOrigin.Y - (Right.Y * 4.0);
  ViewModelOrigin.Z := ViewModelOrigin.Z - (Right.Z * 4.0) - 2.0;
end;

end.
