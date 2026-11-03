unit Types;

interface

uses
  Windows;

type
  { 3D Vector in single precision (float) }
  TVector3D = packed record
    X: Single; // X coordinate / Pitch angle
    Y: Single; // Y coordinate / Yaw angle
    Z: Single; // Z coordinate / Roll angle
  end;
  PVector3D = ^TVector3D;

  { 2D Screen Vector }
  TVector2D = packed record
    X: Single;
    Y: Single;
  end;
  PVector2D = ^TVector2D;

  { GoldSrc / Half-Life Engine User Command (usercmd_s) }
  TUserCmd = packed record
    lerp_msec: SmallInt;
    msec: Byte;
    viewangles: TVector3D;
    forwardmove: Single;
    sidemove: Single;
    upmove: Single;
    lightlevel: Byte;
    buttons: Word;
    impulse: Byte;
    weaponselect: Byte;
    impact_index: Integer;
    impact_position: TVector3D;
  end;
  PUserCmd = ^TUserCmd;

  { GoldSrc Button Bitmasks }
  const
    IN_ATTACK    = (1 shl 0);
    IN_JUMP      = (1 shl 1);
    IN_DUCK      = (1 shl 2);
    IN_FORWARD   = (1 shl 3);
    IN_BACK      = (1 shl 4);
    IN_USE       = (1 shl 5);
    IN_CANCEL    = (1 shl 6);
    IN_LEFT      = (1 shl 7);
    IN_RIGHT     = (1 shl 8);
    IN_MOVELEFT  = (1 shl 9);
    IN_MOVERIGHT = (1 shl 10);
    IN_ATTACK2   = (1 shl 11);
    IN_RUN       = (1 shl 12);
    IN_RELOAD    = (1 shl 13);
    IN_ALT1      = (1 shl 14);
    IN_SCORE     = (1 shl 15);

type
  { Screen Resolution and Font Information }
  TScreenInfo = packed record
    iSize: Integer;
    iWidth: Integer;
    iHeight: Integer;
    iFlags: Integer;
    iCharHeight: Integer;
    charWidths: array[0..255] of SmallInt;
  end;
  PScreenInfo = ^TScreenInfo;

  { Engine Function Pointers (cl_enginefuncs_s) }
  TfnGetLocalPlayer = function: Pointer; cdecl;
  TfnGetScreenInfo  = function(pscrinfo: PScreenInfo): Integer; cdecl;
  TfnCmd_AddCommand = procedure(cmd_name: PChar; function_ptr: Pointer); cdecl;
  TfnClientCmd      = procedure(szCmdString: PChar); cdecl;

implementation

end.
