<#
.SYNOPSIS
    Vista Theme Save & Export Tool
.DESCRIPTION
    A comprehensive legacy-styled WinForms frontend for saving and exporting 
    the current Windows theme. Useful for customized systems where the native 
    save theme functionality is broken.
.VERSION
    1.0.0
#>

# ==============================================================================
# Initialization & Environment
# ==============================================================================
$ErrorActionPreference = "Stop"

$ToolName = "ThemeSaveTool"
$CurrentPath = $MyInvocation.MyCommand.Path
$IsCompiled = $false
if (-not $CurrentPath) {
    $CurrentPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    $IsCompiled = $true
}
$ScriptDir = [System.IO.Path]::GetDirectoryName($CurrentPath)

# ==============================================================================
# Assemblies & Visual Styles
# ==============================================================================
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

[System.Windows.Forms.Application]::EnableVisualStyles()

$ScriptBaseName = [System.IO.Path]::GetFileNameWithoutExtension($CurrentPath)
$IconPath = Join-Path $ScriptDir "$ScriptBaseName.ico"

# ==============================================================================
# Font Handling
# ==============================================================================
$BaseFontName = "Segoe UI"
$InstalledFonts = New-Object System.Drawing.Text.InstalledFontCollection
if ($InstalledFonts.Families | Where-Object { $_.Name -eq "Montserrat" }) {
    $BaseFontName = "Montserrat"
}
$StandardFont = New-Object System.Drawing.Font($BaseFontName, 9, [System.Drawing.FontStyle]::Regular)
$SemiboldFont = New-Object System.Drawing.Font($BaseFontName, 9, [System.Drawing.FontStyle]::Bold)
$TitleFont = New-Object System.Drawing.Font($BaseFontName, 12, [System.Drawing.FontStyle]::Bold)

# ==============================================================================
# Form Construction
# ==============================================================================
$Form = New-Object System.Windows.Forms.Form
$Form.Text = "Vista Theme Export Tool"
$Form.Size = New-Object System.Drawing.Size(520, 350)
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$Form.MaximizeBox = $false
$Form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$Form.Font = $StandardFont
$Form.BackColor = [System.Drawing.SystemColors]::Control 

# Icon Extraction Logic (Prioritizes compiled EXE icon)
$AppIcon = $null
if ($IsCompiled) {
    try {
        $AppIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($CurrentPath)
        $Form.Icon = $AppIcon
    } catch { }
} elseif (Test-Path $IconPath) {
    try {
        $AppIcon = New-Object System.Drawing.Icon($IconPath, 48, 48)
        $Form.Icon = $AppIcon
    } catch { }
}

$ToolTip = New-Object System.Windows.Forms.ToolTip

# --- Top Banner Panel (Vista Teal Gradient) ---
$BannerPanel = New-Object System.Windows.Forms.Panel
$BannerPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$BannerPanel.Height = 65

$BannerPanel.add_Paint({
    param($sender, $e)
    $rect = $sender.ClientRectangle
    # Top color: Pure Aero Frost White, Bottom color: Classic Vista Teal
    $topColor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
    $bottomColor = [System.Drawing.Color]::FromArgb(255, 175, 215, 225) 
    
    $brush = New-Object System.Drawing.Drawing2D.LinearGradientBrush($rect, $topColor, $bottomColor, [System.Drawing.Drawing2D.LinearGradientMode]::Vertical)
    $e.Graphics.FillRectangle($brush, $rect)
    $brush.Dispose()
})

$TitleLabel = New-Object System.Windows.Forms.Label
$TitleLabel.Text = "Theme Export & Save Utility"
$TitleLabel.Font = $TitleFont
$TitleLabel.Location = New-Object System.Drawing.Point(15, 10)
$TitleLabel.AutoSize = $true
$TitleLabel.BackColor = [System.Drawing.Color]::Transparent
$ToolTip.SetToolTip($TitleLabel, "Save your customized theme configuration.")
$BannerPanel.Controls.Add($TitleLabel)

