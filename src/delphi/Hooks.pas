unit Hooks;

{ ==============================================================================
  DISPATCHER & ENGINE HOOKS MODULE (Delphi)
  Hooks:
    - CL_CreateMove  (RVA 0x2530D)
    - HUD_Redraw     (RVA 0x24DA0)
    - HUD_Key_Event  (RVA 0x21133)
  ============================================================================== }

interface

uses
  Windows, Types, Config, Math3D, Aimbot, Movement, ESP, StepESP, RadarCrosshair, WallhackExtra;

type
  TfnCreateMove = procedure(frametime: Single; cmd: PUserCmd; active: Integer); cdecl;
  TfnHUD_Redraw = function(time: Single; intermission: Integer): Integer; cdecl;
  TfnHUD_Key_Event = function(eventcode: Integer; keynum: Integer; const pszCurrentBinding: PChar): Integer; cdecl;

var
  // Original GoldSrc Engine Function Pointers
  g_pfnOriginalCreateMove: TfnCreateMove = nil;
  g_pfnOriginalHUD_Redraw: TfnHUD_Redraw = nil;
  g_pfnOriginalHUD_Key_Event: TfnHUD_Key_Event = nil;

  // Menu State
  g_bMenuVisible: Boolean = False;

  // Fix for 0x4C7E724 Crash: Safe GetAsyncKeyState Pointer
  g_pfnGetAsyncKeyState: function(vKey: Integer): SmallInt; stdcall;

procedure InitializeEngineHooks;
procedure ShutdownEngineHooks;

function Hooked_HUD_Key_Event(eventcode: Integer; keynum: Integer; const pszCurrentBinding: PChar): Integer; cdecl;
procedure Hooked_CL_CreateMove(frametime: Single; cmd: PUserCmd; active: Integer); cdecl;
function Hooked_HUD_Redraw(time: Single; intermission: Integer): Integer; cdecl;

implementation

{ RVA 0x21133: Engine Keyboard Hook (INSERT / F12 Menu Toggle) }
function Hooked_HUD_Key_Event(eventcode: Integer; keynum: Integer; const pszCurrentBinding: PChar): Integer; cdecl;
begin
  // Key pressed (eventcode = 1)
  // keynum $92 = F12
  // keynum $2D / $93 = INSERT in GoldSrc
  if (eventcode = 1) and ((keynum = $92) or (keynum = $2D) or (keynum = $93)) then
  begin
    g_bMenuVisible := not g_bMenuVisible;
    Result := 0; // Consume event (do not transmit to game console)
    Exit;
  end;

  if Assigned(g_pfnOriginalHUD_Key_Event) then
    Result := g_pfnOriginalHUD_Key_Event(eventcode, keynum, pszCurrentBinding)
  else
    Result := 1;
end;

{ RVA 0x2530D: Movement Creation Hook (CL_CreateMove) }
procedure Hooked_CL_CreateMove(frametime: Single; cmd: PUserCmd; active: Integer); cdecl;
begin
  // Call original engine function first to build base usercmd
  if Assigned(g_pfnOriginalCreateMove) then
    g_pfnOriginalCreateMove(frametime, cmd, active);

  if (cmd = nil) or (active = 0) then
    Exit;

  // Process movement modifications (Bhop, FastRun, Speedhack)
  ProcessBhop(cmd);
  ProcessFastRun(cmd);
  ProcessSpeedhack(cmd);

  // Process aimbot and inject calculated angles
  ProcessAimbot(cmd, frametime);
end;

{ RVA 0x24DA0: HUD Rendering Hook (ESP, Crosshair, Radar and StepESP) }
function Hooked_HUD_Redraw(time: Single; intermission: Integer): Integer; cdecl;
var
  iScreenWidth, iScreenHeight: Integer;
begin
  if Assigned(g_pfnOriginalHUD_Redraw) then
    Result := g_pfnOriginalHUD_Redraw(time, intermission)
  else
    Result := 1;

  iScreenWidth := 1024;
  iScreenHeight := 768;

  // Render Visual Modules
  DrawPlayerESP(iScreenWidth, iScreenHeight);
  DrawEntityESP(iScreenWidth, iScreenHeight);
  DrawStepESP;
  DrawCustomCrosshair(iScreenWidth, iScreenHeight);
  DrawRadar(15, 15, 140);
  DrawAimbotVisuals(iScreenWidth, iScreenHeight, g_vTargetDelta, g_bHasTarget);
end;

procedure InitializeEngineHooks;
var
  hUser32: HMODULE;
begin
  // Defensive initialization of GetAsyncKeyState (prevents crash 0x4C7E724)
  hUser32 := GetModuleHandleA('user32.dll');
  if hUser32 <> 0 then
    @g_pfnGetAsyncKeyState := GetProcAddress(hUser32, 'GetAsyncKeyState')
  else
    @g_pfnGetAsyncKeyState := @Windows.GetAsyncKeyState;
end;

procedure ShutdownEngineHooks;
begin
  // Restore engine function pointers if hooked
end;

end.
