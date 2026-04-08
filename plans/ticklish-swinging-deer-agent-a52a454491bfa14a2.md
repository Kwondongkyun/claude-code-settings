# HWP to PDF 변환 대안 조사 결과

> LibreOffice + H2Orestart 제외, Linux 서버에서 사용 가능한 옵션 중심

---

## A. 실사용 가능 (HWP 지원 확인됨)

### 1. ONLYOFFICE Docs 8.3+ (Conversion API)
- **URL**: https://www.onlyoffice.com/blog/2025/02/onlyoffice-docs-8-3-released
- **HWP 지원**: **확인됨** - Docs 8.3 (2025.02)부터 HWP/HWPX 공식 지원
- **사용법**: Docker로 self-hosted 배포 후 Conversion API (REST) 호출
  ```
  docker run -d -p 80:80 --restart=always -e JWT_SECRET=secret onlyoffice/documentserver
  POST https://documentserver/converter
  ```
- **비용**: Community Edition 무료 (self-hosted)
- **Linux 서버**: Docker 기반으로 완전 호환
- **품질**: HWP 열기/뷰어 수준. 편집 시 OOXML로 자동 변환. "full formatting compliance is not guaranteed" 공식 경고. 복잡한 서식은 깨질 수 있음
- **평가**: **가장 유망한 대안**. 무료 self-hosted + REST API. 다만 변환 품질은 직접 테스트 필요

### 2. CloudConvert API
- **URL**: https://cloudconvert.com/hwp-to-pdf
- **HWP 지원**: **확인됨** - HWP/HWPX -> PDF 직접 지원
- **사용법**: REST API 호출. S3/Azure/GCS 통합 지원
  ```
  POST https://api.cloudconvert.com/v2/jobs
  ```
- **비용**: 무료 10건/일, 이후 크레딧 기반 과금 (1크레딧/분 변환시간). Sandbox API는 무제한 (테스트용)
- **Linux 서버**: 클라우드 SaaS API이므로 서버 환경 무관
- **품질**: 전문 변환 서비스로 비교적 높은 품질 기대
- **평가**: **안정적인 유료 옵션**. 대량 변환 시 비용 발생하지만 품질/안정성 보장

### 3. Vertopal CLI
- **URL**: https://www.vertopal.com/en/convert/hwp-to-pdf / https://github.com/vertopal/vertopal-cli
- **HWP 지원**: **확인됨** - HWP -> PDF 변환 지원
- **사용법**: CLI 도구 설치 후 명령어 실행
  ```
  curl https://run.vertopal.com/cli/linux | bash
  vertopal convert input.hwp --to pdf
  ```
- **비용**: 무료 vCredits 일일 지급. 기본 무료 토큰으로 개인 테스트 가능. 프로덕션은 유료
- **Linux 서버**: Linux 완전 지원
- **품질**: 클라우드 기반 변환으로 중간~높음 예상
- **평가**: CLI 있어 자동화 편리. 다만 실제로는 클라우드 API 호출이므로 네트워크 필요

### 4. Polaris Office Web HWP API (RapidAPI)
- **URL**: https://rapidapi.com/polarisapis-polarisofficeapis/api/polaris-office-web-hwp
- **HWP 지원**: **확인됨** - HWP/HWPX 네이티브 지원 (한컴 대안 1위 오피스)
- **사용법**: RapidAPI를 통한 REST API 호출
- **비용**: RapidAPI 요금제 따름 (상세 미확인)
- **Linux 서버**: REST API이므로 서버 환경 무관
- **품질**: Polaris Office 엔진 기반으로 높은 품질 기대
- **평가**: HWP 전문 업체의 API. 가격 정보 추가 확인 필요

### 5. Polaris Share PDF (무료 웹 변환)
- **URL**: https://hub.polarishare.com/en/pdf
- **HWP 지원**: **확인됨** - HWP, HWPX 지원
- **사용법**: 웹 업로드 (API는 없음)
- **비용**: 무료
- **Linux 서버**: 웹 서비스만 (API 없음, 스크래핑 필요)
- **품질**: Polaris Office 엔진 기반으로 높음
- **평가**: 수동 변환에만 적합. 자동화 어려움

### 6. HWPConverter.com
- **URL**: https://hwpconverter.com/en
- **HWP 지원**: **확인됨** - HWP/HWPX -> PDF, Text, Markdown 지원
- **사용법**: 웹 업로드. **API 준비 중** (아직 미출시)
- **비용**: 무료 (10MB 이하, 5파일 동시)
- **Linux 서버**: 현재 웹만. API 출시 대기
- **품질**: "pixel-perfect accuracy" 표방
- **평가**: API 나오면 유망. 현재는 수동 전용

