# PDF 텍스트 추출 개선: nxtgen-hwp-parser 도입

## Context

현재 HWP 파일은 `pyhwp + weasyprint`로 PDF로 변환한 뒤, `PyPDF2`로 그 PDF에서 텍스트를 추출한다.
HWP → PDF 변환 과정에서 텍스트 품질이 떨어지므로, HWP 원본에서 직접 텍스트를 추출하면 AI 분석 품질이 올라간다.
PDF 원본 파일은 그대로 PyPDF2를 사용한다.

---

## 변경 범위

| 파일 | 변경 내용 |
|------|---------|
| `libs/nxtgen-hwp-parser/` | 레포 클론 위치 (신규 디렉토리) |
| `requirements.txt` | `nxtgen-hwp-parser` 로컬 경로 참조 추가 |
| `Dockerfile` | `libs/` 먼저 COPY 후 pip install 순서 조정 |
| `app/ai_analyzer.py` | `extract_text_from_file()` 추가, `analyze_order_plan_detailed` 파라미터 변경 |
| `app/toxic_clause_analyzer.py` | `extract_text_from_file()` 사용, `analyze_toxic_clauses` 파라미터 변경 |
| `app/slack/notifier.py` | 원본 파일 경로(hwp/pdf) 추적, 분석 함수에 원본 경로 전달 |

---

## 구현 계획

### 1. 라이브러리 배치 및 설치

**배포 전략**: `libs/nxtgen-hwp-parser/` 소스를 메인 레포에 직접 커밋 (vendor 방식)
- `.gitignore`에 `lib/`만 있고 `libs/`는 없으므로 그대로 커밋 가능
- EC2에서 `git pull` 한 번으로 소스 포함 자동 수신, 토큰/SSH 불필요

**로컬 초기 세팅:**
```bash
# 프로젝트 루트에서
git clone https://<TOKEN>@github.com/Arc1el/nxtgen-hwp-parser.git libs/nxtgen-hwp-parser

# 로컬 venv에 설치 (wheel로 빌드 → site-packages에 복사됨)
source venv/bin/activate
pip install ./libs/nxtgen-hwp-parser
```

**이후 EC2 배포 흐름:**
```
git push → EC2 git pull → libs/ 포함 → docker build → pip install ./libs/nxtgen-hwp-parser
```

### 2. `Dockerfile` 수정

`libs/`를 `pip install` 전에 먼저 COPY해야 `requirements.txt`의 로컬 경로 참조가 동작함:

```dockerfile
# 기존
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .

# 변경
COPY libs/nxtgen-hwp-parser ./libs/nxtgen-hwp-parser
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY . .
```

### 3. `requirements.txt`

```
nxtgen-hwp-parser @ file:./libs/nxtgen-hwp-parser
```
기존 `PyPDF2` 항목은 PDF 원본 처리용으로 유지.

---

### 4. `app/ai_analyzer.py`

**통합 텍스트 추출 함수 추가** (기존 `extract_text_from_pdf` 대체):

```python
def extract_text_from_file(file_path: Path, max_pages: int = 30) -> str:
    """파일 형식에 따라 텍스트 추출.
    - .hwp / .hwpx → nxtgen-hwp-parser (원본 직접 추출)
    - .pdf         → PyPDF2
    """
    ext = file_path.suffix.lower()
    if ext in ['.hwp', '.hwpx']:
        try:
            from nxtgen_hwp_parser import parse_hwp
            result = parse_hwp(str(file_path))
            return result.get("text", "")
        except Exception as e:
            logger.error(f"HWP 텍스트 추출 실패 ({file_path}): {e}")
            return ""
    else:  # .pdf
        try:
            from PyPDF2 import PdfReader
            reader = PdfReader(str(file_path))
            text = ""
            for page in reader.pages[:max_pages]:
                text += page.extract_text() + "\n"
            return text
        except Exception as e:
            logger.error(f"PDF 텍스트 추출 실패 ({file_path}): {e}")
            return ""
```

**`analyze_order_plan_detailed` 파라미터 변경**:
- 기존: `pdf_paths: List[Path]`
- 변경: `source_paths: List[Path]` (원본 파일 경로, HWP/PDF 모두 가능)
- 내부에서 `extract_text_from_file()` 호출

---

### 5. `app/toxic_clause_analyzer.py`

**기존 `extract_text_from_pdf` 제거**하고 `ai_analyzer.extract_text_from_file` import해서 재사용.

**`analyze_toxic_clauses` 파라미터 변경**:
- 기존: `pdf_paths: List[Path]`
- 변경: `source_paths: List[Path]` (원본 파일 경로)

---

### 6. `app/slack/notifier.py` (`analyze_and_reply_attachments`)

파일 처리 루프에서 `pdf_paths` 외에 **`source_paths` (원본 경로)** 도 함께 수집:

```python
# 기존
pdf_paths = []
successful_files = []

# 변경
pdf_paths = []       # Slack 업로드용 (PDF)
source_paths = []    # 텍스트 추출용 (HWP or PDF 원본)
successful_files = []

# 루프 내부 변경
pdf_paths.append(pdf_path)
source_paths.append(file_path)   # 원본 경로 (변환 전)
```

분석 함수 호출 시 `source_paths` 전달:
```python
# 기존
detailed_analysis = await analyze_order_plan_detailed(bid_notice, pdf_paths)
analysis_result   = await analyze_toxic_clauses(pdf_paths)

# 변경
detailed_analysis = await analyze_order_plan_detailed(bid_notice, source_paths)
analysis_result   = await analyze_toxic_clauses(source_paths)
```

Slack 파일 업로드는 **`pdf_paths` 그대로** 유지.

---

## 유의사항

- `agent_executor.py`의 `_draft_proposal`은 DB에 저장된 `converted_pdf_path`(PDF)를 읽어 텍스트 추출하는데, 이번 변경 범위에 포함되지 않는다. 원본 HWP 경로를 DB에 별도 저장하는 구조 변경이 필요하므로 별도 작업으로 분리.
- `parse_hwp()["text"]`는 순수 텍스트, `["markdown"]`은 표/구조 보존. 현재는 text 사용 (단순, 안정적).

---

## 검증 순서

1. **로컬 적용 및 테스트**
   - 코드 변경 및 라이브러리 설치
   - 서버 기동 후 HWP 첨부파일 있는 공고 알림 확인
   - AI 분석 텍스트 품질 확인, PDF 원본도 정상 동작 확인

2. **main 브랜치에 커밋/푸시**
   - `libs/nxtgen-hwp-parser/` 포함해서 커밋

3. **EC2 배포**
   ```bash
   git pull
   docker compose up -d --build app
   ```
   → Docker 이미지 재빌드 시 `COPY libs/nxtgen-hwp-parser` → `pip install` 자동 처리
