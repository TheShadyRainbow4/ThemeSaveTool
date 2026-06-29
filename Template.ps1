<#
.SYNOPSIS
    PsExec64 Drop Target Launcher
.DESCRIPTION
    A comprehensive legacy-styled WinForms frontend for launching executables via PsExec64 as SYSTEM, featuring a Vista Aero gradient, scope selection, and high-fidelity icons.
.VERSION
    1.0.0.4
.AUTHOR
    EliteSoftwareTech Co - Zachary Whiteman - Susan Gemm
#>

# ==============================================================================
# Initialization & Logging
# ==============================================================================
$ErrorActionPreference = "Stop"

$ToolName = "PsExecDropTarget"
$LogDir = "$env:SystemDrive\EliteSoftware\Logs"
$LogFile = "$LogDir\$ToolName.log"

if (-not (Test-Path $LogDir)) {
    try {
        New-Item -ItemType Directory -Path $LogDir -Force | Out-Null
    } catch { }
}

function Write-Log {
    param(
        [string]$Message,
        [string]$ErrorCode = "0x00000000",
        [bool]$IsError = $false
    )
    $Timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $LogEntry = "[$Timestamp] [$ErrorCode] $Message"
    if ($IsError) {
        $LogEntry = "[$Timestamp] [ERROR: $ErrorCode] $Message"
    }
    try {
        Add-Content -Path $LogFile -Value $LogEntry
    } catch { }
}

Write-Log "Initializing $ToolName Boot Sequence (Vista Aero Paint Update)." "0x00000001"

$CurrentPath = $MyInvocation.MyCommand.Path
$IsCompiled = $false
if (-not $CurrentPath) {
    $CurrentPath = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName
    $IsCompiled = $true
}
$ScriptDir = [System.IO.Path]::GetDirectoryName($CurrentPath)

# ==============================================================================
# PsExec Locating
# ==============================================================================
$PsExecPath = Join-Path $ScriptDir "psexec64.exe"
if (-not (Test-Path $PsExecPath)) {
    $SysPath = (Get-Command "psexec64.exe" -ErrorAction SilentlyContinue).Source
    if ($SysPath) {
        $PsExecPath = $SysPath
    }
}

