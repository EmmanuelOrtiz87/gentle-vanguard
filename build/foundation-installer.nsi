; Foundation Protected Installer v2.8
; Contains encrypted scripts + v2.0 launcher with AES-256 decryption

!define PRODUCT_NAME "Foundation"
!define PRODUCT_VERSION "2.8.0"
!define PRODUCT_PUBLISHER "Gentleman Foundation"

SetCompressor lzma
RequestExecutionLevel admin

Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "C:\Workspace_local\workspace-foundation\dist\Foundation-Setup.exe"
InstallDir "$PROGRAMFILES64\Foundation"

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
  
  SetOutPath "$INSTDIR\protected\scripts\utilities\WORKFLOW-ORCHESTRATION"
  File "C:\Workspace_local\workspace-foundation\build\protected\scripts\utilities\WORKFLOW-ORCHESTRATION\wf.ps1.enc"
  File "C:\Workspace_local\workspace-foundation\build\protected\scripts\utilities\foundation-installer-tui.ps1.enc"
  
  SetOutPath "$INSTDIR\protected\config"
  File "C:\Workspace_local\workspace-foundation\build\protected\config\orchestrator.json.enc"
  File "C:\Workspace_local\workspace-foundation\build\protected\config\auto-delegation.json.enc"
  
  SetOutPath "$INSTDIR\public"
  File /r "C:\Workspace_local\workspace-foundation\build\public\*.*"
  
  ; Install launcher v2.2 (compiled EXE - silent, no interactive prompts)
  SetOutPath "$INSTDIR"
  File "C:\Workspace_local\workspace-foundation\build\compiled\Foundation-Launcher.exe"
  
  ; Create keys directory
  CreateDirectory "$INSTDIR\keys"
  
  ; Create instructions file
  FileOpen $0 "$INSTDIR\keys\HOW_TO_GET_KEY.txt" w
  FileWrite $0 "FOUNDATION MASTER KEY REQUIRED$\r$\n$\r$\n"
  FileWrite $0 "This installation requires a master.key file to decrypt and run Foundation scripts.$\r$\n$\r$\n"
  FileWrite $0 "To obtain the key:$\r$\n"
  FileWrite $0 "1. Clone the private repository: gentleman-foundation$\r$\n"
  FileWrite $0 "2. Copy keys/master.key to this directory: $INSTDIR\keys\master.key$\r$\n$\r$\n"
  FileWrite $0 "OR$\r$\n$\r$\n"
  FileWrite $0 "Run the launcher - it will prompt you to paste the key.$\r$\n"
  FileClose $0
  
  ; Create shortcuts
  CreateDirectory "$SMPROGRAMS\Foundation"
  CreateShortcut "$SMPROGRAMS\Foundation\Foundation.lnk" "$INSTDIR\Foundation-Launcher.exe" ""
  CreateShortcut "$DESKTOP\Foundation.lnk" "$INSTDIR\Foundation-Launcher.exe" ""
  
  WriteUninstaller "$INSTDIR\uninstall.exe"

SectionEnd

Section "Uninstall"
  Delete "$INSTDIR\protected\*.*"
  RMDir /r "$INSTDIR\protected"
  Delete "$INSTDIR\public\*.*"
  RMDir /r "$INSTDIR\public"
  Delete "$INSTDIR\keys\*.*"
  RMDir /r "$INSTDIR\keys"
  Delete "$INSTDIR\Foundation-Launcher.exe"
  Delete "$INSTDIR\uninstall.exe"
  RMDir "$INSTDIR"
  
  Delete "$SMPROGRAMS\Foundation\*.*"
  RMDir "$SMPROGRAMS\Foundation"
  Delete "$DESKTOP\Foundation.lnk"
SectionEnd
