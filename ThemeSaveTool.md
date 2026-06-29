# ThemeSaveTool Development & Scope

## Overview
The **ThemeSaveTool** is a customized Windows tool designed to provide a graphical interface for saving and exporting the active Windows theme. This tool is built specifically for users who have heavily modified their Windows installations (such as creating 1:1 legacy Windows Vista setups) and have unintentionally broken the native Personalization control panel's ability to save or export themes.

## Scope & Requirements
1. **PowerShell-based**: Written in PowerShell (`.ps1`) to interact easily with the Windows registry and file system without needing a heavy framework.
2. **WinForms GUI**: Must include a graphical user interface utilizing native Windows visual styles.
3. **Legacy UI Aesthetic**: The interface is modeled after a provided `Template.ps1` script to keep an authentic "Vista Aero" aesthetic. It features:
   - A top banner panel with a frosted white-to-teal vertical gradient.
   - Segoe UI (or Montserrat) typography.
   - Clean, legacy-styled buttons and form layouts.
4. **Compiled Executable Support**: The script contains logic to extract and display its icon natively from its compiled `.exe` container. When run as an `.exe`, it uses the executable's own icon for the titlebar, taskbar entry, and the UI's top banner graphic.
5. **Theme Extraction Logic**: Automatically fetches the current theme from the Windows registry, parses the raw `.theme` file to inject a custom display name provided by the user, and exports it to a chosen destination.

## Development Details

### 1. Graphical Interface (WinForms)
The GUI is constructed using `System.Windows.Forms`. 
Native visual styles are strictly enabled using:
```powershell
[System.Windows.Forms.Application]::EnableVisualStyles()
```
The UI components include:
- A gradient paint event for the top banner.
- A `TextBox` for specifying the new theme's display name.
- A `SaveFileDialog` initialized through a "Browse..." button to select the `.theme` export location.
- Standard "Export" and "Exit" buttons located in a bottom "Chin" panel.

### 2. Icon Handling
To fulfill the requirement of pulling the icon from the compiled executable, the script checks its environment on initialization:
```powershell
if ($IsCompiled) {
    $AppIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($CurrentPath)
    $Form.Icon = $AppIcon
} elseif (Test-Path $IconPath) {
    $AppIcon = New-Object System.Drawing.Icon($IconPath, 48, 48)
    $Form.Icon = $AppIcon
}
```
If compiled, it extracts the native icon from itself using `[System.Drawing.Icon]::ExtractAssociatedIcon`. If run as a `.ps1` script, it looks for an adjacent `.ico` file.

### 3. Theme Extraction and Parsing
The script interacts directly with the Windows Registry and the `.theme` file structure (which operates essentially as an INI file).
1. **Registry Lookup**: The current theme's absolute path is read from:
   `HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\CurrentTheme`
2. **Parsing**: The script iterates through the theme file line by line. It identifies the `[Theme]` block and locates the `DisplayName=` property.
3. **Injection**: It rewrites the `DisplayName` property to match the custom name provided in the GUI.
4. **Export**: The modified content is dumped directly to the `.theme` file location chosen by the user in UTF-8 encoding.

## Compilation Instructions
To compile this script into an executable (`.exe`) with the correct icon and hidden console:
1. Use the **PS2EXE** module in PowerShell:
   ```powershell
   Install-Module -Name ps2exe -Scope CurrentUser
   ```
2. Compile the script, specifying an icon and the `-NoConsole` flag so the terminal doesn't appear behind the GUI:
   ```powershell
   Invoke-ps2exe -inputFile "ThemeSaveTool.ps1" -outputFile "ThemeSaveTool.exe" -iconFile "Template.ico" -noConsole
   ```
Once compiled, `ThemeSaveTool.exe` will run silently and display the UI, seamlessly pulling its embedded icon for the taskbar and titlebar.
