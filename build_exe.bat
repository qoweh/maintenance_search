@echo off
setlocal EnableExtensions
chcp 65001 >nul
cd /d "%~dp0"

set "APP_NAME=유지보수사례검색기"
set "PYTHON_CMD="
set "BUILD_ENV=%TEMP%\maintenance_search_build_%RANDOM%%RANDOM%"
set "BUILD_WORK=%TEMP%\maintenance_search_work_%RANDOM%%RANDOM%"
set "SPEC_DIR=%TEMP%\maintenance_search_spec_%RANDOM%%RANDOM%"
set "FAILED=0"

echo.
echo 유지보수 사례 검색기 실행 파일 생성
echo.

if not exist "app.py" (
    echo app.py 파일을 찾을 수 없습니다.
    goto fail
)

if not exist "requirements.txt" (
    echo requirements.txt 파일을 찾을 수 없습니다.
    goto fail
)

where py >nul 2>nul
if not errorlevel 1 (
    py -3 -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" >nul 2>nul
    if not errorlevel 1 set "PYTHON_CMD=py -3"
)

if not defined PYTHON_CMD (
    where python >nul 2>nul
    if not errorlevel 1 (
        python -c "import sys; raise SystemExit(0 if sys.version_info >= (3, 10) else 1)" >nul 2>nul
        if not errorlevel 1 set "PYTHON_CMD=python"
    )
)

if not defined PYTHON_CMD (
    echo Python 3.10 이상을 찾을 수 없습니다.
    echo https://www.python.org/downloads/windows/ 에서 Python을 설치한 뒤 다시 실행하세요.
    goto fail
)

echo [1/4] 임시 빌드 환경 생성 중...
%PYTHON_CMD% -m venv "%BUILD_ENV%"
if errorlevel 1 goto fail

set "PYTHON_EXE=%BUILD_ENV%\Scripts\python.exe"
if not exist "%PYTHON_EXE%" (
    echo 임시 Python 환경 생성에 실패했습니다.
    goto fail
)

echo [2/4] 필수 패키지 설치 중...
"%PYTHON_EXE%" -m pip install --upgrade pip
if errorlevel 1 goto fail
"%PYTHON_EXE%" -m pip install -r requirements.txt
if errorlevel 1 goto fail

echo [3/4] PyInstaller 빌드 중...
if not exist "dist" mkdir "dist"
if exist "dist\%APP_NAME%.exe" del /f /q "dist\%APP_NAME%.exe"

"%PYTHON_EXE%" -m PyInstaller ^
    --noconfirm ^
    --clean ^
    --onefile ^
    --windowed ^
    --name "%APP_NAME%" ^
    --distpath "%CD%\dist" ^
    --workpath "%BUILD_WORK%" ^
    --specpath "%SPEC_DIR%" ^
    --hidden-import "win32com" ^
    --hidden-import "win32com.client" ^
    "app.py"
if errorlevel 1 goto fail

if not exist "dist\%APP_NAME%.exe" (
    echo 실행 파일 생성 결과를 찾을 수 없습니다.
    goto fail
)

echo [4/4] 임시 파일 정리 중...
goto cleanup

:fail
set "FAILED=1"

:cleanup
if exist "%BUILD_ENV%" rmdir /s /q "%BUILD_ENV%"
if exist "%BUILD_WORK%" rmdir /s /q "%BUILD_WORK%"
if exist "%SPEC_DIR%" rmdir /s /q "%SPEC_DIR%"

echo.
if "%FAILED%"=="1" (
    echo 실행 파일 생성에 실패했습니다.
    echo 위 오류 내용을 확인한 뒤 다시 실행하세요.
    pause
    exit /b 1
)

echo 실행 파일 생성 완료: dist\%APP_NAME%.exe
pause
exit /b 0
