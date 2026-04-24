@echo off
setlocal enabledelayedexpansion

:: Read current values from version.json
for /f "tokens=*" %%a in ('powershell -Command "(Get-Content backend/version.json | ConvertFrom-Json).latestVersion"') do set CURRENT_VER=%%a
for /f "tokens=*" %%a in ('powershell -Command "(Get-Content backend/version.json | ConvertFrom-Json).releaseNotes"') do set CURRENT_NOTES=%%a

echo Current Version: %CURRENT_VER%
set /p VERSION="Enter new version (Press Enter to keep %CURRENT_VER%): "
if "!VERSION!"=="" set VERSION=%CURRENT_VER%

set /p NOTES="Enter release notes (Press Enter to keep current): "
if "!NOTES!"=="" set NOTES=%CURRENT_NOTES%

echo ========================================
echo 📝 Updating pubspec.yaml and version.json...
echo ========================================

:: Update backend/version.json and get the new build number
powershell -Command "$json = Get-Content backend/version.json | ConvertFrom-Json; $json.latestVersion = '%VERSION%'; $json.releaseNotes = '%NOTES%'; $json.buildNumber = [int]$json.buildNumber + 1; $json | ConvertTo-Json | Set-Content backend/version.json; Write-Output $json.buildNumber" > build_num.tmp
set /p BUILD_NUM=<build_num.tmp
del build_num.tmp

:: Update flutter_app/pubspec.yaml
powershell -Command "(Get-Content flutter_app/pubspec.yaml) -replace 'version: .+', 'version: %VERSION%+%BUILD_NUM%' | Set-Content flutter_app/pubspec.yaml"
if exist build_num.tmp del build_num.tmp

echo ✅ Version set to %VERSION%+%BUILD_NUM%

echo ========================================
echo 🚀 Building APK...
echo ========================================

cd flutter_app
call flutter build apk --release
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Build failed!
    cd ..
    pause
    exit /b %ERRORLEVEL%
)
cd ..

echo ========================================
echo 📁 Copying APK to backend...
echo ========================================

set APK_FILE=schatapp-v%VERSION%-b%BUILD_NUM%.apk
if not exist "backend\public" mkdir "backend\public"
copy /Y "flutter_app\build\app\outputs\flutter-apk\app-release.apk" "backend\public\!APK_FILE!"

echo ========================================
echo 📝 Updating version.json with filename...
echo ========================================

powershell -Command "$json = Get-Content backend/version.json | ConvertFrom-Json; $json.apkFilename = '!APK_FILE!'; $json | ConvertTo-Json | Set-Content backend/version.json"

echo ========================================
echo ✅ Done! Version %VERSION%+%BUILD_NUM% is ready.
echo File: !APK_FILE!
echo Push to GitHub to deploy.
echo ========================================
pause
