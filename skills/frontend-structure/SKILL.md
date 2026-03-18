---
name: frontend-structure
description: Use when setting up or organizing Next.js App Router projects. Defines folder structure for app (pages), components (UI), features (domain modules), lib (utils), and hooks.
allowed-tools: Read, Glob, Bash(mkdir *)
---

# 프로젝트 구조

## 기본 구조
```
src/
├── app/                    # Next.js App Router 페이지
│   ├── page.tsx           # 메인 홈
│   ├── layout.tsx         # 루트 레이아웃
│   ├── (main)/            # 메인 레이아웃 그룹
│   │   └── [feature]/     # 기능별 페이지
│   │       └── page.tsx
│   └── (auth)/            # 인증 레이아웃 그룹
│
├── components/            # 공통 컴포넌트
│   ├── ui/               # Shadcn/Radix 기본 컴포넌트
│   └── [domain]/         # 도메인별 컴포넌트
│       └── [Component]/  # 디렉토리/index.tsx 패턴
│           └── index.tsx
│
├── features/             # 도메인 모듈 (API + 관련 로직)
│   ├── [domain]/
│   │   └── [feature]/
│   │       ├── api.ts   # API 함수
│   │       └── types.ts # 요청/응답 타입
│   └── shared/
│       └── response.ts  # 공통 응답 타입
│
├── lib/                  # 유틸리티 & 핵심 설정
│   ├── api/
│   │   └── axios.ts     # Axios 인스턴스
│   └── utils.ts         # cn() 등
│
└── hooks/                # 전역 공통 훅
    └── use-mobile.ts
```

## Features 폴더 규칙

**features는 도메인별 로직을 포함하는 모듈 단위**
- ✅ api.ts - API 함수
- ✅ types.ts - 요청/응답 타입
- ✅ schemas.ts - Zod 폼 스키마 + 추출 타입
- ✅ hooks.ts - 도메인 전용 훅 (useAuth 등)
- ✅ Context.tsx - 도메인 전용 Context (AuthContext 등)
- ✅ constants.ts - 도메인 전용 상수
- ❌ 컴포넌트 (components 폴더로)

**hooks/ 폴더**: UI 관련 전역 공통 훅만 (use-mobile 등)

## Features 계층 구조 예시
```
features/
├── auth/
│   ├── api.ts             # API 함수
│   ├── types.ts           # 타입
│   ├── schemas.ts         # Zod 폼 스키마
│   ├── AuthContext.tsx     # Context + Provider
│   └── hooks.ts           # useAuth 등
│
├── feed/
│   ├── articles/
│   │   ├── api.ts
│   │   └── types.ts
│   ├── sources/
│   │   ├── api.ts
│   │   └── types.ts
│   └── categories/
│       └── constants.ts   # 카테고리 상수
│
└── shared/
    └── response.ts        # BaseResponse 등
```

## 컴포넌트와 API 연결
```
페이지: app/(main)/admin/accounts/page.tsx
    ↓ 사용
컴포넌트: components/admin/accounts/AdminTable/index.tsx
    ↓ 호출
API: features/admin/accounts/api.ts
```
