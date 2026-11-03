unit Aimbot;

interface

uses
  Types, Math3D, Config;

var
  g_vTargetDelta: TVector3D; // RVA 0x2E6B0 (0x04C7E6B0)
  g_bHasTarget: Boolean;

procedure ApplyAngles(const TargetDelta: TVector3D; var ViewAngles: TVector3D; FrameTime: Single);
procedure ProcessAimbot(cmd: PUserCmd; FrameTime: Single);

implementation

{ RVA 0x2090C (0x04C7090C): Core Aimbot Angle Smoothing Choke Point }
procedure ApplyAngles(const TargetDelta: TVector3D; var ViewAngles: TVector3D; FrameTime: Single);
const
  // Constants extracted from RVA 0x20998..0x209A0
  k_flHalf: Single = 0.5;   // 0x04C70998
  k_flBase: Single = 10.0;  // 0x04C7099C
  k_flZero: Single = 0.0;   // 0x04C709A0
var
  flSmoothFactor: Single;
  flDecay: Single;
  vScaledDelta: TVector3D;
begin
  // Exponential decay interpolation algorithm
  flSmoothFactor := TargetDelta.X;
  flDecay := (flSmoothFactor * k_flHalf + k_flBase) * FrameTime;
  flSmoothFactor := flSmoothFactor - flDecay;

  // Clamp against 0.0 to prevent aim oscillation
  if flSmoothFactor < k_flZero then
    flSmoothFactor := k_flZero;

  // Scale angular correction proportionally
  VectorScale(TargetDelta, flSmoothFactor, vScaledDelta);

  // Direct injection into Pitch and Yaw of usercmd->viewangles
  ViewAngles.X := ViewAngles.X - (vScaledDelta.X * 2.0);
  ViewAngles.Y := ViewAngles.Y - (vScaledDelta.Y * 2.0);

  NormalizeAngles(ViewAngles);
end;

procedure ProcessAimbot(cmd: PUserCmd; FrameTime: Single);
begin
  if (cmd = nil) or (g_Config.Aimbot = 0) then
    Exit;

  // If a target is acquired with valid angular delta
  if g_bHasTarget and ((g_vTargetDelta.X <> 0.0) or (g_vTargetDelta.Y <> 0.0)) then
  begin
    // Silent Aim (1) or Continuous Lock (2)
    if (g_Config.NoRecoil = 1) or (g_Config.NoRecoil = 2) then
    begin
      ApplyAngles(g_vTargetDelta, cmd^.viewangles, FrameTime);
    end;
  end;
end;

end.
