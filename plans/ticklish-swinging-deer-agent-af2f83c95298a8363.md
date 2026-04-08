# HWP to PDF 무료 변환 방법 조사 결과 (2025-2026)

> 15개 이상의 검색 쿼리를 통해 조사 완료. 이미 알려진 도구(pyhwp, LibreOffice+H2Orestart, hwp.js, hwpers, simple-hwp2pdf, simnalamburt/hwp2pdf, atsusta/hwp2pdf, Hancom Office SDK, Dangerzone, 온라인 컨버터)는 제외.

---

## 1. ONLYOFFICE DocumentServer (v8.3+)

- **URL**: https://github.com/ONLYOFFICE/DocumentServer
- **무엇을 하는가**: 2025년 2월 v8.3부터 HWP/HWPX 파일 열기/뷰잉 지원 추가. v9.1(2025.10)에서 HWPML도 추가.
- **설치**: `docker run -d -p 80:80 onlyoffice/documentserver`
- **무료 여부**: AGPL v3 오픈소스 (Community Edition 무료, 동시 접속 20명 제한)
- **PDF 변환**: 현재 HWP 열기/뷰잉만 지원. Conversion API에 HWP 입력은 **아직 미지원** (DOCX로 변환 후 PDF로 가능). 향후 HWP -> PDF 직접 변환 추가 예정.
- **품질**: DOCX 변환 시 일부 서식 손실 가능
- **Linux 서버**: Docker로 headless 운영 가능
- **평가**: HWP -> DOCX -> PDF 2단계 파이프라인으로 우회 가능하지만 직접 변환은 아직 불가

## 2. hwpparser (HariFatherKR/hwp-parser)

- **URL**: https://github.com/HariFatherKR/hwp-parser
- **무엇을 하는가**: HWP 파일을 Text, HTML, ODT, **PDF**로 변환. HWPX 생성(MD/HTML/DOCX에서). LangChain/RAG 통합 지원.
- **설치**: `pip install hwpparser` (PDF용 Chromium 필요, HWPX용 pandoc 필요)
- **무료 여부**: MIT 라이선스 (단, pyhwp 의존성이 AGPL v3)
- **PDF 변환 방식**: HTML 렌더링 후 Chrome/Chromium으로 PDF 출력 (headless)
- **품질**: pyhwp 기반이므로 복잡한 레이아웃에서 한계 있을 수 있음
- **Linux 서버**: Chromium headless 필요하므로 가능하지만 무거움
- **평가**: pyhwp 래퍼이지만 CLI/API가 잘 정리됨. AGPL 의존성 주의.

## 3. jacepark12/hwp-converter-api

- **URL**: https://github.com/jacepark12/hwp-converter-api
- **무엇을 하는가**: LibreOffice headless + HWP 확장을 사용하여 HWP/HWPX -> PDF/DOCX 변환 API 서버. Palantir Foundry 컨테이너 환경용.
- **설치**: `docker build -t hwp-converter-api . && docker run -p 8800:8800 hwp-converter-api`
- **무료 여부**: 라이선스 명시 안됨 (GitHub에 공개)
- **PDF 변환**: POST /convert 엔드포인트로 직접 PDF 변환 지원
- **품질**: LibreOffice 기반이므로 H2Orestart 확장 품질과 동일
- **Linux 서버**: Docker 컨테이너로 운영 가능
- **평가**: 본질적으로 LibreOffice+H2Orestart를 Docker API로 감싼 것. 이미 알려진 방식의 패키징.

## 4. PyMuPDF Pro (pymupdfpro)

- **URL**: https://pymupdf.readthedocs.io/en/latest/pymupdf-pro/index.html
- **무엇을 하는가**: HWP/HWPX 파일 열기, 텍스트/테이블 추출, **PDF 변환** 지원
- **설치**: `pip install pymupdfpro` + 라이선스 키 필요
- **무료 여부**: **유료** (상용 라이선스). 트라이얼 있으나 3페이지 제한.
- **PDF 변환**: `doc.convert_to_pdf()` 메서드로 직접 변환
- **품질**: Artifex(MuPDF 제작사) 제품이므로 높은 품질 기대
- **Linux 서버**: Linux x86_64, macOS x86_64/arm64, Windows x86_64 지원
- **평가**: 기술적으로 가장 완성도 높을 가능성이 크지만 유료.

## 5. Polaris Office HWP to PDF

- **URL**: https://play.google.com/store/apps/details?id=com.polarisoffice.tools.hwptopdf
- **무엇을 하는가**: HWP/HWPX -> PDF 무료 변환 (모바일 앱 + Windows 스토어 앱 + 웹)
- **설치**: Google Play / Microsoft Store / hub.polarishare.com/en/pdf
- **무료 여부**: 무료 (무제한 변환, 서버 업로드 없이 로컬 처리)
- **PDF 변환**: 직접 지원
- **품질**: Polaris Office(전 Infraware) 자체 엔진으로 양호
- **Linux 서버**: **불가** (모바일/Windows 앱만)
- **평가**: 개인용으로는 훌륭하지만 서버/자동화에 사용 불가

