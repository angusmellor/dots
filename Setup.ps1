# Setup script for Windots
#Requires -RunAsAdministrator

# Linked Files (Destination => Source)
$symlinks = @{
  $PROFILE.CurrentUserAllHosts                                                                    = ".\Profile.ps1"
  "$HOME\AppData\Local\nvim"                                                                      = ".\nvim"
  "$HOME\AppData\Local\Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json" = ".\windowsterminal\settings.json"
  "$HOME\.gitconfig"                                                                              = ".\.gitconfig"
}

# Winget & choco dependencies (cmd => package name)
$wingetDeps = @(
  "Chocolatey.Chocolatey"
  "eza-community.eza"
  "Git.Git"
  "Microsoft.OpenJDK.21"
  "OpenJS.NodeJS"
  "Microsoft.PowerShell"
  "Starship.Starship"
)
$chocoDeps = @(
  "bat"
  "fd"
  "fzf"
  "gawk"
  "neovim"
  "ripgrep"
  "sed"
  "zig"
  "zoxide"
)

# Set working directory
Set-Location $PSScriptRoot
[Environment]::CurrentDirectory = $PSScriptRoot

Write-Host "Installing missing dependencies..."
$installedWingetDeps = winget list | Out-String
foreach ($wingetDep in $wingetDeps) {
  if ($installedWingetDeps -notmatch $wingetDep) {
    winget install -e --id $wingetDep
  }
}

# Path Refresh
$env:Path = [System.Environment]::GetEnvironmentVariable("Path", "Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path", "User")

$installedChocoDeps = (choco list --limit-output --id-only).Split("`n")
foreach ($chocoDep in $chocoDeps) {
  if ($installedChocoDeps -notcontains $chocoDep) {
    choco install $chocoDep -y
  }
}

Write-Host "Installing Fonts..."
# Get all installed font families
[void] [System.Reflection.Assembly]::LoadWithPartialName("System.Drawing")
$fontFamilies = (New-Object System.Drawing.Text.InstalledFontCollection).Families

# Check if CaskaydiaCove NF is installed
if ($fontFamilies -notcontains "JetBrainsMono NF") {
  # Download and install CaskaydiaCove NF
  $webClient = New-Object System.Net.WebClient
  $webClient.DownloadFile("https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/JetBrainsMono.zip", ".\JetBrainsMono.zip")

  Expand-Archive -Path ".\JetBrainsMono.zip" -DestinationPath ".\JetBrainsMono" -Force
  $destination = (New-Object -ComObject Shell.Application).Namespace(0x14)

  $fonts = Get-ChildItem -Path ".\JetBrainsMono" -Recurse -Filter "*.ttf"
  foreach ($font in $fonts) {
    # Only install standard fonts (16 fonts instead of 90+)
    if ($font.Name -like "JetBrainsMonoNerdFont-*.ttf") {
      $destination.CopyHere($font.FullName, 0x10)
    }
  }

  Remove-Item -Path ".\JetBrainsMono" -Recurse -Force
  Remove-Item -Path ".\JetBrainsMono.zip" -Force
}

$currentGitEmail = (git config --global user.email)
$currentGitName = (git config --global user.name)

# Create Symbolic Links
Write-Host "Creating Symbolic Links..."
foreach ($symlink in $symlinks.GetEnumerator()) {
  Get-Item -Path $symlink.Key -ErrorAction SilentlyContinue | Remove-Item -Force -Recurse -ErrorAction SilentlyContinue
  New-Item -ItemType SymbolicLink -Path $symlink.Key -Target (Resolve-Path $symlink.Value) -Force | Out-Null
}

git config --global --unset user.email | Out-Null
git config --global --unset user.name | Out-Null
git config --global user.email $currentGitEmail | Out-Null
git config --global user.name $currentGitName | Out-Null

