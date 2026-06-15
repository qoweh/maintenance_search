@echo off
setlocal
cd /d "%~dp0"

powershell -NoProfile -ExecutionPolicy Bypass -File ".\build_exe.ps1"

if errorlevel 1 (
    echo.
    echo 실행 파일 생성에 실패했습니다.
    echo 오류 내용을 확인한 뒤 다시 실행하세요.
    pause
    exit /b 1
)

echo.
echo 실행 파일 생성 완료: dist\유지보수사례검색기.exe
pause
