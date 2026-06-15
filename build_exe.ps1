$ErrorActionPreference = 'Stop'

$python = ".\.venv\Scripts\python.exe"
$appName = [Text.Encoding]::UTF8.GetString(
    [Convert]::FromBase64String("7Jyg7KeA67O07IiY7IKs66GA6rKA7IOJ6riw")
)
$internalName = "maintenance_search_app"

if (-not (Test-Path $python)) {
    if (Get-Command py -ErrorAction SilentlyContinue) {
        & py -m venv .venv
    }
    elseif (Get-Command python -ErrorAction SilentlyContinue) {
        & python -m venv .venv
    }
    else {
        throw "Python을 찾을 수 없습니다. Python을 설치한 뒤 다시 실행하세요."
    }

    if ($LASTEXITCODE -ne 0) {
        throw "가상환경 생성에 실패했습니다."
    }
}

& $python -m pip install -r requirements.txt
if ($LASTEXITCODE -ne 0) {
    throw "필수 패키지 설치에 실패했습니다."
}

# uv 기반 Python은 PyInstaller의 Tcl/Tk 자동 감지가 실패할 수 있으므로
# 빌드 중에만 임시 hook을 만들어 tkinter와 Tcl/Tk 리소스를 포함합니다.
$pythonBase = (& $python -c "import sys; print(sys.base_prefix)").Trim()
$env:TCL_LIBRARY = Join-Path $pythonBase "tcl\tcl8.6"
$env:TK_LIBRARY = Join-Path $pythonBase "tcl\tk8.6"

& $python -c "import tkinter, _tkinter; print('Tkinter 모듈 확인:', tkinter.TkVersion, _tkinter.__file__)"
if ($LASTEXITCODE -ne 0) {
    throw "현재 Python에서 tkinter를 사용할 수 없습니다. Tcl/Tk가 포함된 Python으로 .venv를 다시 생성하세요."
}

foreach ($requiredPath in @(
    (Join-Path $env:TCL_LIBRARY "init.tcl"),
    (Join-Path $env:TK_LIBRARY "tk.tcl"),
    (Join-Path $pythonBase "DLLs\_tkinter.pyd"),
    (Join-Path $pythonBase "DLLs\tcl86t.dll"),
    (Join-Path $pythonBase "DLLs\tk86t.dll")
)) {
    if (-not (Test-Path -LiteralPath $requiredPath)) {
        throw "Tkinter 빌드에 필요한 파일을 찾을 수 없습니다: $requiredPath"
    }
}

$tempBuildConfig = Join-Path ([IO.Path]::GetTempPath()) ("maintenance-search-build-" + [guid]::NewGuid().ToString("N"))
$tempPreHookDir = Join-Path $tempBuildConfig "pre_find_module_path"
$appPath = (Resolve-Path ".\app.py").Path
$distPath = Join-Path (Get-Location) "dist"
$workPath = Join-Path (Get-Location) "build"

try {
    New-Item -ItemType Directory -Path $tempPreHookDir -Force | Out-Null

    @'
def pre_find_module_path(hook_api):
    return
'@ | Set-Content -LiteralPath (Join-Path $tempPreHookDir "hook-tkinter.py") -Encoding UTF8

    @'
from pathlib import Path
import sys

python_root = Path(sys.base_prefix)
tcl_root = python_root / "tcl"
dll_root = python_root / "DLLs"

datas = []
binaries = []

for source_name, destination in (
    ("tcl8.6", "_tcl_data"),
    ("tk8.6", "_tk_data"),
    ("tcl8", "tcl8"),
):
    source = tcl_root / source_name
    if source.is_dir():
        datas.append((str(source), destination))

for dll_name in ("tcl86t.dll", "tk86t.dll"):
    source = dll_root / dll_name
    if source.is_file():
        binaries.append((str(source), "."))
'@ | Set-Content -LiteralPath (Join-Path $tempBuildConfig "hook-_tkinter.py") -Encoding UTF8

    & $python -m PyInstaller `
        --noconfirm `
        --clean `
        --onefile `
        --windowed `
        --additional-hooks-dir $tempBuildConfig `
        --hidden-import "tkinter" `
        --hidden-import "_tkinter" `
        --specpath $tempBuildConfig `
        --distpath $distPath `
        --workpath $workPath `
        --name $internalName `
        $appPath
    if ($LASTEXITCODE -ne 0) {
        throw "실행 파일 생성에 실패했습니다."
    }

    $temporaryExe = Join-Path $distPath ($internalName + ".exe")
    $finalExe = Join-Path $distPath ($appName + ".exe")
    if (Test-Path -LiteralPath $finalExe) {
        Remove-Item -LiteralPath $finalExe -Force
    }
    Move-Item -LiteralPath $temporaryExe -Destination $finalExe

    $temporaryWorkDir = Join-Path $workPath $internalName
    if (Test-Path -LiteralPath $temporaryWorkDir) {
        Remove-Item -LiteralPath $temporaryWorkDir -Recurse -Force
    }
}
finally {
    if (Test-Path -LiteralPath $tempBuildConfig) {
        Remove-Item -LiteralPath $tempBuildConfig -Recurse -Force
    }
}

Write-Host ("Build complete: dist\" + $appName + ".exe")
