$ErrorActionPreference = 'Stop'

$python = ".\.venv\Scripts\python.exe"

& $python -m pip install -r requirements.txt
& $python -m PyInstaller --noconfirm --clean --onefile --windowed --name "유지보수사례검색기" app.py
Write-Host "완료: dist\유지보수사례검색기.exe"