$SubTitleLabel = New-Object System.Windows.Forms.Label
$SubTitleLabel.Text = "Backup and export your custom Vista visual style configuration."
$SubTitleLabel.Location = New-Object System.Drawing.Point(18, 35)
$SubTitleLabel.AutoSize = $true
$SubTitleLabel.BackColor = [System.Drawing.Color]::Transparent
$BannerPanel.Controls.Add($SubTitleLabel)

if ($AppIcon) {
    $BannerIcon = New-Object System.Windows.Forms.PictureBox
    $BannerIcon.Size = New-Object System.Drawing.Size(48, 48)
    $BannerIcon.Location = New-Object System.Drawing.Point(440, 8)
    $BannerIcon.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::CenterImage
    $BannerIcon.Image = $AppIcon.ToBitmap()
    $BannerIcon.BackColor = [System.Drawing.Color]::Transparent
    $BannerPanel.Controls.Add($BannerIcon)
}

$BannerDivider = New-Object System.Windows.Forms.Label
$BannerDivider.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
$BannerDivider.Height = 2
$BannerDivider.Dock = [System.Windows.Forms.DockStyle]::Bottom
$BannerPanel.Controls.Add($BannerDivider)

# --- Bottom Chin Panel ---
$ChinPanel = New-Object System.Windows.Forms.Panel
$ChinPanel.BackColor = [System.Drawing.SystemColors]::Control
$ChinPanel.Dock = [System.Windows.Forms.DockStyle]::Bottom
$ChinPanel.Height = 55

$ExportButton = New-Object System.Windows.Forms.Button
$ExportButton.Text = "Export"
$ExportButton.Size = New-Object System.Drawing.Size(90, 28)
$ExportButton.Location = New-Object System.Drawing.Point(300, 13)
$ExportButton.Font = $SemiboldFont
$ExportButton.UseVisualStyleBackColor = $true
$ToolTip.SetToolTip($ExportButton, "Commit your current configuration to a .theme file.")
$ChinPanel.Controls.Add($ExportButton)

$ExitButton = New-Object System.Windows.Forms.Button
$ExitButton.Text = "Exit"
$ExitButton.Size = New-Object System.Drawing.Size(90, 28)
$ExitButton.Location = New-Object System.Drawing.Point(400, 13)
$ExitButton.Font = $SemiboldFont
$ExitButton.UseVisualStyleBackColor = $true
$ChinPanel.Controls.Add($ExitButton)

# --- 3D Inset Client Edge Panel ---
$ClientPanel = New-Object System.Windows.Forms.Panel
$ClientPanel.BackColor = [System.Drawing.SystemColors]::Window
$ClientPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
$ClientPanel.Location = New-Object System.Drawing.Point(10, 75)
$ClientPanel.Size = New-Object System.Drawing.Size(485, 170)

# Theme Name Field
$NameLabel = New-Object System.Windows.Forms.Label
$NameLabel.Text = "Theme Display Name:"
$NameLabel.Location = New-Object System.Drawing.Point(15, 20)
$NameLabel.AutoSize = $true
$ClientPanel.Controls.Add($NameLabel)

$NameTextBox = New-Object System.Windows.Forms.TextBox
$NameTextBox.Location = New-Object System.Drawing.Point(18, 43)
$NameTextBox.Size = New-Object System.Drawing.Size(447, 25)
$NameTextBox.Text = "My Custom Vista Theme"
$ToolTip.SetToolTip($NameTextBox, "The name that will appear in the Personalization menu.")
$ClientPanel.Controls.Add($NameTextBox)

# Export Path Field
$PathLabel = New-Object System.Windows.Forms.Label
$PathLabel.Text = "Export Location (.theme):"
$PathLabel.Location = New-Object System.Drawing.Point(15, 80)
$PathLabel.AutoSize = $true
$ClientPanel.Controls.Add($PathLabel)

