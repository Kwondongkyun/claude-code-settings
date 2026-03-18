# PDF 텍스트 추출 한도 증가

## Context
AI 상세 분석 시 PDF 텍스트를 Claude 프롬프트에 전달하는데, 현재 8,000자로 제한되어 긴 문서는 잘림. Claude 3.5 Sonnet의 컨텍스트 윈도우가 200k 토큰으로 충분하므로 한도를 늘려 분석 품질 향상.

---

## 수정 내용

**파일**: `app/ai_analyzer.py`

| 항목 | 현재 | 변경 |
|---|---|---|
| 페이지 추출 한도 (`max_pages`) | 10페이지 | 30페이지 |
| Claude 전달 문자 한도 | `combined_text[:8000]` | `combined_text[:50000]` |

**수정 위치** (`analyze_order_plan_detailed` 함수):
```python
# L262 - 페이지 한도
text = extract_text_from_pdf(pdf_path, max_pages=30)  # 10 → 30

# L294 - 문자 한도
{combined_text[:50000]}  # 8000 → 50000
```

---

## 검증 방법
```bash
python3 -c "
from app.ai_analyzer import extract_text_from_pdf
from pathlib import Path
pdf_path = Path('downloads/bid_notices/R26BK01259561/1. 입찰설명서.pdf')
text = extract_text_from_pdf(pdf_path, max_pages=30)
print(f'추출 길이: {len(text)}자')
"
```