## 6. Vertopal CLI

- **URL**: https://github.com/vertopal/vertopal-cli
- **무엇을 하는가**: `vertopal convert file.hwp --to pdf` 명령으로 HWP -> PDF 변환. 벌크 변환 지원.
- **설치**: 바이너리 다운로드 또는 pip install
- **무료 여부**: CLI는 무료이나 **Vertopal 공용 API 사용** (클라우드 서버로 파일 전송). 무료 티어 제한 있을 수 있음.
- **PDF 변환**: 직접 지원
- **품질**: 온라인 변환기 수준
- **Linux 서버**: macOS/Windows/Linux 바이너리 제공. 단, 파일이 Vertopal 서버로 전송됨.
- **평가**: 로컬 처리가 아니라 API 호출이므로 보안/대량처리에 부적합

## 7. HWP-MCP (Model Context Protocol)

- **URL**: https://github.com/jkf87/hwp-mcp (152+ stars)
- **무엇을 하는가**: AI 모델(Claude 등)이 한글(HWP) 프로그램을 직접 제어. 문서 생성/편집/PDF 저장 자동화.
- **설치**: npm/pip, HWP 프로그램 + Python 3.7+ 필요
- **무료 여부**: 오픈소스
- **PDF 변환**: HWP 프로그램의 PDF 저장 기능을 자동화하는 방식
- **품질**: 한컴 오피스 엔진 사용이므로 최고 품질
- **Linux 서버**: **불가** (Windows + HWP 프로그램 필수)
- **평가**: AI 에이전트 워크플로우에 적합하지만 Windows+HWP 필수

## 8. neolord0/hwplib + hwpxlib + hwp2hwpx (Java)

- **URL**: https://github.com/neolord0/hwplib / https://github.com/neolord0/hwp2hwpx
- **무엇을 하는가**: Java로 HWP 파일 읽기/쓰기/변환. hwp2hwpx로 HWP->HWPX 변환 가능.
- **설치**: Maven/Gradle 의존성
- **무료 여부**: Apache-2.0
- **PDF 변환**: **직접 PDF 변환 미지원**. HWP->HWPX 변환 후 다른 도구로 PDF 변환 필요.
- **품질**: HWP 파서로서는 높은 완성도
- **Linux 서버**: Java이므로 플랫폼 독립
- **평가**: HWP -> HWPX -> (ONLYOFFICE/LibreOffice) -> PDF 파이프라인의 중간 단계로 활용 가능

## 9. hamonikr/libreoffice-hwp2odt

- **URL**: https://github.com/hamonikr/libreoffice-hwp2odt
- **무엇을 하는가**: H2Orestart를 Debian 패키지로 재패키징하여 apt로 쉽게 설치 가능하게 함
- **설치**: `sudo apt install libreoffice-hwp2odt` (HamonIKR 저장소 추가 후)
- **무료 여부**: GPL-3.0
- **PDF 변환**: LibreOffice headless + 이 확장으로 `libreoffice --headless --convert-to pdf file.hwp`
- **품질**: H2Orestart와 동일
- **Linux 서버**: Ubuntu/Debian 서버에서 apt로 바로 설치 가능
- **평가**: 이미 알려진 LibreOffice+H2Orestart 방식이지만, **apt 패키지로 설치가 매우 간편**

## 10. hanpama/hwp (Go)

- **URL**: https://github.com/hanpama/hwp
- **무엇을 하는가**: Go 언어로 HWP/HWPX 텍스트 추출. `hwpcat` CLI 도구 포함.
- **설치**: `go get github.com/hanpama/hwp`
- **무료 여부**: MIT
- **PDF 변환**: **미지원** (텍스트 추출만)
- **품질**: 텍스트 추출 용도로는 양호
- **Linux 서버**: Go 바이너리이므로 어디서든 실행 가능
- **평가**: PDF 변환은 안되지만 텍스트 추출이 필요한 경우 유용

## 11. Microsoft Hanword HWP Document Converter for Word

- **URL**: https://www.microsoft.com/en-us/download/details.aspx?id=49152
- **무엇을 하는가**: MS Word에서 HWP 파일을 열고 DOCX로 변환. 폴더 단위 벌크 변환도 지원.
- **설치**: MSI 설치 (32-bit/64-bit 별도)
- **무료 여부**: 무료
- **PDF 변환**: HWP -> DOCX -> Word로 PDF 저장 (간접)
- **품질**: Microsoft 공식 도구이므로 DOCX 변환 품질 양호. 단 HWP 5.0만 지원.
- **Linux 서버**: **불가** (Windows + MS Word 필요)
- **평가**: Windows 데스크톱 환경에서 배치 처리 가능

