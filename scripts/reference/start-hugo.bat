@echo off
cd /d "%~dp0"

REM Check if wrangler is installed
where wrangler >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo ERROR: Wrangler is not installed.
    echo.
    echo Wrangler is the Cloudflare Pages CLI tool needed for local development with redirect support.
    echo.
    echo To install Wrangler, run:
    echo   npm install -g wrangler
    echo.
    echo If you don't have Node.js/npm installed, run:
    echo   winget install OpenJS.NodeJS.LTS
    echo.
    echo Alternatively, you can use the build.ps1 script for development without Wrangler:
    echo   .\build.ps1
    echo.
    pause
    exit /b 1
)

echo Building site...
"%USERPROFILE%\AppData\Local\Microsoft\WinGet\Packages\Hugo.Hugo.Extended_Microsoft.Winget.Source_8wekyb3d8bbwe\hugo.exe" -D
echo Starting Cloudflare Pages local dev server...
wrangler pages dev ./public --port 1313
pause