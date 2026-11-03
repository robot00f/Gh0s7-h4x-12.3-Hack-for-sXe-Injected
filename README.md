# Gh0s7H4x Reconstructed (xZone-Reactor CS 1.6 Leak)

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Target: Counter-Strike 1.6](https://img.shields.io/badge/Target-GoldSrc%201.6-orange.svg)]()
[![Language: C++17](https://img.shields.io/badge/Language-C%2B%2B17-blue.svg)]()
[![Language: Delphi](https://img.shields.io/badge/Language-Borland%20Delphi%207-red.svg)]()
[![Architecture: x86](https://img.shields.io/badge/Arch-x86-lightgrey.svg)]()

> **Forensic reverse engineering, memory dump analysis, and complete clean-room source code reconstruction of the famous Gh0s7 H4x v12.3 from xZone-Reactor for Counter-Strike 1.6 (recovered from a leaked & cracked build).**

---

## 📖 Research Context

In the mid-2000s, **Gh0s7 H4x** (developed by the **xZone-Reactor** group for Counter-Strike 1.6 / GoldSrc) was one of the most prominent private utilities in the competitive scene. The binary was originally protected with a multi-stage crypter/packer (Reactor / X-Protector) containing anti-debugging traps, VM instruction virtualization, and MSVC licensing checks wrapped around a pure **Borland Delphi 6/7** core payload.

This repository provides:
1. **Raw Memory Dumps & Unpacked Binaries**: The original decrypted process memory dump (`payload_memory_dump.bin`) and standalone cleaned PE binary (`lolwut_clean.dll`).
2. **Complete Disassembly & Decompilation**: Over 55,500 annotated instructions in `disassembly_delphi_code.asm`.
3. **Modular Reconstructed Source Code**: 100% human-readable, decoupled, compile-ready implementations in both **C++17** and **Borland Delphi/Pascal**, free of protector code or external DRM hooks.

---

## 📂 Repository Structure

```text
gh0s7h4x-reconstructed/
├── CMakeLists.txt              # Modern CMake build script (MSVC / MinGW)
├── LICENSE                     # MIT License
├── README.md                   # Project documentation and build guide
├── .gitignore                  # Git ignore rules for Delphi, MSVC, and Python
│
├── artifacts/                  # Forensic binaries, dumps & disassembly
│   ├── lolwut32.dll            # Original packed binary from leak (1.27 MB)
│   ├── lolwut_clean.dll        # Modern Windows (Win10/11) patched & unpacked PE binary (1.57 MB)
│   ├── payload_memory_dump.bin # Raw process memory dump (Base 0x04C50000, 1.44 MB)
│   ├── iat_resolved.txt        # Resolved IAT imports table
│   ├── relocs_v5.bin           # Serialized base relocation table
│   ├── disassembly_delphi_code.asm # Full x86 disassembly (55,534 instructions)
│   ├── decompiled_source.cpp   # Base decompiled C++ core unit
│   └── decompiled_source.pas   # Base decompiled Delphi Pascal core unit
│
├── config/
│   └── gh0s7h4x12.ini          # Reference configuration file (40 parameters)
│
├── docs/
│   └── OFFSETS.md              # Full memory map, RVAs, and struct offsets
│
├── tools/
│   ├── build_perfect_clean.py  # Unpacker & standalone clean PE reconstructor
│   ├── symbols_map.py          # Master symbol mapping generator
│   ├── apply_symbols_ida.idc   # Automated IDA Pro symbol script
│   └── apply_symbols_ghidra.py # Automated Ghidra symbol script
│
└── src/
    ├── cpp/                    # Native C++ modular implementation
    │   ├── SDK.hpp             # Shared GoldSrc & Half-Life structures
    │   ├── Aimbot.cpp          # Angle decay smoothing choke point
    │   ├── AimbotTarget.cpp    # 2D Screen-space FOV and bone targeting
    │   ├── BarrelHack.cpp      # 3D forward projection laser beam
    │   ├── ESP.cpp             # Box, Name, Weapon, and Distance ESP
    │   ├── GlowLight.cpp       # Local glow, player glow, and dynamic lights
    │   ├── Movement.cpp        # Auto-bhop, fast run strafe, speedhack
    │   ├── RadarCrosshair.cpp  # 2D Radar HUD, custom dot/cross crosshairs
    │   ├── RemovalsView.cpp    # LessSmoke, LessFlash, ChaseCam, QuakeGuns
    │   ├── StepESP.cpp         # Circular step sound buffer and visuals
    │   ├── VisualsOpenGL.cpp   # AsusWallhack, Lambert, WhiteWalls, NightMode
    │   └── WallhackExtra.cpp   # SimpleWall, Unlit shader, EntityESP, Autowall
    │
    └── delphi/                 # Pure Borland Delphi 6/7 Pascal implementation
        ├── Gh0s7H4x.dpr        # Master Delphi DLL project & worker thread
        ├── Types.pas           # Vectors, usercmd_s, and entity definitions
        ├── Config.pas          # Complete 40-key INI parser and serializer
        ├── Math3D.pas          # FPU x87 vector math library & normalization
        ├── Hooks.pas           # CL_CreateMove, HUD_Redraw, HUD_Key_Event
        ├── Aimbot.pas
        ├── AimbotTarget.pas
        ├── BarrelHack.pas
        ├── ESP.pas
        ├── GlowLight.pas
        ├── Movement.pas
        ├── RadarCrosshair.pas
        ├── RemovalsView.pas
        ├── StepESP.pas
        ├── VisualsOpenGL.pas
        └── WallhackExtra.pas
```

---

## 🎯 Modular Architecture & Forensic Offsets

| Feature / Setting | Module | Original RVA / Offset | Description |
| :--- | :--- | :--- | :--- |
| `aimbot`, `norecoil`, `silentaim` | `Aimbot` | RVA `0x2090C` (`0x04C7090C`) | Exponential decay angle smoothing choke point |
| `aimspot`, `aimfov`, `aimteam` | `AimbotTarget` | RVA `0x24CE0` (`0x04C74CE0`) | 2D screen FOV bounding box & bone targeting |
| `stepesp` | `StepESP` | RVA `0x21190` & `0x22108` | Sound hook on `pfnPlaySoundByName`, circular step buffer |
| `boxesp`, `nameesp`, `weaponesp`| `ESP` | RVA `0x224D0` (`0x04C724D0`) | 32-player client loop, WorldToScreen projection |
| `asuswallhack`, `lambert`, `whitewalls` | `VisualsOpenGL` | RVA `0x25490` (`0x04C75490`) | Intercepts `glBegin`, depth buffer manipulation |
| `barrelhack` | `BarrelHack` | RVA `0x217B0` (`0x04C717B0`) | Forward viewangle projection via `R_BeamPoints` |
| `localglow`, `playerglow`, `playerlight` | `GlowLight` | RVA `0x22313` / `0x2236C` | `kRenderFxGlowShell` (19) and `CL_AllocDlight` |
| `radar`, `crosshair`, `drawaimfov` | `RadarCrosshair` | RVA `0x1FE0B`, `0x219C3` | 2D HUD Radar with local player yaw transformation |
| `lesssmoke`, `lessflash`, `quakeguns` | `RemovalsView` | RVA `0x2565B`, `0x25100` | Smoke sprite quad filter, flash screenfade suppressor |
| `simplewall`, `niggers`, `entityesp` | `WallhackExtra` | RVA `0x1F27D`, `0x1FB50` | Depth range override, unlit silhouette model shader |
| `bhop`, `fastrun`, `speedhack` | `Movement` | RVA `0x252BF`, `0x25131` | Auto-jump on `FL_ONGROUND`, sidemove oscillation |
| `CL_CreateMove`, `HUD_Redraw` | `Hooks` | RVA `0x2530D`, `0x24DA0` | Command modification & frame render dispatchers |

For the complete technical breakdown of all 40 variables and struct alignments, refer to [docs/OFFSETS.md](docs/OFFSETS.md).

---

## 🛡️ Modern Windows (Win10 / Win11) Patches in `lolwut_clean.dll`

The pre-built standalone binary `artifacts/lolwut_clean.dll` has been specifically repaired and patched for modern Windows environments:

1. **Modern OpenGL Driver Compatibility**: Neutralized destructive Windows XP-era `glTexEnvf` hook skips at RVA `0x2655E..0x2658C`, preventing crashes on modern NVIDIA, AMD, and Intel WDDM graphics drivers.
2. **Safe GetProcAddress Hook Guard**: Added parameter validation guard at RVA `0x257C4` to prevent `0xC0000005` Access Violation crashes when modern Windows components or overlays pass ordinals or non-user memory pointers.
3. **Dynamic IAT & Relocations**: Replaced stripped protector tables with a standard 148-entry IAT and 9,000 base relocations, ensuring full compatibility with Windows ASLR.
4. **Protector VM Neutralization**: The original Delphi `DllMain` entry point at RVA `0x26FA9` is patched to jump directly to `0x27091`, bypassing the Reactor VM anti-tamper stub.
5. **Dynamic Path Isolation**: Replaced hardcoded paths with runtime resolution via `GetModuleFileNameA`, automatically reading `config/gh0s7h4x12.ini` relative to wherever the DLL is placed.

---

## 🛠️ Building the Project

### Option A: Borland Delphi (Native Original Engine)
1. Open Borland Delphi 6, Delphi 7, or Embarcadero RAD Studio.
2. Open `src/delphi/Gh0s7H4x.dpr`.
3. Select **Release** build target and compile (`Ctrl + F9`).
4. Output: `gh0s7h4x.dll`.

### Option B: C++ with CMake & MSVC
1. Open a terminal or Developer Command Prompt.
2. Run CMake:
   ```bash
   cmake -B build -A Win32
   cmake --build build --config Release
   ```
3. Output: `build/Release/gh0s7h4x.dll`.

---

## 🔍 Disassembly & Symbol Tools

To import all reconstructed symbols and subroutines into your reverse engineering platform of choice:

* **IDA Pro:**
  1. Load `artifacts/payload_memory_dump.bin` or `artifacts/lolwut_clean.dll` at base `0x04C50000`.
  2. In IDA, navigate to `File` -> `Script file...` -> select `tools/apply_symbols_ida.idc`.
* **Ghidra:**
  1. Open the project in the CodeBrowser.
  2. Open the `Script Manager` -> `Run Script` -> select `tools/apply_symbols_ghidra.py`.

---

## ⚠️ Disclaimer & Educational Notice

This repository contains clean-room reverse engineering and software reconstruction conducted strictly for **educational purposes, forensic analysis, game engine architecture research, and video game software preservation**. 

All original binary protection mechanisms, DRM wrappers, and third-party commercial components have been discarded in favor of pure, readable source code.
