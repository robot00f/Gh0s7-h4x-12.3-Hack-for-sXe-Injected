unit RadarCrosshair;

{ ==============================================================================
  SEPARATE MODULE: RADAR, CROSSHAIR & AIM VISUALS
  (Radar, Crosshair, DrawAimSpot, DrawAimFov)
  Original RVAs in Dump:
    - Crosshair:   RVA 0x219C3..0x21D5D
    - Radar:       RVA 0x1FE0B (0x04C6FE0B)
    - DrawAimSpot: RVA 0x23C20 (0x04C73C20)
    - DrawAimFov:  RVA 0x200A7 (0x04C700A7)
  ============================================================================== }

interface

uses
  Windows, Types, Config;

procedure DrawCustomCrosshair(iScreenWidth, iScreenHeight: Integer);
procedure DrawRadar(rx, ry, rsize: Integer);
procedure DrawAimbotVisuals(iScreenWidth, iScreenHeight: Integer; const TargetBonePos: TVector3D; HasTarget: Boolean);

implementation

{ External graphics and engine helper imports }
procedure DrawBox2D(x, y, w, h, r, g, b: Integer); external 'hw.dll';
procedure DrawCircle(x, y, radius, r, g, b: Integer); external 'hw.dll';
procedure DrawLine2D(x1, y1, x2, y2, r, g, b: Integer); external 'hw.dll';
function WorldToScreen(const WorldPos: TVector3D; var ScreenPos: TVector2D): Boolean; external 'hw.dll';
function GetLocalPlayerOrigin: TVector3D; external 'hw.dll';
function GetLocalPlayerViewAngles: TVector3D; external 'hw.dll';
function GetEntityOrigin(index: Integer): TVector3D; external 'hw.dll';
function GetPlayerTeam(index: Integer): Integer; external 'hw.dll';
function IsPlayerAlive(index: Integer): Boolean; external 'hw.dll';

{ -----------------------------------------------------------------------------
  1. CUSTOM 2D CROSSHAIR (RVA 0x219C3..0x21D5D)
  ----------------------------------------------------------------------------- }
procedure DrawCustomCrosshair(iScreenWidth, iScreenHeight: Integer);
var
  cx, cy: Integer;
  size, gap: Integer;
begin
  if g_Config.Crosshair = 0 then
    Exit;

  cx := iScreenWidth div 2;
  cy := iScreenHeight div 2;

  // Mode 1: Center Red Dot
  if g_Config.Crosshair = 1 then
  begin
    DrawBox2D(cx - 1, cy - 1, 3, 3, 255, 0, 0);
  end
  // Mode 2: Classic Cross (+ crosshair)
  else if g_Config.Crosshair = 2 then
  begin
    size := 6;
    gap  := 2;
    // Horizontal bars
    DrawLine2D(cx - size - gap, cy, cx - gap, cy, 0, 255, 0);
    DrawLine2D(cx + gap, cy, cx + size + gap, cy, 0, 255, 0);
    // Vertical bars
    DrawLine2D(cx, cy - size - gap, cx, cy - gap, 0, 255, 0);
    DrawLine2D(cx, cy + gap, cx, cy + size + gap, 0, 255, 0);
  end;
end;

{ -----------------------------------------------------------------------------
  2. 2D RADAR WINDOW (RVA 0x1FE0B)
  ----------------------------------------------------------------------------- }
procedure DrawRadar(rx, ry, rsize: Integer);
const
  flRadarScale: Single = 0.05; // Radar Zoom factor
var
  vLocalOrigin, vLocalAngles, vEntOrigin: TVector3D;
  flYawRad, cosYaw, sinYaw: Single;
  rcx, rcy: Integer;
  i, px, py: Integer;
  dx, dy, rX, rY: Single;
  iTeam, r, b: Integer;
begin
  if g_Config.Radar = 0 then
    Exit;

  // Draw radar background box and center lines
  DrawBox2D(rx, ry, rsize, rsize, 20, 20, 20);
  DrawLine2D(rx + rsize div 2, ry, rx + rsize div 2, ry + rsize, 50, 50, 50);
  DrawLine2D(rx, ry + rsize div 2, rx + rsize, ry + rsize div 2, 50, 50, 50);

  vLocalOrigin := GetLocalPlayerOrigin;
  vLocalAngles := GetLocalPlayerViewAngles;

  flYawRad := vLocalAngles.Y * (3.14159265 / 180.0);
  cosYaw := Cos(flYawRad);
  sinYaw := Sin(flYawRad);

  rcx := rx + rsize div 2;
  rcy := ry + rsize div 2;

  for i := 1 to 32 do
  begin
    if not IsPlayerAlive(i) then
      Continue;

    vEntOrigin := GetEntityOrigin(i);
    dx := vEntOrigin.X - vLocalOrigin.X;
    dy := vEntOrigin.Y - vLocalOrigin.Y;

    // Rotate delta relative to local player Yaw orientation
    rX := (dy * cosYaw - dx * sinYaw) * flRadarScale;
    rY := (dx * cosYaw + dy * sinYaw) * flRadarScale;

    px := rcx + Round(rX);
    py := rcy - Round(rY);

    // Clamp inside radar boundary
    if (px >= rx) and (px <= (rx + rsize)) and (py >= ry) and (py <= (ry + rsize)) then
    begin
      iTeam := GetPlayerTeam(i);
      if iTeam = 1 then
        r := 255
      else
        r := 0; // T: Red

      if iTeam = 2 then
        b := 255
      else
        b := 0; // CT: Blue

      DrawBox2D(px - 1, py - 1, 3, 3, r, 50, b);
    end;
  end;
end;

{ -----------------------------------------------------------------------------
  3. AIMBOT FOV CIRCLE & AIM SPOT VISUALS
  ----------------------------------------------------------------------------- }
procedure DrawAimbotVisuals(iScreenWidth, iScreenHeight: Integer; const TargetBonePos: TVector3D; HasTarget: Boolean);
var
  cx, cy: Integer;
  sSpot: TVector2D;
begin
  cx := iScreenWidth div 2;
  cy := iScreenHeight div 2;

  // Draw FOV radius circle around crosshair (RVA 0x200A7)
  if (g_Config.DrawAimFov = 1) and (g_Config.AimFov > 0) then
  begin
    DrawCircle(cx, cy, g_Config.AimFov, 255, 255, 255);
  end;

  // Draw Aim Spot dot on the target bone (RVA 0x23C20)
  if (g_Config.DrawAimSpot = 1) and HasTarget then
  begin
    if WorldToScreen(TargetBonePos, sSpot) then
    begin
      DrawBox2D(Round(sSpot.X) - 2, Round(sSpot.Y) - 2, 5, 5, 255, 0, 0); // Red dot on target bone
    end;
  end;
end;

end.