# ==============================================================================
# INSTANT DROP TARGET LOGIC (GUI Bypass)
# ==============================================================================
if ($args.Count -gt 0) {
    $DroppedFile = $args[0]
    if (Test-Path $DroppedFile) {
        Write-Log "EXE triggered as drop target. Bypassing UI and engaging instant SYSTEM launch for: $DroppedFile" "0x00000007"
        
        if (-not (Test-Path $PsExecPath)) {
            Write-Log "Instant launch failed: psexec64.exe not found." "0xE0000010" $true
            exit
        }

        $SilentArgs = "-s -i `"$DroppedFile`""
        try {
            Start-Process -FilePath $PsExecPath -ArgumentList $SilentArgs -Verb RunAs -ErrorAction Stop
            Write-Log "Instant SYSTEM payload deployed successfully. Terminating launcher." "0x00000008"
        } catch {
            Write-Log "Instant launch exception caught: $($_.Exception.Message)" "0xE0000011" $true
        }
        exit
    }
}

# ==============================================================================
# Assemblies & Environment
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
$Form.Text = "EliteSoftware PsExec Launcher"
$Form.Size = New-Object System.Drawing.Size(520, 520)
$Form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$Form.MaximizeBox = $false
$Form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
$Form.Font = $StandardFont
$Form.BackColor = [System.Drawing.SystemColors]::Control 

$AppIcon = $null
if (Test-Path $IconPath) {
    try {
        $AppIcon = New-Object System.Drawing.Icon($IconPath, 48, 48)
        $Form.Icon = $AppIcon
    } catch {
        Write-Log "Icon file exists but failed to extract 48x48 frame." "0xE0000012" $true
    }
} elseif ($IsCompiled) {
    $AppIcon = [System.Drawing.Icon]::ExtractAssociatedIcon($CurrentPath)
    $Form.Icon = $AppIcon
}

$ToolTip = New-Object System.Windows.Forms.ToolTip

# --- Top Banner Panel (Vista Teal Gradient) ---
$BannerPanel = New-Object System.Windows.Forms.Panel
$BannerPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$BannerPanel.Height = 65

# Paint event for the Vista Aero Gradient
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
$TitleLabel.Text = "System Context Launcher"
$TitleLabel.Font = $TitleFont
$TitleLabel.Location = New-Object System.Drawing.Point(15, 10)
$TitleLabel.AutoSize = $true
$TitleLabel.BackColor = [System.Drawing.Color]::Transparent
$ToolTip.SetToolTip($TitleLabel, "You are entering the NT AUTHORITY realm. Tread lightly.")
$BannerPanel.Controls.Add($TitleLabel)

$SubTitleLabel = New-Object System.Windows.Forms.Label
$SubTitleLabel.Text = "Select or drop a target executable to launch with elevated parameters."
$SubTitleLabel.Location = New-Object System.Drawing.Point(18, 35)
$SubTitleLabel.AutoSize = $true
$SubTitleLabel.BackColor = [System.Drawing.Color]::Transparent
$ToolTip.SetToolTip($SubTitleLabel, "Explorer drop targets are supported. Just drag it into the client area below.")
$BannerPanel.Controls.Add($SubTitleLabel)

if ($AppIcon) {
    $BannerIcon = New-Object System.Windows.Forms.PictureBox
    $BannerIcon.Size = New-Object System.Drawing.Size(48, 48)
    $BannerIcon.Location = New-Object System.Drawing.Point(440, 8)
    $BannerIcon.SizeMode = [System.Windows.Forms.PictureBoxSizeMode]::CenterImage
    $BannerIcon.Image = $AppIcon.ToBitmap()
    $BannerIcon.BackColor = [System.Drawing.Color]::Transparent
    $ToolTip.SetToolTip($BannerIcon, "Glorious 32-bit icon extracted flawlessly at 48x48.")
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

$ApplyButton = New-Object System.Windows.Forms.Button
$ApplyButton.Text = "Apply"
$ApplyButton.Size = New-Object System.Drawing.Size(90, 28)
$ApplyButton.Location = New-Object System.Drawing.Point(300, 13)
$ApplyButton.Font = $SemiboldFont
$ApplyButton.UseVisualStyleBackColor = $true
$ToolTip.SetToolTip($ApplyButton, "Applies your configuration and sparks the PsExec engine. Prepare for UAC.")
$ChinPanel.Controls.Add($ApplyButton)

$ExitButton = New-Object System.Windows.Forms.Button
$ExitButton.Text = "Exit"
$ExitButton.Size = New-Object System.Drawing.Size(90, 28)
$ExitButton.Location = New-Object System.Drawing.Point(400, 13)
$ExitButton.Font = $SemiboldFont
$ExitButton.UseVisualStyleBackColor = $true
$ToolTip.SetToolTip($ExitButton, "Abandon execution protocol and return to safety.")
$ChinPanel.Controls.Add($ExitButton)

$LogLink = New-Object System.Windows.Forms.LinkLabel
$LogLink.Text = "View $ToolName Logs"
$LogLink.AutoSize = $true
$LogLink.Location = New-Object System.Drawing.Point(15, 20)
$ToolTip.SetToolTip($LogLink, "Summon Notepad to view the diagnostic transcripts of your previous decisions.")
$ChinPanel.Controls.Add($LogLink)

# --- 3D Inset Client Edge Panel ---
$ClientPanel = New-Object System.Windows.Forms.Panel
$ClientPanel.BackColor = [System.Drawing.SystemColors]::Window
$ClientPanel.BorderStyle = [System.Windows.Forms.BorderStyle]::Fixed3D
$ClientPanel.Location = New-Object System.Drawing.Point(10, 75)
$ClientPanel.Size = New-Object System.Drawing.Size(485, 335)
$ClientPanel.AllowDrop = $true

# Target Setup
$TargetLabel = New-Object System.Windows.Forms.Label
$TargetLabel.Text = "Target File:"
$TargetLabel.Location = New-Object System.Drawing.Point(15, 15)
$TargetLabel.AutoSize = $true
$ClientPanel.Controls.Add($TargetLabel)

$TargetTextBox = New-Object System.Windows.Forms.TextBox
$TargetTextBox.Location = New-Object System.Drawing.Point(18, 38)
$TargetTextBox.Size = New-Object System.Drawing.Size(365, 25)
$ToolTip.SetToolTip($TargetTextBox, "The absolute path to the executable demanding complete system authority.")
$ClientPanel.Controls.Add($TargetTextBox)

$BrowseButton = New-Object System.Windows.Forms.Button
$BrowseButton.Text = "Browse..."
$BrowseButton.Location = New-Object System.Drawing.Point(390, 37)
$BrowseButton.Size = New-Object System.Drawing.Size(75, 26)
$BrowseButton.UseVisualStyleBackColor = $true
$ToolTip.SetToolTip($BrowseButton, "Invokes the legacy file dialog so you don't have to type the path like a caveman.")
$ClientPanel.Controls.Add($BrowseButton)

# Arguments
$ArgsLabel = New-Object System.Windows.Forms.Label
$ArgsLabel.Text = "Arguments (Optional):"
$ArgsLabel.Location = New-Object System.Drawing.Point(15, 75)
$ArgsLabel.AutoSize = $true
$ClientPanel.Controls.Add($ArgsLabel)

$ArgsTextBox = New-Object System.Windows.Forms.TextBox
$ArgsTextBox.Location = New-Object System.Drawing.Point(18, 98)
$ArgsTextBox.Size = New-Object System.Drawing.Size(447, 25)
$ToolTip.SetToolTip($ArgsTextBox, "Command-line flags and parameters to feed the target payload.")
$ClientPanel.Controls.Add($ArgsTextBox)

# Execution Scope Section
$ScopeGroupBox = New-Object System.Windows.Forms.GroupBox
$ScopeGroupBox.Text = "Execution Scope"
$ScopeGroupBox.Location = New-Object System.Drawing.Point(18, 140)
$ScopeGroupBox.Size = New-Object System.Drawing.Size(447, 135)
$ToolTip.SetToolTip($ScopeGroupBox, "Determine the exact permissions framework for the launched process.")
$ClientPanel.Controls.Add($ScopeGroupBox)

$ScopeLabel = New-Object System.Windows.Forms.Label
$ScopeLabel.Text = "Run As:"
$ScopeLabel.Location = New-Object System.Drawing.Point(15, 30)
$ScopeLabel.AutoSize = $true
$ScopeGroupBox.Controls.Add($ScopeLabel)

$ScopeComboBox = New-Object System.Windows.Forms.ComboBox
$ScopeComboBox.Location = New-Object System.Drawing.Point(90, 27)
$ScopeComboBox.Size = New-Object System.Drawing.Size(340, 25)
$ScopeComboBox.DropDownStyle = [System.Windows.Forms.ComboBoxStyle]::DropDownList
$ScopeComboBox.Items.Add("Current User (Elevated)")
$ScopeComboBox.Items.Add("NT AUTHORITY\SYSTEM")
$ScopeComboBox.Items.Add("Specific User / Domain")
$ScopeComboBox.SelectedIndex = 1 
$ToolTip.SetToolTip($ScopeComboBox, "Defines the token structure. SYSTEM is the classic, but do what you must.")
$ScopeGroupBox.Controls.Add($ScopeComboBox)

$UserLabel = New-Object System.Windows.Forms.Label
$UserLabel.Text = "Username:"
$UserLabel.Location = New-Object System.Drawing.Point(15, 68)
$UserLabel.AutoSize = $true
$ScopeGroupBox.Controls.Add($UserLabel)

$UserTextBox = New-Object System.Windows.Forms.TextBox
$UserTextBox.Location = New-Object System.Drawing.Point(90, 65)
$UserTextBox.Size = New-Object System.Drawing.Size(340, 25)
$UserTextBox.Enabled = $false
$ToolTip.SetToolTip($UserTextBox, "Domain\Username format preferred, unless it's a local pleb account.")
$ScopeGroupBox.Controls.Add($UserTextBox)

$PassLabel = New-Object System.Windows.Forms.Label
$PassLabel.Text = "Password:"
$PassLabel.Location = New-Object System.Drawing.Point(15, 101)
$PassLabel.AutoSize = $true
$ScopeGroupBox.Controls.Add($PassLabel)

$PassTextBox = New-Object System.Windows.Forms.TextBox
$PassTextBox.Location = New-Object System.Drawing.Point(90, 98)
$PassTextBox.Size = New-Object System.Drawing.Size(340, 25)
$PassTextBox.UseSystemPasswordChar = $true
$PassTextBox.Enabled = $false
$ToolTip.SetToolTip($PassTextBox, "Your secret password. Masked visually, but PsExec uses it in plain text, so keep your network secure.")
$ScopeGroupBox.Controls.Add($PassTextBox)

# Flags
$InteractiveCheckbox = New-Object System.Windows.Forms.CheckBox
$InteractiveCheckbox.Text = "Interactive UI (-i)"
$InteractiveCheckbox.Location = New-Object System.Drawing.Point(18, 290)
$InteractiveCheckbox.AutoSize = $true
$InteractiveCheckbox.Checked = $true
$ToolTip.SetToolTip($InteractiveCheckbox, "Ensures the spawned process actually renders on your current desktop Session 1.")
$ClientPanel.Controls.Add($InteractiveCheckbox)

$Form.Controls.Add($ClientPanel)
$Form.Controls.Add($ChinPanel)
$Form.Controls.Add($BannerPanel)

# ==============================================================================
# Events & Logic
# ==============================================================================

# ComboBox Logic
$ScopeComboBox.add_SelectedIndexChanged({
    if ($ScopeComboBox.SelectedIndex -eq 2) {
        $UserTextBox.Enabled = $true
        $PassTextBox.Enabled = $true
    } else {
        $UserTextBox.Enabled = $false
        $PassTextBox.Enabled = $false
    }
})

# Drag and Drop Events
$DragEnterAction = {
    if ($_.Data.GetDataPresent([System.Windows.Forms.DataFormats]::FileDrop)) {
        $_.Effect = [System.Windows.Forms.DragDropEffects]::Copy
    }
}

$DragDropAction = {
    $Files = $_.Data.GetData([System.Windows.Forms.DataFormats]::FileDrop)
    if ($Files.Count -gt 0) {
        $TargetTextBox.Text = $Files[0]
        Write-Log "Target acquired via GUI UIPI drag-and-drop: $($Files[0])" "0x00000003"
    }
}

$ClientPanel.add_DragEnter($DragEnterAction)
$ClientPanel.add_DragDrop($DragDropAction)
$Form.AllowDrop = $true
$Form.add_DragEnter($DragEnterAction)
$Form.add_DragDrop($DragDropAction)

$BrowseButton.add_Click({
    $OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $OpenFileDialog.Filter = "Executables (*.exe;*.bat;*.cmd;*.ps1)|*.exe;*.bat;*.cmd;*.ps1|All Files (*.*)|*.*"
    $OpenFileDialog.Title = "Select Target Executable"
    if ($OpenFileDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $TargetTextBox.Text = $OpenFileDialog.FileName
    }
})

$LogLink.add_Click({
    if (Test-Path $LogFile) {
        Start-Process "notepad.exe" -ArgumentList "`"$LogFile`""
    } else {
        [System.Windows.Forms.MessageBox]::Show("Log file has not been materialized yet.", "Missing Logs", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    }
})