$PathTextBox = New-Object System.Windows.Forms.TextBox
$PathTextBox.Location = New-Object System.Drawing.Point(18, 103)
$PathTextBox.Size = New-Object System.Drawing.Size(365, 25)
$ToolTip.SetToolTip($PathTextBox, "The destination path where your .theme file will be saved.")
$ClientPanel.Controls.Add($PathTextBox)

$BrowseButton = New-Object System.Windows.Forms.Button
$BrowseButton.Text = "Browse..."
$BrowseButton.Location = New-Object System.Drawing.Point(390, 102)
$BrowseButton.Size = New-Object System.Drawing.Size(75, 26)
$BrowseButton.UseVisualStyleBackColor = $true
$ClientPanel.Controls.Add($BrowseButton)

$Form.Controls.Add($ClientPanel)
$Form.Controls.Add($ChinPanel)
$Form.Controls.Add($BannerPanel)

# ==============================================================================
# Events & Logic
# ==============================================================================

$BrowseButton.add_Click({
    $SaveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $SaveDialog.Filter = "Windows Theme Files (*.theme)|*.theme|All Files (*.*)|*.*"
    $SaveDialog.Title = "Save Theme As"
    $FileName = $NameTextBox.Text -replace '[\\/:*?"<>|]', '_'
    if ([string]::IsNullOrWhiteSpace($FileName)) {
        $FileName = "ExportedTheme"
    }
    $SaveDialog.FileName = "$FileName.theme"
    if ($SaveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $PathTextBox.Text = $SaveDialog.FileName
    }
})

$ExitButton.add_Click({
    $Form.Close()
})

$ExportButton.add_Click({
    $ThemeName = $NameTextBox.Text.Trim()
    $ExportPath = $PathTextBox.Text.Trim()
    
    if ([string]::IsNullOrWhiteSpace($ThemeName)) {
        [System.Windows.Forms.MessageBox]::Show("Please enter a theme display name.", "Input Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    if ([string]::IsNullOrWhiteSpace($ExportPath)) {
        [System.Windows.Forms.MessageBox]::Show("Please select an export location.", "Input Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    
    try {
        # 1. Get the currently active theme path from the registry
        $RegPath = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes"
        $CurrentTheme = (Get-ItemProperty -Path $RegPath -Name "CurrentTheme" -ErrorAction Stop).CurrentTheme
        
        if (-not (Test-Path $CurrentTheme)) {
            [System.Windows.Forms.MessageBox]::Show("Could not locate the currently active theme file:`n$CurrentTheme", "Theme Not Found", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            return
        }

        # 2. Read the active theme file
        $ThemeContent = Get-Content $CurrentTheme
        $NewThemeContent = @()
        $InThemeSection = $false
        $DisplayNameFound = $false
        
        # 3. Modify the DisplayName in the [Theme] section
        foreach ($Line in $ThemeContent) {
            if ($Line -match "^\[Theme\]") {
                $InThemeSection = $true
                $NewThemeContent += $Line
                continue
            }
            if ($Line -match "^\[.*\]") {
                if ($InThemeSection -and -not $DisplayNameFound) {
                    $NewThemeContent += "DisplayName=$ThemeName"
                }
                $InThemeSection = $false
            }
            
            if ($InThemeSection -and $Line -match "^DisplayName=") {
                $NewThemeContent += "DisplayName=$ThemeName"
                $DisplayNameFound = $true
            } else {
                $NewThemeContent += $Line
            }
        }
        
        if ($InThemeSection -and -not $DisplayNameFound) {
            $NewThemeContent += "DisplayName=$ThemeName"
        }

        # 4. Save to the new location
        $NewThemeContent | Set-Content -Path $ExportPath -Encoding UTF8
        
        [System.Windows.Forms.MessageBox]::Show("Your theme was successfully exported to:`n`n$ExportPath", "Export Successful", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } catch {
        [System.Windows.Forms.MessageBox]::Show("An error occurred while exporting your theme:`n`n$($_.Exception.Message)", "Export Failed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
    }
})

[void]$Form.ShowDialog()
