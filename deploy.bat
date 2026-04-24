@echo off
setlocal enabledelayedexpansion

echo ========================================
echo 🚀 Building Flutter Web...
echo ========================================

cd flutter_app
call flutter build web --release
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Web build failed!
    cd ..
    pause
    exit /b %ERRORLEVEL%
)
cd ..

echo ========================================
echo 📁 Copying Web Build to backend/public...
echo ========================================

if not exist "backend\public" mkdir "backend\public"

:: Clear existing web files but keep APKs (which have .apk extension)
powershell -Command "Get-ChildItem backend/public -Exclude *.apk, .gitkeep | Remove-Item -Recurse -Force"

:: Copy new build
xcopy /E /I /Y "flutter_app\build\web\*" "backend\public\"

echo ========================================
echo 📤 Pushing to GitHub...
echo ========================================

git add .
set /p COMMIT_MSG="Enter commit message (Press Enter for 'Deploy web build'): "
if "!COMMIT_MSG!"=="" set COMMIT_MSG=Deploy web build

git commit -m "!COMMIT_MSG!"
git push

echo ========================================
echo ✅ Done! Web build deployed to backend/public and pushed to GitHub.
echo ========================================
pause
