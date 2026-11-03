library Gh0s7H4x;

{ ==============================================================================
  COMPLETE RECONSTRUCTED PROJECT: Borland Delphi 6/7
  Original Binary: lolwut32.dll / gh0s7h4x11.dll (Dump: payload_memory_dump.bin)
  Target: Counter-Strike 1.6 (GoldSrc Engine / Half-Life 1)
  Purpose: Clean, modular, standalone reconstruction without protector overhead.
  ============================================================================== }

uses
  Windows,
  SysUtils,
  Types in 'Types.pas',
  Config in 'Config.pas',
  Math3D in 'Math3D.pas',
  Aimbot in 'Aimbot.pas',
  AimbotTarget in 'AimbotTarget.pas',
  Movement in 'Movement.pas',
  ESP in 'ESP.pas',
  StepESP in 'StepESP.pas',
  BarrelHack in 'BarrelHack.pas',
  GlowLight in 'GlowLight.pas',
  RadarCrosshair in 'RadarCrosshair.pas',
  VisualsOpenGL in 'VisualsOpenGL.pas',
  RemovalsView in 'RemovalsView.pas',
  WallhackExtra in 'WallhackExtra.pas',
  Hooks in 'Hooks.pas';

{$R *.res}

var
  g_hWorkerThread: THandle = 0;

function WorkerThreadProc(lpParameter: Pointer): DWORD; stdcall;
var
  hHW: HMODULE;
  szDllPath: array[0..MAX_PATH] of Char;
  szIniPath: string;
begin
  Result := 0;

  // Resolve DLL path and load configuration INI
  GetModuleFileNameA(hInstance, szDllPath, MAX_PATH);
  szIniPath := ExtractFilePath(string(szDllPath)) + 'gh0s7h4x12.ini';

  LoadConfig(szIniPath);

  // Wait for GoldSrc graphics engine (hw.dll or sw.dll) to load
  repeat
    hHW := GetModuleHandleA('hw.dll');
    if hHW = 0 then
      hHW := GetModuleHandleA('sw.dll');
    if hHW = 0 then
      Sleep(100);
  until hHW <> 0;

  // Initialize engine hooks
  InitializeEngineHooks;
end;

procedure DllMain(fdwReason: DWORD);
var
  dwThreadId: DWORD;
begin
  case fdwReason of
    DLL_PROCESS_ATTACH:
    begin
      DisableThreadLibraryCalls(hInstance);
      // Spawn safe initialization worker thread
      g_hWorkerThread := CreateThread(nil, 0, @WorkerThreadProc, nil, 0, dwThreadId);
    end;

    DLL_PROCESS_DETACH:
    begin
      ShutdownEngineHooks;
      if g_hWorkerThread <> 0 then
        CloseHandle(g_hWorkerThread);
    end;
  end;
end;

exports
  Hooked_HUD_Key_Event,
  Hooked_CL_CreateMove,
  Hooked_HUD_Redraw;

begin
  DllProc := @DllMain;
  DllMain(DLL_PROCESS_ATTACH);
end.
