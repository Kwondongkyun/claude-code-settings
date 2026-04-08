---
name: frontend-form
description: 다중 필드 + 검증 + 제출이 필요한 폼을 만들 때 사용. React Hook Form + Zod + shadcn/ui Form. 단일 입력(검색, 필터)에는 불필요. 로그인, 회원가입, 설정 등 본격적인 폼에 적용.
effort: medium
allowed-tools: Read, Write, Edit, Glob, Grep
---

# 폼 작성 규칙

React Hook Form + Zod + shadcn/ui Form 조합을 기본으로 사용한다.

## 필수 라이브러리

```typescript
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
```

## 스키마 파일 위치

스키마는 도메인 단위로 `features/[domain]/schemas.ts`에 모아서 관리한다.

```
features/
├── auth/
│   ├── api.ts
│   ├── types.ts
│   ├── schemas.ts      # 도메인 내 모든 폼 스키마
│   └── hooks.ts
│
├── feed/
│   ├── articles/
│   │   ├── api.ts
│   │   ├── types.ts
│   │   └── schemas.ts  # 서브 도메인도 각각 관리
│   └── sources/
│       ├── api.ts
│       └── types.ts
```

## Zod 스키마 작성

### 기본 패턴

```typescript
// features/auth/schemas.ts
import { z } from 'zod';

export const loginSchema = z.object({
  email: z.string().min(1, '이메일을 입력해주세요').email('올바른 이메일 형식이 아닙니다'),
  password: z.string().min(8, '비밀번호는 8자 이상이어야 합니다'),
});

export const signupSchema = z.object({
  email: z.string().min(1, '이메일을 입력해주세요').email('올바른 이메일 형식이 아닙니다'),
  password: z.string().min(8, '비밀번호는 8자 이상이어야 합니다'),
  confirmPassword: z.string(),
}).refine((data) => data.password === data.confirmPassword, {
  message: '비밀번호가 일치하지 않습니다',
  path: ['confirmPassword'],
});

// 스키마에서 타입 추출 (별도 interface 정의 금지)
export type LoginFormValues = z.infer<typeof loginSchema>;
export type SignupFormValues = z.infer<typeof signupSchema>;
```

### 자주 쓰는 Zod 검증

```typescript
// 필수 문자열
z.string().min(1, '필수 항목입니다')

// 이메일
z.string().email('올바른 이메일 형식이 아닙니다')

// 숫자 범위
z.number().min(0).max(100)

// 문자열 → 숫자 변환 (input은 문자열로 받으므로)
z.string().transform(Number).pipe(z.number().min(1))

// 선택 항목
z.enum(['admin', 'user', 'guest'])

// 선택적 필드
z.string().optional()
z.string().nullable()
```

## 기본 폼 구조

```typescript
// components/auth/LoginForm/index.tsx
'use client';

import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import {
  Form,
  FormControl,
  FormField,
  FormItem,
  FormLabel,
  FormMessage,
} from '@/components/ui/form';
import { loginSchema, type LoginFormValues } from '@/features/auth/schemas';

export function LoginForm() {
  const form = useForm<LoginFormValues>({
    resolver: zodResolver(loginSchema),
    defaultValues: {
      email: '',
      password: '',
    },
  });

  const handleSubmit = form.handleSubmit(async (values) => {
    await loginApi(values);
  });

  return (
    <Form {...form}>
      <form onSubmit={handleSubmit} className="flex flex-col gap-4">
        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>이메일</FormLabel>
              <FormControl>
                <Input placeholder="example@email.com" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <FormField
          control={form.control}
          name="password"
          render={({ field }) => (
            <FormItem>
              <FormLabel>비밀번호</FormLabel>
              <FormControl>
                <Input type="password" {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />

        <Button type="submit" disabled={form.formState.isSubmitting}>
          {form.formState.isSubmitting ? '로그인 중...' : '로그인'}
        </Button>
      </form>
    </Form>
  );
}
```

## Submit 핸들링

```typescript
// ✅ form.handleSubmit으로 래핑
const handleSubmit = form.handleSubmit(async (values) => {
  await someApi(values);
});

// ❌ Bad: e.preventDefault() 직접 작성
const handleSubmit = async (e: React.FormEvent) => {
  e.preventDefault();
};
```

### 로딩 상태

```typescript
// ✅ isSubmitting 사용 (별도 useState 금지)
<Button type="submit" disabled={form.formState.isSubmitting}>
  {form.formState.isSubmitting ? '저장 중...' : '저장'}
</Button>

// ❌ Bad
const [isLoading, setIsLoading] = useState(false);
```

## 에러 처리

### 필드 에러 (Zod 자동 처리)

```typescript
// FormMessage가 자동으로 표시 — 별도 구현 불필요
<FormMessage />
```

### 서버 에러 처리

```typescript
const handleSubmit = form.handleSubmit(async (values) => {
  try {
    await loginApi(values);
  } catch (error) {
    // 특정 필드 에러
    form.setError('email', {
      message: '이미 사용 중인 이메일입니다',
    });

    // 폼 전체 에러
    form.setError('root', {
      message: '로그인에 실패했습니다. 다시 시도해주세요',
    });
  }
});

// 루트 에러 표시
{form.formState.errors.root && (
  <p className="text-sm text-destructive">
    {form.formState.errors.root.message}
  </p>
)}
```

## 복합 필드 & 수정 폼

Select, Checkbox, Radio 등 복합 필드 패턴과 기존 데이터 편집(수정 폼) 패턴은 `references/field-patterns.md`를 참고.

## 금지 사항

```typescript
// ❌ 스키마와 별도로 interface 정의
interface LoginFormValues { ... }  // z.infer<typeof schema> 사용할 것

// ❌ register() 직접 사용
<Input {...form.register('email')} />  // FormField + FormControl 사용할 것

// ❌ 로딩 상태 별도 state 관리
const [isLoading, setIsLoading] = useState(false);  // form.formState.isSubmitting 사용할 것

// ❌ e.preventDefault() 직접 작성
const onSubmit = (e) => { e.preventDefault(); }  // form.handleSubmit() 사용할 것
```
