# 평가 기반 홈페이지 개선 (60점 → 목표 80점+)

## Context
홈페이지 종합 평가에서 60/100점을 받았다. 상위 4개 이슈를 수정하여 전환율과 완성도를 높인다.
(이슈 #5 "교육 상세 정보"는 콘텐츠 확보 후 별도 진행)

---

## 1. [P0] 서버-클라이언트 폼 스키마 불일치 수정

**문제**: ContactForm이 `inquiryType`(필수), `budget`(선택)을 수집하지만 API route에서 무시됨 → 데이터 유실
**영향**: 문의 이메일에 문의 유형/예산 정보가 빠져 영업 대응 품질 저하

### 수정 파일
- `src/app/api/contact/route.ts`

### 변경 내용
```ts
// Before (line 5-10)
const contactSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  company: z.string().optional(),
  message: z.string().min(10),
})

// After
const contactSchema = z.object({
  name: z.string().min(2),
  email: z.string().email(),
  company: z.string().min(1),    // 클라이언트와 일치 (필수)
  inquiryType: z.string().min(1), // 추가
  budget: z.string().optional(),   // 추가
  message: z.string().min(10),
})
```

이메일 본문에 문의 유형/예산 포함:
```
이름: ${name}
이메일: ${email}
회사: ${company}
문의 유형: ${inquiryType}
예산: ${budget || '미정'}

${message}
```

---

## 2. [P1] CTA 섹션 액션 버튼 추가

**문제**: CTA 섹션에 제목+설명만 있고 버튼이 없음 → 전환 퍼널 끊김
**영향**: 사용자가 관심을 가져도 다음 행동을 할 수 없음

### 수정 파일
- `src/components/sections/CTASection.tsx`
- `messages/ko.json` (CTA 네임스페이스)
- `messages/en.json` (CTA 네임스페이스)

### 변경 내용
CTASection에 두 개 버튼 추가:
- **Primary**: "문의하기" → `/contact` 링크 (bg-nxt-blue, ArrowRight 아이콘)
- **Secondary**: "서비스 살펴보기" → `/services` 링크 (border 스타일)

```tsx
// CTASection.tsx — 버튼 그룹 추가 (description 아래)
<div className="flex flex-col sm:flex-row justify-center gap-4">
  <Link href="/contact" className="inline-flex items-center justify-center gap-2 rounded-xl bg-nxt-blue px-8 py-3.5 font-semibold text-white transition-all hover:bg-nxt-blue/90 hover:shadow-lg hover:-translate-y-0.5">
    {t('contactButton')} <ArrowRight className="h-4 w-4" />
  </Link>
  <Link href="/services" className="inline-flex items-center justify-center rounded-xl border-2 border-slate-200 px-8 py-3.5 font-medium text-slate-700 transition-all hover:border-slate-300 hover:bg-slate-50 hover:-translate-y-0.5">
    {t('servicesButton')}
  </Link>
</div>
```

번역 키 추가:
- ko: `"contactButton": "문의하기"`, `"servicesButton": "서비스 살펴보기"`
- en: `"contactButton": "Contact Us"`, `"servicesButton": "Explore Services"`

---

## 3. [P2] 히어로 카피 구체화 + CTA 버튼 추가

**문제**: "지속가능한 기술로 / 미래 인재를 양성합니다" → 무슨 회사인지 알 수 없음
**영향**: 첫 화면에서 가치 전달 실패 → 이탈률 증가

### 수정 파일
- `messages/ko.json` (Hero 네임스페이스)
- `messages/en.json` (Hero 네임스페이스)
- `src/components/sections/HeroSection.tsx` (CTA 버튼 추가)

### 히어로 카피 (확정: 포지셔닝 강조형)
```
ko: "대학 교육을 위한" / "AWS 클라우드 파트너"
en: "AWS Cloud Partner" / "for University Education"
```

### 히어로 CTA 버튼
서브 텍스트 아래에 버튼 2개 추가:
- **Primary**: "서비스 살펴보기" → `/services`
- **Secondary**: "문의하기" → `/contact`

```tsx
// HeroSection.tsx — subtitle 아래 추가
<motion.div className="flex flex-col sm:flex-row gap-4" ...>
  <Link href="/services" className="inline-flex items-center gap-2 rounded-xl bg-white px-8 py-3.5 font-semibold text-slate-900 transition-all hover:bg-white/90 hover:-translate-y-0.5">
    {t('ctaPrimary')} <ArrowRight className="h-4 w-4" />
  </Link>
  <Link href="/contact" className="inline-flex items-center rounded-xl border-2 border-white/30 px-8 py-3.5 font-medium text-white transition-all hover:bg-white/10 hover:-translate-y-0.5">
    {t('ctaSecondary')}
  </Link>
</motion.div>
```

---

## 4. [P3] 에러 페이지 구현 (404/500)

**문제**: 에러 페이지가 없어 기본 Next.js 에러 화면 노출 → 비전문적 인상
**영향**: UX 완성도 하락, 사용자 이탈 시 복귀 경로 없음

### 신규 파일 4개

#### `src/app/[locale]/not-found.tsx`
- "페이지를 찾을 수 없습니다" 메시지
- "홈으로 돌아가기" 버튼
- 심플한 일러스트/아이콘 (lucide `FileQuestion`)
- `useTranslations('Error')` 사용

#### `src/app/[locale]/error.tsx`
- `'use client'` (필수)
- "문제가 발생했습니다" 메시지
- "다시 시도" 버튼 (`reset()` 호출) + "홈으로" 버튼
- `useTranslations('Error')` 사용

#### `src/app/global-error.tsx`
- `'use client'` (필수)
- 자체 `<html><body>` 포함 (root layout 대체)
- 최소한의 스타일 (Tailwind 사용 불가 → inline style)
- "다시 시도" 버튼

#### `src/app/not-found.tsx`
- root level 404 (locale 밖에서 발생하는 경우)
- `/ko`로 리다이렉트 또는 간단한 안내

### 번역 키 추가 (Error 네임스페이스)
```json
// ko.json
"Error": {
  "notFoundTitle": "페이지를 찾을 수 없습니다",
  "notFoundDescription": "요청하신 페이지가 존재하지 않거나 이동되었습니다.",
  "errorTitle": "문제가 발생했습니다",
  "errorDescription": "일시적인 오류가 발생했습니다. 잠시 후 다시 시도해주세요.",
  "backHome": "홈으로 돌아가기",
  "retry": "다시 시도"
}
```

---

## 검증
1. `npm run build` 성공 확인
2. `/api/contact` POST 테스트 — inquiryType, budget 포함 시 이메일 본문에 표시되는지 확인
3. CTA 섹션에 두 버튼 렌더링 + 링크 동작 확인
4. 히어로 섹션 카피 변경 + CTA 버튼 확인
5. 존재하지 않는 URL 접속 → 커스텀 404 페이지 표시 확인
6. `npm run dev`에서 전체 페이지 한/영 정상 확인