### 7. AllInPDF.com
- **URL**: https://allinpdf.com/hwp-to-pdf
- **HWP 지원**: **확인됨** - 한국 서비스, HWP -> PDF 지원
- **사용법**: 웹 업로드
- **비용**: 무료
- **Linux 서버**: 웹만 (API 미확인)
- **품질**: 한국 서비스로 HWP 호환성 높을 것으로 기대
- **평가**: API 없이 자동화 어려움

---

## B. 오픈소스 라이브러리/도구 (직접 구축)

### 8. pyhwp (Python)
- **URL**: https://github.com/mete0r/pyhwp / https://pypi.org/project/pyhwp/
- **HWP 지원**: **확인됨** - HWP v5 파서
- **사용법**: `pip install pyhwp` -> hwp5odt (ODT 변환) -> LibreOffice로 PDF 변환
  ```
  hwp5odt input.hwp -o output.odt
  libreoffice --headless --convert-to pdf output.odt
  ```
- **비용**: 무료 오픈소스
- **Linux 서버**: 완전 호환
- **품질**: 실험적(experimental). 복잡한 서식 깨질 가능성 높음
- **평가**: HWP -> ODT -> PDF 2단계 변환. 품질 손실 불가피. Python 2.7~3.8 지원 (최신 Python 미지원 가능성)

### 9. hwp2pdf (simnalamburt) - Naver Whale 기반
- **URL**: https://github.com/simnalamburt/hwp2pdf
- **HWP 지원**: **확인됨** - Naver Whale의 HWP 변환기 활용
- **사용법**: Naver Whale 브라우저 내장 변환기 호출
- **비용**: 무료 오픈소스 (AGPL-3.0)
- **Linux 서버**: Naver Whale이 Linux 지원하는지 미확인. **비유지 상태(unmaintained)**
- **품질**: Naver Whale 엔진 기반이면 높을 수 있으나 미유지
- **평가**: 비유지 프로젝트. 프로덕션 사용 비권장

### 10. hwp2pdf (atsusta) - pyhwp + tinyXML2
- **URL**: https://github.com/atsusta/hwp2pdf
- **HWP 지원**: **확인됨**
- **사용법**: pyhwp + tinyXML2 조합 콘솔 앱
- **비용**: 무료 오픈소스
- **Linux 서버**: 호환 가능
- **품질**: pyhwp 기반이므로 제한적
- **평가**: pyhwp와 동일한 한계

### 11. hwpers (Rust)
- **URL**: https://github.com/Indosaram/hwpers / https://crates.io/crates/hwpers
- **HWP 지원**: **확인됨** - HWP 5.0 파서 + 레이아웃 렌더링
- **사용법**: Rust 라이브러리. SVG 출력 지원. SVG -> PDF 변환 파이프라인 구축 가능
- **비용**: 무료 오픈소스
- **Linux 서버**: Rust이므로 완전 호환
- **품질**: "pixel-perfect" 레이아웃 렌더링 (레이아웃 데이터 있을 때). SVG 출력은 높은 품질
- **평가**: **가장 유망한 오픈소스**. SVG -> PDF(resvg 등) 파이프라인으로 고품질 변환 가능성. 다만 직접 통합 개발 필요

### 12. unhwp (Rust)
- **URL**: https://github.com/iyulab/unhwp / https://crates.io/crates/unhwp
- **HWP 지원**: **확인됨** - HWP 5.0 + HWPX 파서
- **사용법**: `cargo install unhwp-cli && unhwp document.hwp`
- **비용**: 무료 오픈소스
- **Linux 서버**: 완전 호환
- **품질**: Markdown/Text/JSON 추출. **레이아웃/서식은 보존하지 않음** (텍스트 추출 용도)
- **평가**: PDF 변환이 아닌 텍스트 추출 용도. PDF가 목적이면 부적합

### 13. openhwp (Rust)
- **URL**: https://github.com/openhwp/openhwp
- **HWP 지원**: **확인됨** - HWP 읽기/쓰기
- **사용법**: Rust 라이브러리
- **비용**: 무료 오픈소스
- **Linux 서버**: 완전 호환
- **품질**: 읽기/쓰기 라이브러리. PDF 출력 기능은 미확인
- **평가**: 파서 수준. PDF 변환 직접 구현 필요

