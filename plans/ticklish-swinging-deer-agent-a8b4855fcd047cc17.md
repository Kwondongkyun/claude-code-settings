# HWP 중간 포맷 변환 방법 조사 결과

> 조사일: 2026-03-26 | 15개 이상 검색 쿼리 실행 완료

## 이미 알려진 접근법 (제외)
- pyhwp -> HTML -> WeasyPrint (47-62% SSIM)
- pyhwp -> ODT -> LibreOffice (RelaxNG 에러)
- pyhwp -> TXT -> ReportLab (텍스트 전용)
- hwpers -> SVG (Rust, 미테스트)
- Custom cairo renderer (34% SSIM)

---

## 발견된 새로운 변환 체인

### 1. H2Orestart + LibreOffice -> PDF (HWP -> ODT -> PDF)
- **이름**: H2Orestart LibreOffice Extension
- **URL**: https://extensions.libreoffice.org/en/extensions/show/27504 / https://github.com/k2webtech/hwp2odt
- **변환 체인**: HWP/HWPX -> (LibreOffice import filter) -> ODT -> PDF
- **설치**: `libreoffice` 설치 후 `.oxt` 확장 설치. Debian: `sudo apt install libreoffice-hwp2odt` (hamonikr 저장소)
- **비용**: 무료 (GPL)
- **예상 품질**: 중상. v0.7.7 (2025-09-16)이 최신. LO 7.2+ 호환성 개선됨. 지속적 버그 수정 중. pyhwp ODT와 다른 접근 - 자체 C++ 바이너리 필터.
- **Linux 서버 호환**: O. Linux/Windows/macOS 지원. headless 모드: `libreoffice --headless --infilter="Hwp2002_Reader" --convert-to pdf input.hwp`
- **핵심 차이점**: pyhwp의 ODT 변환과 달리, 이것은 LibreOffice의 네이티브 import filter로 직접 HWP를 읽음. RelaxNG 에러 없음.

### 2. hwp2docx-linux (HWP -> DOCX via LibreOffice)
- **이름**: hwp2docx-linux
- **URL**: https://github.com/omakasekim/hwp2docx-linux
- **변환 체인**: HWP -> (LibreOffice + hwpfilter.oxt) -> DOCX, 폴백: HWP -> pyhwp+python-docx -> DOCX (텍스트만)
- **설치**: Homebrew, Docker, 또는 Ubuntu/Debian 네이티브. Python 3.7+, LibreOffice + HWP filter extension 필요.
- **비용**: 무료
- **예상 품질**: LibreOffice 모드에서 "high-fidelity conversion" (문서 설명). Python 폴백은 텍스트만.
- **Linux 서버 호환**: O. Docker 이미지 제공.