$ExitButton.add_Click({
    Write-Log "User initiated exit sequence." "0x00000004"
    $Form.Close()
})

$ApplyButton.add_Click({
    $Target = $TargetTextBox.Text.Trim()
    
    if ([string]::IsNullOrWhiteSpace($Target) -or -not (Test-Path $Target)) {
        [System.Windows.Forms.MessageBox]::Show("The target executable path is completely void of reality.", "Execution Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        Write-Log "Launch aborted: Target path invalid or empty." "0xE0000003" $true
        return
    }

    if (-not (Test-Path $PsExecPath)) {
        [System.Windows.Forms.MessageBox]::Show("Could not locate psexec64.exe. Ensure it resides alongside this tool.", "PsExec Missing", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        Write-Log "Failed execution: PsExec64.exe pulled a vanishing act." "0xE0000004" $true
        return
    }

    $PsArgs = ""
    
    # Scope Logic Application
    if ($ScopeComboBox.SelectedIndex -eq 0) {
        # Current User (Elevated)
        $PsArgs += "-h "
    } elseif ($ScopeComboBox.SelectedIndex -eq 1) {
        # SYSTEM
        $PsArgs += "-s "
    } elseif ($ScopeComboBox.SelectedIndex -eq 2) {
        # Custom Credentials
        $U = $UserTextBox.Text.Trim()
        $P = $PassTextBox.Text
        if (-not [string]::IsNullOrWhiteSpace($U)) { $PsArgs += "-u `"$U`" " }
        if (-not [string]::IsNullOrWhiteSpace($P)) { $PsArgs += "-p `"$P`" " }
    }

    if ($InteractiveCheckbox.Checked) { $PsArgs += "-i " }
    
    $PsArgs += "`"$Target`""
    
    $UserArgs = $ArgsTextBox.Text.Trim()
    if (-not [string]::IsNullOrWhiteSpace($UserArgs)) {
        $PsArgs += " $UserArgs"
    }

    Write-Log "Attempting to invoke PsExec with payload configuration." "0x00000005"

    try {
        Start-Process -FilePath $PsExecPath -ArgumentList $PsArgs -Verb RunAs -ErrorAction Stop
        Write-Log "PsExec deployed successfully." "0x00000006"
    } catch {
        [System.Windows.Forms.MessageBox]::Show("Launch failed. See log for diagnostic details.", "Execution Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        Write-Log "Launch exception caught: $($_.Exception.Message)" "0xE0000005" $true
    }
})

[void]$Form.ShowDialog()