## 12. openhwp/openhwp (Rust)

- **URL**: https://github.com/openhwp/openhwp
- **무엇을 하는가**: Rust로 HWP 5.0/HWPX 읽기/쓰기. 포맷 간 변환(HWP <-> HWPX). 암호화 파일 처리.
- **설치**: Cargo 의존성
- **무료 여부**: MIT
- **PDF 변환**: **미지원**
- **품질**: 파서로서 높은 완성도 (75 stars)
- **Linux 서버**: Rust 바이너리이므로 어디서든 실행 가능
- **평가**: HWP -> HWPX 변환 후 다른 도구로 PDF 생성하는 파이프라인에 활용 가능

## 13. HWPConverter.com

- **URL**: https://hwpconverter.com
- **무엇을 하는가**: 온라인 HWP/HWPX 뷰어 + PDF/Text/Markdown 변환
- **설치**: 웹 서비스 (셀프호스팅 불가)
- **무료 여부**: 무료 (파일 5개, 10MB 제한)
- **PDF 변환**: 직접 지원
- **품질**: 미확인
- **Linux 서버**: 웹 서비스이므로 API가 있다면 가능하나 공식 API 미확인
- **평가**: 온라인 서비스 (이미 알려진 유형에 해당하지만, Markdown 변환이 독특)

## 14. ConvertX (셀프호스팅 변환기)

- **URL**: https://github.com/C4illin/ConvertX (16.3k stars)
- **무엇을 하는가**: 셀프호스팅 파일 변환기. LibreOffice, Pandoc, ImageMagick 등 20+개 도구 통합. 1000+ 포맷 지원.
- **설치**: Docker
- **무료 여부**: AGPL-3.0
- **PDF 변환**: LibreOffice가 내장되어 있으므로 HWP 확장 설치 시 HWP -> PDF 가능할 수 있음
- **품질**: 내부 LibreOffice 엔진 품질에 의존
- **Linux 서버**: Docker로 운영 가능
- **평가**: 직접 HWP를 지원하진 않지만, LibreOffice+H2Orestart를 내부에 설치하면 통합 변환 UI를 제공할 수 있음

## 15. NomaDamas/hwp-converter-api (Java/Kotlin)

- **URL**: https://github.com/NomaDamas/hwp-converter-api
- **무엇을 하는가**: hwplib 기반 HWP -> 텍스트 변환 API 서버
- **설치**: `docker run -p 7000:7000 vkehfdl1/hwp-converter-api:1.0.0`
- **무료 여부**: Apache-2.0
- **PDF 변환**: **미지원** (텍스트 변환만)
- **품질**: 텍스트 추출로는 양호
- **Linux 서버**: Docker로 운영 가능
- **평가**: PDF 변환은 안되지만 텍스트 추출 API가 필요한 경우 유용

---

## 요약: 실제로 "새로운" HWP -> PDF 직접 변환이 가능한 도구

| 도구 | 무료 | Linux 서버 | 직접 PDF | 품질 | 비고 |
|------|------|-----------|---------|------|------|
| **PyMuPDF Pro** | 유료 | O | O | 높음 | 3페이지 트라이얼만 무료 |
| **hwpparser** | O (AGPL 주의) | O (Chromium 필요) | O | 중간 | pyhwp+Chrome 기반 |
| **ONLYOFFICE** | O (AGPL) | O (Docker) | X (간접) | 중간 | HWP->DOCX->PDF 우회 |
| **jacepark12/hwp-converter-api** | O | O (Docker) | O | 중간 | LibreOffice 래핑 |
| **Polaris Office** | O | X | O | 높음 | 모바일/Windows만 |
| **Vertopal CLI** | 조건부 무료 | O | O | 중간 | 클라우드 API 의존 |
| **HWP-MCP** | O | X (Windows) | O | 최고 | HWP 프로그램 필요 |
| **hamonikr/hwp2odt** | O | O (apt) | O (간접) | 중간 | LibreOffice 방식 apt 패키징 |

### 핵심 결론
2025-2026년에도 HWP -> PDF **직접** 무료 변환은 여전히 매우 제한적. 진정으로 "새로운" 접근법은:

1. **hwpparser** - pyhwp + Chromium 조합의 편리한 래퍼 (2026년 2월 생성)
2. **ONLYOFFICE 8.3+** - HWP 열기 지원 시작, Conversion API에 HWP 추가 예정
3. **PyMuPDF Pro** - 유일한 고품질 상용 솔루션 (유료)
4. **Polaris Office** - 모바일/데스크톱에서 무제한 무료 (서버 불가)
5. **HWP-MCP** - AI 에이전트를 통한 HWP 자동화 (혁신적이지만 Windows+HWP 필요)