### 14. hwp-rs (hahnlee)
- **URL**: https://github.com/hahnlee/hwp-rs
- **HWP 지원**: **확인됨** - 저수준 HWP 파서 + libhwp(Python 바인딩)
- **사용법**: Rust 라이브러리 또는 Python 바인딩
- **비용**: 무료 오픈소스
- **Linux 서버**: 완전 호환
- **품질**: 파서 수준
- **평가**: 파서만 제공. PDF 렌더링은 별도 구현 필요

---

## C. HWP 미지원 확인됨

### 15. WPS Office
- **URL**: https://www.wps.com/office/linux/
- **HWP 지원**: **미확인/미지원 추정** - 공식 문서에 HWP 언급 없음
- **Linux 서버**: Linux 버전 있으나 GUI 필요
- **평가**: HWP 미지원으로 보임

### 16. FreeOffice (SoftMaker)
- **URL**: https://www.freeoffice.com
- **HWP 지원**: **미지원** - 검색 결과에 HWP 언급 전무
- **평가**: 부적합

### 17. Collabora Online (LibreOffice 기반)
- **URL**: https://www.collaboraonline.com/
- **HWP 지원**: **미확인** - LibreOffice 기반이므로 LibreOffice 수준의 HWP 지원 가능성. 공식 문서에 HWP 미언급
- **사용법**: REST API (`curl -F "data=@file" https://server/cool/convert-to/pdf`)
- **비용**: 유료 (Enterprise), 개발자 에디션 무료
- **평가**: LibreOffice와 동일한 엔진이므로 이미 알고 있는 옵션의 변형

### 18. Gotenberg
- **URL**: https://gotenberg.dev/
- **HWP 지원**: **미확인/미지원 추정** - LibreOffice 백엔드 사용. HWP 명시적 미언급
- **평가**: LibreOffice 래퍼이므로 LibreOffice와 동일한 한계

### 19. Stirling PDF
- **URL**: https://stirlingpdf.io/
- **HWP 지원**: **미확인/미지원 추정** - 50+ 포맷 지원하나 HWP 명시적 미언급
- **평가**: PDF 편집/변환 도구이나 HWP는 입력 포맷으로 미지원 추정

### 20. Google Docs API / Drive API
- **URL**: https://developers.google.com/docs
- **HWP 지원**: **미지원** - HWP 업로드/변환 미지원
- **평가**: 부적합

### 21. Microsoft Graph API
- **URL**: https://learn.microsoft.com/graph
- **HWP 지원**: **미지원** - 지원 포맷에 HWP 없음 (doc, docx, odt, rtf 등만)
- **평가**: 부적합

### 22. Amazon Textract
- **URL**: https://aws.amazon.com/textract/
- **HWP 지원**: **미지원** - PNG/JPEG/TIFF/PDF만 지원. 한국어도 미지원
- **평가**: 완전 부적합

### 23. Aspose
- **URL**: https://www.aspose.com/
- **HWP 지원**: **미지원** - HWP 변환 API 없음
- **평가**: 부적합

### 24. Calibre
- **URL**: https://calibre-ebook.com/
- **HWP 지원**: **미지원** - eBook 포맷만 (EPUB, MOBI 등)
- **평가**: 완전 부적합

### 25. ConvertAPI
- **URL**: https://www.convertapi.com/
- **HWP 지원**: **미확인** - 300+ 포맷 지원 주장하나 HWP 명시적 미언급
- **평가**: 확인 필요

---

## D. 추천 순위 (Linux 서버 자동화 기준)

| 순위 | 도구 | 유형 | 비용 | 품질 (예상) | 자동화 난이도 |
|------|------|------|------|-------------|--------------|
| 1 | **ONLYOFFICE Docs 8.3** | Self-hosted Docker + REST API | 무료 | 중~상 | 낮음 |
| 2 | **CloudConvert API** | 클라우드 SaaS API | 유료 (10건/일 무료) | 상 | 낮음 |
| 3 | **Vertopal CLI** | 클라우드 CLI | 제한적 무료 | 중~상 | 낮음 |
| 4 | **Polaris Web HWP API** | 클라우드 API (RapidAPI) | 유료 | 상 | 낮음 |
| 5 | **hwpers (Rust) + SVG->PDF** | 오픈소스 라이브러리 | 무료 | 상 (이론적) | 높음 |
| 6 | **pyhwp + LibreOffice** | 오픈소스 파이프라인 | 무료 | 하~중 | 중간 |
| 7 | **HWPConverter.com** | 웹 서비스 (API 준비중) | 무료 | 상 | API 대기 중 |