### 3. hwp2hwpx + python-docx (HWP -> HWPX -> DOCX)
- **이름**: hwp2hwpx (Java) + 수동 HWPX->DOCX 변환
- **URL**: https://github.com/neolord0/hwp2hwpx
- **변환 체인**: HWP -> HWPX (Java, hwplib/hwpxlib 기반) -> DOCX (별도 변환 필요)
- **설치**: Maven, Java. hwplib 1.1.4+, hwpxlib 1.0.1+ 필요.
- **비용**: 무료 (Apache-2.0)
- **예상 품질**: HWP->HWPX는 안정적 (공식 스펙 기반). HWPX->DOCX는 추가 도구 필요 (LibreOffice 또는 수동 XML 변환).
- **Linux 서버 호환**: O (Java)
- **참고**: hwpConvert (https://github.com/yuseok-kim-edushare/hwpConvert)도 Java Spring 기반 HWP(X)<->DOCX 양방향 변환 제공. Java 21 + Spring Boot.

### 4. any2pdf (HWP -> PDF via LibreOffice, 폴백 hwp5txt)
- **이름**: any2pdf
- **URL**: https://github.com/maenjh/any2pdf
- **변환 체인**: HWP -> LibreOffice CLI -> PDF (1차), HWP -> hwp5txt 텍스트 추출 (폴백)
- **설치**: `pip install`. Python 3.10+, LibreOffice CLI, pyhwp, python-docx, markdown, beautifulsoup4 필요.
- **비용**: 무료
- **예상 품질**: LibreOffice 의존이므로 H2Orestart 확장 설치 시 품질 동일.
- **Linux 서버 호환**: O. CLI + GUI 모두 제공.
- **참고**: hwp2docx 모듈도 포함 (LibreOffice -> DOCX).

### 5. hwp-parser (HWP -> HTML/PDF, Python + Chromium)
- **이름**: hwp-parser
- **URL**: https://github.com/HariFatherKR/hwp-parser
- **변환 체인**: HWP -> HTML, HWP -> PDF (Chromium 이용), HWP -> ODT, HWP -> Text. 또한 Markdown/HTML/DOCX -> HWPX 역변환.
- **설치**: Python. pyhwp 기반. 시스템 의존: Pandoc, Chromium/Chrome.
- **비용**: 무료 (AGPL v3 - 서비스 배포 시 소스 공개 의무)
- **예상 품질**: pyhwp 기반이므로 HTML 품질은 pyhwp와 유사할 수 있으나, Chromium PDF 렌더링은 WeasyPrint보다 나을 가능성.
- **Linux 서버 호환**: O. headless Chromium 필요.
- **추가 기능**: RAG 파이프라인, LangChain 통합, 문서 청킹, 메타데이터 추출.

### 6. @ohah/hwpjs (HWP -> HTML with CSS layout, Rust+WASM)
- **이름**: hwpjs (@ohah/hwpjs)
- **URL**: https://github.com/ohah/hwpjs
- **변환 체인**: HWP -> HTML (CSS 스타일링), HWP -> Markdown, HWP -> JSON
- **설치**: npm. Rust 코어(hwp-core) + NAPI-RS Node.js 바인딩. WASM도 지원.
- **비용**: 무료
- **예상 품질**: "CSS 스타일링이 적용된 완전한 HTML 문서 생성". 섹션 기반 페이지 레이아웃, 헤더/푸터, 페이지 번호 렌더링. pyhwp HTML보다 레이아웃 보존 가능성 높음.
- **Linux 서버 호환**: O (Node.js/WASM). Puppeteer로 HTML->PDF 변환 가능.
- **변환 체인 가능**: HWP -> hwpjs HTML -> Puppeteer/Playwright -> PDF

### 7. pyhwp2md (HWP -> Markdown -> PDF)
- **이름**: pyhwp2md
- **URL**: https://github.com/pitzcarraldo/pyhwp2md
- **변환 체인**: HWP/HWPX -> Markdown -> (pandoc/weasyprint 등) -> PDF
- **설치**: Python. pyhwp + python-hwpx 의존.
- **비용**: 무료
- **예상 품질**: 낮음-중간. 테이블은 Markdown pipe 포맷. 이미지/링크는 미지원 또는 부분 지원.
- **Linux 서버 호환**: O.

### 8. unhwp (HWP -> Markdown/JSON, Rust CLI)
- **이름**: unhwp
- **URL**: https://github.com/iyulab/unhwp
- **변환 체인**: HWP/HWPX -> Markdown, Plain Text, JSON (메타데이터 포함)
- **설치**: pre-built 바이너리 (Linux x64, macOS Intel/ARM, Windows). 또는 `cargo install unhwp-cli`.
- **비용**: 무료
- **예상 품질**: 구조 보존 (헤딩, 리스트, 테이블, 인라인 포맷, 이미지 임베드). Markdown->PDF는 pandoc 등으로 추가 변환 필요.
- **Linux 서버 호환**: O. pre-built Linux 바이너리 제공.

### 9. PyMuPDF Pro (HWP -> PDF 직접 변환)
- **이름**: PyMuPDF Pro
- **URL**: https://pymupdf.readthedocs.io/en/latest/pymupdf-pro/index.html
- **변환 체인**: HWP/HWPX -> PDF (직접 변환, Document.convert_to_pdf())
- **설치**: `pip install PyMuPDFPro`
- **비용**: 유료 (Commercial license). 무료 시 3페이지 제한. Trial key 가능.
- **예상 품질**: 높음 (상용 수준).
- **Linux 서버 호환**: O.
- **참고**: 무료가 아님. 3페이지 제한은 실용성 낮음.

### 10. hwp.js + Puppeteer (HWP -> HTML -> Screenshot/PDF)
- **이름**: hwp.js
- **URL**: https://github.com/hahnlee/hwp.js
- **변환 체인**: HWP -> hwp.js 파싱 -> HTML 렌더링 -> Puppeteer PDF/스크린샷
- **설치**: npm. Chrome/Chromium 필요.
- **비용**: 무료 (Apache-2.0)
- **예상 품질**: 중간. v0.0.3 (2020년 10월)으로 오래됨. 기본적인 뷰어 수준. 1.3k stars이지만 유지보수 부족.
- **Linux 서버 호환**: O (headless Chrome 필요).

### 11. HWPCONV (HWP -> HTML/Markdown, Windows only)
- **이름**: HWPCONV
- **URL**: https://github.com/jeongsuho-lawyer/HWPCONV
- **변환 체인**: HWP/HWPX -> HTML, HWP/HWPX -> Markdown (+ AI 이미지 분석)
- **설치**: Windows 10/11 전용. Python + PyInstaller.
- **비용**: 무료
- **예상 품질**: 중간. 테이블 구조 보존. 이미지는 Gemini AI로 텍스트 설명 변환.
- **Linux 서버 호환**: X (Windows 전용)

### 12. hwpConvert (HWP(X) <-> DOCX, Java Spring)
- **이름**: hwpConvert
- **URL**: https://github.com/yuseok-kim-edushare/hwpConvert
- **변환 체인**: HWP(X) -> DOCX, DOCX -> HWPX (양방향)
- **설치**: Java 21 + Spring Boot + Redis + MySQL/MSSQL. `./gradlew build`.
- **비용**: 무료
- **예상 품질**: 미확인. 웹 앱 형태라 직접 테스트 필요.
- **Linux 서버 호환**: O (Java Spring Boot).

### 13. pyhwpx (HWP 자동화, Windows only)
- **이름**: pyhwpx
- **URL**: https://pypi.org/project/pyhwpx/
- **변환 체인**: HWP -> (한글 프로그램 자동화) -> PDF/DOCX/기타 (SaveAs)
- **설치**: `pip install pyhwpx`. Windows + 한글(아래아한글) 설치 필수.
- **비용**: 무료 (한글 프로그램 라이선스 별도)
- **예상 품질**: 최고 (네이티브 앱이 직접 변환)
- **Linux 서버 호환**: X (Windows + 한글 프로그램 필수)

### 14. Hancom DocsConverter API 리버싱 (sigridjineth/hwp2pdf)
- **이름**: hwp2pdf
- **URL**: https://github.com/sigridjineth/hwp2pdf
- **변환 체인**: HWP -> Hancom DocsConverter API (리버스 엔지니어링) -> PDF
- **설치**: Python. Cookie 기반 인증 필요.
- **비용**: 무료 (API 남용 가능성, 불안정)
- **예상 품질**: 높음 (한컴 공식 엔진 사용). 하지만 Cookie 만료 시 동작 불가.
- **Linux 서버 호환**: O (API 호출만 하므로). 하지만 안정성 문제.

---

## 변환 체인별 정리

### HWP -> DOCX -> PDF
| 도구 | 방법 | 품질 | Linux |
|------|------|------|-------|
| hwp2docx-linux | LibreOffice + hwpfilter.oxt | 중상 | O (Docker) |
| any2pdf/hwp2docx | LibreOffice CLI | 중상 | O |
| hwpConvert | Java Spring (자체 구현) | 미확인 | O |

### HWP -> ODT -> PDF
| 도구 | 방법 | 품질 | Linux |
|------|------|------|-------|
| H2Orestart | LO extension (C++ 바이너리 필터) | 중상 | O |
| libreoffice-hwp2odt | Debian 패키지 (H2Orestart 기반) | 중상 | O |

### HWP -> HTML -> PDF
| 도구 | 방법 | 품질 | Linux |
|------|------|------|-------|
| @ohah/hwpjs | Rust+WASM -> CSS HTML -> Puppeteer | 중상 (추정) | O |
| hwp.js | JS 파싱 -> HTML -> Puppeteer | 중 (오래됨) | O |
| hwp-parser | pyhwp -> HTML -> Chromium PDF | 중 | O |

### HWP -> HWPX -> DOCX -> PDF
| 도구 | 방법 | 품질 | Linux |
|------|------|------|-------|
| hwp2hwpx + LO | Java(hwplib) -> HWPX -> LO -> DOCX/PDF | 중상 (추정) | O |

### HWP -> Markdown -> PDF
| 도구 | 방법 | 품질 | Linux |
|------|------|------|-------|
| pyhwp2md | pyhwp -> MD -> pandoc -> PDF | 낮음-중 | O |
| unhwp | Rust CLI -> MD -> pandoc -> PDF | 중 | O |
| @ohah/hwpjs | Rust -> MD -> pandoc -> PDF | 중 | O |

### HWP -> SVG -> PDF
| 도구 | 방법 | 품질 | Linux |
|------|------|------|-------|
| hwpers | Rust, SVG 렌더링 | 높음 (추정) | O (Rust 필요) |

### HWP -> Image -> PDF
| 도구 | 방법 | 품질 | Linux |
|------|------|------|-------|
| hwp.js + Puppeteer screenshot | HTML 렌더 -> 스크린샷 | 중 | O |
| @ohah/hwpjs + Puppeteer | CSS HTML -> 스크린샷 | 중상 | O |

### HWP -> RTF -> PDF
- 자체 호스팅 가능한 오픈소스 도구 **없음**. 온라인 서비스(CloudConvert 등)만 존재.

### HWP -> LaTeX -> PDF
- 직접 변환 도구 **없음**. HWP -> Markdown -> pandoc -> LaTeX -> PDF 체인은 이론적으로 가능하나 실용성 낮음.

---

## 우선순위 추천 (Linux 서버, 무료, 품질 순)

### Tier 1: 가장 유망 (바로 테스트 가능)
1. **H2Orestart v0.7.7 + LibreOffice headless** - HWP->ODT->PDF. 가장 활발히 유지보수됨. 2025-09 최신 릴리스.
2. **hwp2docx-linux + Docker** - HWP->DOCX->PDF. Docker 이미지로 쉽게 테스트.
3. **@ohah/hwpjs + Puppeteer** - HWP->HTML(CSS)->PDF. Rust 코어로 레이아웃 보존 가능성 높음.

### Tier 2: 시도 가치 있음
4. **hwp2hwpx (Java) + LibreOffice** - HWP->HWPX->PDF. 자바 환경 필요.
5. **hwp-parser + Chromium** - pyhwp 기반이나 Chromium PDF가 WeasyPrint보다 나을 수 있음.
6. **unhwp + pandoc** - HWP->MD->PDF. 구조 보존 좋으나 레이아웃은 제한적.

### Tier 3: 조건부 사용
7. **PyMuPDF Pro** - 유료이나 Trial로 테스트 가능. 품질 최고 수준일 가능성.
8. **pyhwpx** - Windows+한글 필요. 품질 최고이나 서버 환경 부적합.
9. **hwpers (Rust SVG)** - Rust 환경 설정 필요. SVG->PDF 품질 높을 수 있음.
