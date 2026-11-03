# Forensic Symbol Mapping Script for IDA Pro / Ghidra / x64dbg
# Target Binary: payload_memory_dump.bin
# Image Base Address: 0x04C50000

SYMBOLS = {
    # -------------------------------------------------------------------------
    # Math & Geometry Subroutines
    # -------------------------------------------------------------------------
    0x04C63728: "VectorLength_3D",
    0x04C63764: "VectorSubtract_3D",
    0x04C638E0: "VectorScale_3D",
    0x04C70890: "ComputeAngleDifference",
    0x04C7090C: "ApplyAngles_AimbotChokePoint",

    # -------------------------------------------------------------------------
    # Engine & Client Hooks
    # -------------------------------------------------------------------------
    0x04C6F27D: "Hooked_SimpleWall_DepthRange",
    0x04C6F3EC: "Hooked_ModelShader_Niggers",
    0x04C6FB50: "Hooked_EntityESP_GroundItems",
    0x04C6FE0B: "Hooked_Radar_Draw",
    0x04C70084: "Hooked_AimThruWall_Autowall",
    0x04C700A7: "Hooked_DrawAimFov_Circle",
    0x04C71133: "Hooked_HUD_Key_Event",
    0x04C71190: "Hooked_PlaySoundByName_StepESP",
    0x04C712CC: "Hooked_ChaseCam_ThirdPerson",
    0x04C717B0: "Hooked_BarrelHack_LaserBeam",
    0x04C719C3: "Hooked_CustomCrosshair_Draw",
    0x04C72108: "Hooked_DrawStepESP_Visuals",
    0x04C72313: "Hooked_LocalGlow_Apply",
    0x04C7236C: "Hooked_PlayerGlow_Apply",
    0x04C724D0: "Hooked_PlayerESP_DrawAll",
    0x04C73C20: "Hooked_DrawAimSpot_Dot",
    0x04C7457B: "Hooked_QuakeGuns_CenterViewmodel",
    0x04C74754: "Hooked_Speedhack_MsecModifier",
    0x04C74CE0: "Hooked_FindBestTarget_FOVCheck",
    0x04C74DA0: "Hooked_HUD_Redraw",
    0x04C75100: "Hooked_LessFlash_SuppressFade",
    0x04C75131: "Hooked_FastRun_StrafeToggle",
    0x04C752BF: "Hooked_Bhop_ProcessJump",
    0x04C752E6: "Hooked_CL_CreateMove_SilentAim",
    0x04C75490: "Hooked_glBegin_VisualsOpenGL",
    0x04C7565B: "Hooked_LessSmoke_FilterSprite",
    0x04C76120: "LoadSettingsFromIni",
    0x04C764BA: "Handle_AutoScreenShot",
    0x04C7689A: "Install_EngineHooks",
    0x04C76FA9: "Original_Delphi_DllMain_OEP",
    0x04C77091: "Clean_Delphi_DllMain_Exit",

    # -------------------------------------------------------------------------
    # Floating Point Constants in .rdata / Code
    # -------------------------------------------------------------------------
    0x04C70998: "k_flAimbot_HalfDecay_0_5",
    0x04C7099C: "k_flAimbot_BaseDecay_10_0",
    0x04C709A0: "k_flAimbot_MinClamp_0_0",

    # -------------------------------------------------------------------------
    # Global Configuration Variables (RVA 0x2E5D0..0x2E670)
    # -------------------------------------------------------------------------
    0x04C7E5C8: "g_pEngineFuncs",
    0x04C7E5D0: "g_bSimpleWall",
    0x04C7E5D4: "g_bAsusWallhack",
    0x04C7E5D8: "g_bLambert",
    0x04C7E5DC: "g_bWhiteWalls",
    0x04C7E5E0: "g_bFullbright",
    0x04C7E5E4: "g_bLessSmoke",
    0x04C7E5E8: "g_bLessFlash",
    0x04C7E5EC: "g_bStepESP",
    0x04C7E5F0: "g_bNiggers_ModelShader",
    0x04C7E5F4: "g_bNightmode",
    0x04C7E5F8: "g_bCrosshair",
    0x04C7E5FC: "g_bAimbot",
    0x04C7E600: "g_iAimSpot",
    0x04C7E604: "g_bBoxESP",
    0x04C7E608: "g_bNameESP",
    0x04C7E60C: "g_bBhop",
    0x04C7E610: "g_bFastRun",
    0x04C7E614: "g_bQuakeGuns",
    0x04C7E618: "g_bLocalGlow",
    0x04C7E61C: "g_iAimMode_NoRecoil",
    0x04C7E620: "g_bChaseCam",
    0x04C7E624: "g_bRadar",
    0x04C7E628: "g_iAimTeam",
    0x04C7E62C: "g_flDistanceESP",
    0x04C7E630: "g_bWeaponESP",
    0x04C7E634: "g_bSpeedhack",
    0x04C7E638: "g_bAimThruWall",
    0x04C7E63C: "g_bPlayerGlow",
    0x04C7E640: "g_bPlayerLight",
    0x04C7E644: "g_bDrawAimFov",
    0x04C7E648: "g_iAimFov",
    0x04C7E64C: "g_iAimKey",
    0x04C7E654: "g_bSilentAim",
    0x04C7E658: "g_bEntityESP",
    0x04C7E65C: "g_bDrawAimSpot",
    0x04C7E660: "g_bBarrelHack",
    0x04C7E664: "g_bGlowNades",
    0x04C7E668: "g_bGlowEnts",
    0x04C7E66C: "g_flAimSpeed",
    0x04C7E670: "g_szAutoScreenShot",
    0x04C7E6B0: "g_vTargetDelta",
    0x04C7E724: "g_pfnGetAsyncKeyState"
}

def generate_ida_idc(out_path):
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write("#include <idc.idc>\n\nstatic main() {\n")
        for addr, name in SYMBOLS.items():
            f.write(f'  set_name(0x{addr:08X}, "{name}");\n')
        f.write('  Message("Symbols applied successfully!\\n");\n}\n')
    print(f"Generated IDA script: {out_path}")

def generate_ghidra_py(out_path):
    with open(out_path, 'w', encoding='utf-8') as f:
        f.write("# Ghidra Symbol Importer\n")
        f.write("from ghidra.program.model.symbol.SourceType import USER_DEFINED\n\n")
        for addr, name in SYMBOLS.items():
            f.write(f'createLabel(toAddr(0x{addr:08X}), "{name}", True, USER_DEFINED)\n')
    print(f"Generated Ghidra script: {out_path}")

if __name__ == "__main__":
    generate_ida_idc("apply_symbols_ida.idc")
    generate_ghidra_py("apply_symbols_ghidra.py")
