---
name: frontend-naming
description: 파일, 변수, 함수, 타입 네이밍 시 사용. 컴포넌트 PascalCase, 함수 camelCase, 상수 UPPER_SNAKE_CASE, 파일 kebab-case.
effort: low
allowed-tools: Read, Glob, Grep
---

# 네이밍 컨벤션

## 파일명

### 페이지 컴포넌트
```
폴더명으로 기능 구분, 파일명은 모두 page.tsx
✅ app/(main)/admin/accounts/page.tsx
✅ app/(auth)/login/page.tsx
```

### 컴포넌트 (디렉토리/index.tsx 패턴 필수)
```
✅ components/admin/accounts/AdminTable/index.tsx
✅ components/ui/Button/index.tsx

❌ components/admin-table.tsx (단일 파일 금지)
❌ components/AdminTable.tsx (단일 파일 금지)
❌ components/AdminTable/AdminTable.tsx (중복 금지)
```

### API & Hooks & 기타 유틸리티 파일
```
kebab-case 사용 (Shadcn UI 컨벤션 따름)
✅ api.ts
✅ types.ts
✅ hooks.ts
✅ constants.ts
✅ use-mobile.ts
❌ API.ts
❌ useMobile.ts
```

### Context 파일
```
PascalCase 사용 (React 컨벤션)
✅ AuthContext.tsx
✅ ThemeContext.tsx
```

## 변수명 & 함수명

### 컴포넌트 (PascalCase)
```typescript
export function PageHeader() { ... }
export function DialogStack() { ... }
```

### 함수 & 변수 (camelCase)
```typescript
const handleSubmit = () => { ... }
const isLoading = false
const userData = { ... }
```

### 상수 (UPPER_SNAKE_CASE)
```typescript
const BASE_URL = "https://api.example.com";
const DEFAULT_TIMEOUT = 10000;
const MAX_RETRY_COUNT = 3;
```

### 타입 & 인터페이스 (PascalCase)
```typescript
interface UserData { ... }
type ApiResponse = { ... }
type StreamEvent = StatusEvent | TokenEvent
```

## API 함수 네이밍 패턴
```typescript
// 패턴: [동사][명사]Api
export async function getMeApi() { ... }
export async function listThreadsApi() { ... }
export async function createUserApi() { ... }
export async function deleteThreadApi() { ... }
```

## Import 규칙
```typescript
// ✅ 디렉토리명으로 import
import { AdminTable } from '@/components/admin/accounts/AdminTable';

// ❌ index까지 명시 금지
import { AdminTable } from '@/components/admin/accounts/AdminTable/index';
```
