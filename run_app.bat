@echo off
setlocal
cd /d "%~dp0"

if exist ".venv\Scripts\python.exe" (
    ".venv\Scripts\python.exe" app.py
) else (
    py -3 app.py
)

if errorlevel 1 (
    echo.
    echo 프로그램 실행에 실패했습니다.
    echo Python 또는 필수 패키지가 설치되어 있는지 확인하세요.
    pause
)
