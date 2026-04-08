# AI CMO 분석 기반 홈페이지 개선

## Context
okara.ai AI CMO가 nxtcloud.kr을 분석한 결과:
- SEO 100점, Best Practices 100점 (이미 우수)
- **Critical 1건** + **Warning 11건** + **Info 5건**
- Core Web Vitals: LCP 16초(심각), FCP 2초, TBT 165ms, CLS 0
- AI/GEO Readiness: 60점 (6/10)

이미 적용된 것: sitemap.xml ✓, robots.txt ✓, OG tags ✓, canonical ✓, hreflang ✓
**→ 남은 이슈들을 코드 수정으로 해결**

---

## P0 — Critical + 빠른 수정

### 1. `<html lang>` 속성 추가
- **파일**: `src/app/layout.tsx`, `src/app/[locale]/layout.tsx`
- **문제**: `<html suppressHydrationWarning>` — lang 속성 없음
- **수정**: root layout에서 `<html>`/`<body>` 제거 → `[locale]/layout.tsx`에서 `<html lang={locale}>` 렌더링
  - root layout은 children만 pass-through
  - locale layout에서 폰트, GA 스크립트, html/body 모두 관리

### 2. Hero 이미지 alt text 추가
- **파일**: `src/components/sections/HeroSection.tsx:46`
- **문제**: `alt=""` → AI CMO Critical 이슈
- **수정**: 슬라이드별 설명적 alt text 추가 (번역 키 활용)

### 3. Meta description 길이 조정
- **파일**: `messages/ko.json`, `messages/en.json`
- **문제**: home description이 okara 기준 179자 (권장 155자 이하)
- **수정**: 핵심 키워드 유지하면서 155자 이내로 축약

### 4. Security headers 추가
- **파일**: `next.config.ts`
- **문제**: 보안 헤더 전무
- **수정**: `headers()` async 함수 추가
  ```
  X-Content-Type-Options: nosniff
  X-Frame-Options: SAMEORIGIN
  Referrer-Policy: strict-origin-when-cross-origin
  Strict-Transport-Security: max-age=63072000; includeSubDomains; preload
  Permissions-Policy: camera=(), microphone=(), geolocation=()
  ```

### 5. llms.txt 생성
- **파일**: `public/llms.txt` (신규)
- **내용**: NXTCLOUD 소개, 서비스 설명, 주요 페이지 URL 목록

### 6. Next.js 이미지 최적화 설정
- **파일**: `next.config.ts`
- **수정**: `formats: ['image/avif', 'image/webp']` 추가
- 효과: 브라우저 지원 시 자동으로 AVIF/WebP 변환 제공

---

## P1 — LCP 성능 개선

### 7. Hero 이미지 로컬화
- **문제**: Unsplash 외부 URL → DNS/TLS 오버헤드로 LCP 16초의 주범
- **수정**: 3장 이미지를 `public/img/hero/`에 로컬 다운로드 후 경로 변경
- **파일**: `src/components/sections/HeroSection.tsx`
- **효과**: LCP 3-5초 단축 예상

---

## 수정 파일 목록

| 파일 | 변경 내용 |
|------|-----------|
| `src/app/layout.tsx` | html/body 제거, children pass-through만 |
| `src/app/[locale]/layout.tsx` | `<html lang={locale}>`, `<body>`, 폰트, GA 이동 |
| `src/components/sections/HeroSection.tsx` | alt text 추가, 이미지 로컬 경로 변경 |
| `next.config.ts` | security headers, image formats 추가 |
| `messages/ko.json` | home description 155자 이내로 축약 |
| `messages/en.json` | home description 155자 이내로 축약 |
| `public/llms.txt` | 신규 생성 |
| `public/img/hero/*.jpg` | Unsplash 이미지 3장 로컬 저장 |

---

## 검증
1. `npm run build` 성공
2. 브라우저 Elements에서 `<html lang="ko">` 확인
3. Response Headers에서 보안 헤더 확인 (`curl -I`)
4. `/llms.txt` 접근 확인
5. Lighthouse 재측정 → LCP 개선 확인
