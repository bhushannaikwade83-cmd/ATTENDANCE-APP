@echo off
echo ==========================================
echo   PUSH CODE TO GITHUB - ATTENDANCE APP
echo ==========================================
echo.

:: Check if git is installed
git --version >nul 2>&1
if %errorlevel% neq 0 (
    echo [ERROR] Git is not installed or not in PATH.
    echo Please install Git from https://git-scm.com/downloads
    pause
    exit /b
)

:: Initialize git if not already initialized
if not exist .git (
    echo [INFO] Initializing new Git repository...
    git init
    echo.
)

:: Ask for GitHub Repository URL
set /p REPO_URL="Enter your GitHub Repository URL (e.g., https://github.com/username/repo.git): "

if "%REPO_URL%"=="" (
    echo [ERROR] Repository URL cannot be empty.
    pause
    exit /b
)

:: Add remote origin
git remote remove origin >nul 2>&1
git remote add origin %REPO_URL%

:: Add all files
echo [INFO] Adding files...
git add .

:: Commit and Push
echo [INFO] Committing and Pushing...
git commit -m "Update Attendance App code"
git branch -M main
git push -u origin main

echo.
echo [SUCCESS] Code pushed to GitHub!
pause