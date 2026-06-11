# 유지보수 사례 검색기

유지보수 내역서 엑셀 파일을 읽어서 장애내용/조치내용을 인덱싱하고, 다음 순서로 유사 사례를 찾는 GUI 프로그램입니다.

1. 키워드 검색: BM25
2. 벡터 검색: TF-IDF 기반 코사인 유사도
3. 조건 필터: 연도, 부서, 사용자, APC / PC filter / UTMP

## 실행

```powershell
.\.venv\Scripts\python.exe app.py
```

## 인덱스 저장 위치

선택한 데이터 폴더 아래의 `.maintenance_search_cache` 폴더에 저장됩니다.

## 실행파일 생성

```powershell
powershell -ExecutionPolicy Bypass -File .\build_exe.ps1
```

생성 결과:

- `dist\유지보수사례검색기.exe`
