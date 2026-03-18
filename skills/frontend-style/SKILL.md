---
name: frontend-style
description: Use when styling components or writing CSS. Enforces TailwindCSS with cn() utility, proper environment variables usage. Prohibits emojis, any types, inline styles, and console.log.
allowed-tools: Read, Edit, Glob, Grep
---

# 스타일 & 금지사항

## TailwindCSS 사용

### cn() 유틸 활용 (필수)

```typescript
import { cn } from '@/lib/utils';

<div
  className={cn(
    "flex items-center gap-2",
    isActive && "bg-primary",
    isDisabled && "opacity-50 pointer-events-none"
  )}
/>
```

### 축약 클래스 사용

```typescript
// ✅ Good: 축약형
<div className="shrink-0" />
<div className="grow" />

// ❌ Bad: 비축약형
<div className="flex-shrink-0" />
<div className="flex-grow" />
```

### bg 그라데이션 사용 금지

```typescript
// ❌ Bad
<div className="bg-gradient-to-r from-blue-500 to-purple-500" />
<div className="bg-linear-to-r" />
```

## 텍스트 태그 규칙

### Heading 태그 규칙

시맨틱 HTML 태그(`<h1>` ~ `<h6>`)를 사용하되, TailwindCSS 클래스로 스타일링한다.
접근성(스크린 리더)과 SEO를 위해 문서 계층 구조를 유지한다.

```typescript
// ✅ Good: 시맨틱 태그 + TailwindCSS
<h1 className="text-3xl font-bold">페이지 제목</h1>
<h2 className="text-2xl font-semibold">섹션 제목</h2>
<p className="text-base">본문 텍스트</p>

// ❌ Bad: 제목에 p 태그 사용
<p className="text-3xl font-bold">페이지 제목</p>
```

### 텍스트 크기 매핑표

| 태그                                      | 스타일      | 설명         |
| ----------------------------------------- | ----------- | ------------ |
| `<h1 className="text-3xl font-bold">`     | 최상위 제목 | 페이지당 1개 |
| `<h2 className="text-2xl font-semibold">` | 주요 섹션   |              |
| `<h3 className="text-xl font-medium">`    | 하위 섹션   |              |
| `<h4 className="text-lg font-medium">`    | 소제목      |              |
| `<p className="text-base">`               | 본문 텍스트 |              |

규칙:

- 페이지당 `<h1>`은 1개만
- 계층 순서 유지 (h1 → h2 → h3, h1 → h3 건너뛰기 금지)
- 스타일만 변경하고 싶으면 heading이 아닌 `<p>` + TailwindCSS 사용

### 반응형 디자인

```typescript
// 모바일 우선 (mobile-first)
<div className="
  text-sm          // 기본 (모바일)
  md:text-base     // 태블릿
  lg:text-lg       // 데스크톱
" />

// 브레이크포인트: sm, md, lg, xl, 2xl
```

## 환경변수 규칙

### NEXT*PUBLIC* 접두사

```bash
# .env.local

# 클라이언트 접근 가능 (공개되어도 괜찮은 것)
NEXT_PUBLIC_API_URL=https://api.example.com
NEXT_PUBLIC_GOOGLE_ANALYTICS_ID=G-XXXXXXXXXX

# 서버만 접근 가능 (비밀 유지 필수)
DATABASE_URL=postgresql://user:password@localhost:5432/db
ADMIN_API_KEY=admin-secret-key-12345
```

| 구분 | NEXT*PUBLIC* 있음   | NEXT*PUBLIC* 없음   |
| ---- | ------------------- | ------------------- |
| 접근 | 클라이언트 + 서버   | 서버만              |
| 노출 | 브라우저에서 보임   | 숨겨짐              |
| 용도 | 공개 API URL, GA ID | DB 비밀번호, API 키 |

### 위험한 사용 (절대 금지)

```bash
❌ NEXT_PUBLIC_DATABASE_URL=postgresql://...
❌ NEXT_PUBLIC_SECRET_KEY=abc123
❌ NEXT_PUBLIC_ADMIN_PASSWORD=1234
```

## 금지 사항

### 1. 이모지 사용 절대 금지

```typescript
❌ const message = "완료되었습니다 ✅";
❌ <Button>저장 💾</Button>

✅ const message = "완료되었습니다";
✅ <Button>저장</Button>

// 아이콘 필요시 lucide-react 사용
import { Check, Save } from 'lucide-react';
<Button><Save className="w-4 h-4" />저장</Button>
```

### 2. 인라인 스타일 금지

```typescript
❌ <div style={{ color: 'red' }} />
✅ <div className="text-red-500" />
```

### 3. any 타입 사용 금지

```typescript
❌ const data: any = ...
✅ const data: UserData = ...

❌ function handleData(data: any) { ... }
✅ function handleData(data: UserData) { ... }
```

### 4. console.log 프로덕션 코드에 남기기 금지

```typescript
❌ console.log('debug');
✅ // 개발 중에만 사용, 커밋 전 제거
```

### 5. 단일 파일 컴포넌트 생성 금지

```typescript
❌ components/AdminTable.tsx
✅ components/admin/accounts/AdminTable/index.tsx
```

## 주석 스타일

```typescript
/**
 * 사용자 정보를 조회하는 API
 *
 * @param userId - 조회할 사용자 ID
 * @param accessToken - 인증 토큰 (선택)
 * @returns 사용자 데이터
 */
export async function getUserApi(
  userId: string,
  accessToken?: string,
): Promise<UserData> {
  // API 요청 로직
}
```

