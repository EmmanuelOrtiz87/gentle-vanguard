; Gentle-Vanguard Protected Installer v2.8
; Contains 402+ encrypted scripts + v2.0 launcher with AES-256 decryption

!define PRODUCT_NAME "Gentle-Vanguard"
!define PRODUCT_VERSION "2.8.0"
!define PRODUCT_PUBLISHER "Gentle-Vanguard"

SetCompressor lzma
RequestExecutionLevel admin

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "C:\Workspace_local\gentle-vanguard\dist\Gentle-Vanguard-Setup.exe"
InstallDir "$PROGRAMFILES64\Gentle-Vanguard"

!include "MUI2.nsh"

!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

!insertmacro MUI_LANGUAGE "English"

Section "Core (Protected)" SecCore
  SectionIn RO

  ; All encrypted scripts and configs
  SetOutPath "$INSTDIR\protected"
  File /r "C:\Workspace_local\gentle-vanguard\build\protected\*.*"

  ; Public skill stubs
  SetOutPath "$INSTDIR\public"
  File /r "C:\Workspace_local\gentle-vanguard\build\public\*.*"

  ; Compiled launcher
  SetOutPath "$INSTDIR"
  File "C:\Workspace_local\gentle-vanguard\build\compiled\Gentle-Vanguard-Launcher.exe"

  ; Keys directory + instructions
  CreateDirectory "$INSTDIR\keys"
  FileOpen $0 "$INSTDIR\keys\HOW_TO_GET_KEY.txt" w
  FileWrite $0 "GENTLE_VANGUARD MASTER KEY REQUIRED$\r$\n$\r$\n"
  FileWrite $0 "This installation requires a master.key file to decrypt and run Gentle-Vanguard scripts.$\r$\n$\r$\n"
  FileWrite $0 "To obtain the key:$\r$\n"
  FileWrite $0 "1. Clone the private repository: gentle-vanguard$\r$\n"
  FileWrite $0 "2. Copy keys/master.key to this directory: $INSTDIR\keys\master.key$\r$\n$\r$\n"
  FileWrite $0 "OR$\r$\n$\r$\n"
  FileWrite $0 "Run the launcher - it will prompt you to paste the key.$\r$\n"
  FileClose $0

  ; Shortcuts
  CreateDirectory "$SMPROGRAMS\Gentle-Vanguard"
  CreateShortcut "$SMPROGRAMS\Gentle-Vanguard\Gentle-Vanguard.lnk" "$INSTDIR\Gentle-Vanguard-Launcher.exe" ""
  CreateShortcut "$DESKTOP\Gentle-Vanguard.lnk" "$INSTDIR\Gentle-Vanguard-Launcher.exe" ""

  WriteUninstaller "$INSTDIR\uninstall.exe"
SectionEnd

Section "Uninstall"
  RMDir /r "$INSTDIR\protected"
  RMDir /r "$INSTDIR\public"
  RMDir /r "$INSTDIR\keys"
  Delete "$INSTDIR\Gentle-Vanguard-Launcher.exe"
  Delete "$INSTDIR\uninstall.exe"
  RMDir "$INSTDIR"

  Delete "$SMPROGRAMS\Gentle-Vanguard\*.*"
  RMDir "$SMPROGRAMS\Gentle-Vanguard"
  Delete "$DESKTOP\Gentle-Vanguard.lnk"
SectionEnd

