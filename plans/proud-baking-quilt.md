# PDF 추출 테스트 v2 — 새 PDF 3개 추가 테스트

## Context
pdfplumber를 nara-api 적용 후보로 선정. 새로 추가된 PDF 3개(입찰공고문, 제안요청서, 과업지시서)로 추가 테스트하여 품질을 최종 검증한다.

## 변경 사항

### `run_tests.py` 수정
- `PDF_PATH` 단일 파일 → 4개 PDF 전체 순회 구조로 변경
- 테스트 대상: 5개 라이브러리 전부 (PyPDF2, pypdf, PyMuPDF, pdfplumber, OpenDataLoader)
- 새 PDF 3개에서도 동일한 품질 차이가 나타나는지 확인

### 대상 PDF 파일 (4개)
1. `origin-pdf.pdf` (201KB, 기존)
2. `(붙임1) 입찰공고문.pdf` (324KB)
3. `(붙임2) 제안요청서.pdf` (1.1MB)
4. `(붙임3) 과업지시서.pdf` (560KB)

### 테스트 내용
- 각 PDF x 5개 라이브러리 = 총 20회 추출
- 비교: 글자수, 페이지수, 속도, 테이블 감지수(pdfplumber)
- 각 결과를 `output/{라이브러리}_{파일명}.txt`로 저장
- PDF별 + 라이브러리별 결과 요약 테이블 출력

### 출력 구조
```
output/
  pypdf2_origin-pdf.txt
  pypdf_origin-pdf.txt
  pymupdf_origin-pdf.txt
  pdfplumber_origin-pdf.txt
  opendataloader_origin-pdf.txt
  ... (x4 PDF = 20개 txt 파일)
  results_v2.json
```

## 검증
- `source .venv/bin/activate && python run_tests.py` 실행
- 4개 PDF 전부 성공 확인
- 추출된 텍스트 파일에서 한국어 깨짐/자간 문제 없는지 확인
