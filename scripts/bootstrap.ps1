<# scripts/bootstrap.ps1
Cross-platform bootstrap for Windows users.
Run inside Windows Terminal:
  - For WSL: open your Linux distro and run ./scripts/bootstrap.sh
  - For native Windows + Git Bash: run the .sh script from Git Bash.
If you insist on pure PowerShell + native Windows builds, install Rust via rustup-init.exe and a C++ build toolchain (e.g., MSVC via Visual Studio Build Tools).
#>

Write-Host "This project targets Linux and WSL for builds. For WSL, start your distro and run:" -ForegroundColor Cyan
Write-Host "    ./scripts/bootstrap.sh" -ForegroundColor Yellow
Write-Host ""
Write-Host "For native Windows builds (unsupported path):" -ForegroundColor Cyan
Write-Host "  1) Install Rust: https://rustup.rs/" -ForegroundColor Yellow
Write-Host "  2) Install 'Desktop development with C++' using Visual Studio Build Tools." -ForegroundColor Yellow
