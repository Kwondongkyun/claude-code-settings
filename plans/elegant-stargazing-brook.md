# Supabase DB 구축 + 홈페이지 데이터 전환 + 백오피스 완성

## Context
nxtcloud-homepage는 현재 100% mock 데이터로 동작 중. nxtcloud-admin 백오피스는 초기 구현 상태(CRUD UI 있으나 대부분 mock). Supabase 프로젝트를 새로 생성하고, 양쪽 프로젝트 모두 실데이터로 전환해야 함.

## 현재 상태

### 이미 있는 것
- **nxtcloud-homepage**: Supabase client/server/storage 구성, 마이그레이션 SQL (`articles`, `metrics`, `inquiries`, `certificates`), RLS 정책, Storage 정책
- **nxtcloud-admin**: 로그인, 대시보드, 기사/영상 CRUD, 지표 관리, 문의 관리, 인증서 CRUD UI 구현. Supabase 쿼리 부분적 구현 (Articles, Certificates)

### 해야 할 것
1. Supabase 프로젝트 생성 & 테이블/RLS/Storage 구축
2. nxtcloud-homepage: mock 데이터 → Supabase 쿼리로 전환
3. nxtcloud-admin: mock 데이터 → 실제 Supabase CRUD로 전환

---

## Step 1: Supabase 프로젝트 생성 (사용자 수동)
- https://supabase.com 에서 새 프로젝트 생성
- Project URL과 anon key 받아서 양쪽 `.env.local`에 설정
- Supabase SQL Editor에서 마이그레이션 실행

### 실행할 SQL
- `nxtcloud-homepage/supabase/migrations/001_initial_schema.sql` — 테이블 생성
- `nxtcloud-homepage/supabase/storage-policies.sql` — Storage 버킷/정책

### 초기 데이터 시딩
- `MOCK_ARTICLES` (20+개) → articles 테이블에 INSERT
- `MOCK_VIDEOS` → articles 테이블에 INSERT (type: 'video')
- `metrics` 초기 데이터 (마이그레이션에 포함)
- BrainCrew 케이스 스터디 → insights 테이블 필요 (신규)

---

## Step 2: DB 스키마 보완
기존 마이그레이션에 없는 테이블 추가 필요:

### insights 테이블 (신규)
```sql
CREATE TABLE insights (
  id TEXT PRIMARY KEY,
  title TEXT NOT NULL,
  title_en TEXT,
  summary TEXT,
  summary_en TEXT,
  content TEXT,
  content_en TEXT,
  author TEXT,
  author_en TEXT,
  category TEXT NOT NULL DEFAULT 'msp',
  published BOOLEAN DEFAULT false,
  published_at TIMESTAMPTZ,
  locales TEXT[] DEFAULT '{en}',
  thumbnail_url TEXT,
  created_at TIMESTAMPTZ DEFAULT now(),
  updated_at TIMESTAMPTZ DEFAULT now()
);
```

### videos 테이블 (또는 articles에 통합)
현재 `articles` 테이블에 `type` 필드로 구분 가능. 하지만 `youtube_id`, `category`(webinar/interview/promotion) 필드 추가 필요:
```sql
ALTER TABLE articles ADD COLUMN youtube_id TEXT;
ALTER TABLE articles ADD COLUMN video_category TEXT;
```

---

## Step 3: nxtcloud-homepage 데이터 전환

### 변경 파일
- `src/lib/mock-data-helpers.ts` → Supabase 쿼리 함수로 교체
- `src/app/[locale]/(public)/newsroom/` — mock → supabase
- `src/app/[locale]/(public)/media/` — mock → supabase
- `src/app/[locale]/(public)/insights/` — 하드코딩 → supabase
- `src/components/sections/ResourcesSection.tsx` — mock → supabase
- `src/components/sections/MetricsSection.tsx` — 하드코딩 → supabase

### 접근 방식
- Server Components에서 `createServerClient()`로 Supabase 직접 쿼리
- Client Components는 props로 데이터 전달받기
- 기존 타입 구조 유지하여 호환성 보장

---

## Step 4: nxtcloud-admin 백오피스 완성

### 변경 대상
- 대시보드: mock → 실제 통계 쿼리
- 기사/영상: 이미 부분 구현 → 완성 + 파일 업로드
- 지표 관리: mock → 실제 CRUD
- 문의 관리: mock → 실제 조회 + 상태 변경
- 인증서 관리: 이미 부분 구현 → 완성
- 인사이트 관리: 신규 추가 필요 (CRUD 페이지)

### 신규 페이지
- `/admin/insights` — 인사이트 목록
- `/admin/insights/new` — 새 인사이트 등록
- `/admin/insights/[id]` — 인사이트 수정

---

## Step 5: Supabase Auth 설정
- 관리자 계정 생성 (이메일/비밀번호)
- nxtcloud-admin 미들웨어 인증 연동 확인

---

## 실행 순서
1. Supabase 프로젝트 생성 (사용자)
2. 스키마 보완 SQL 작성 & 실행
3. Mock 데이터 시딩 SQL 생성
4. nxtcloud-homepage 데이터 전환 (Server Components → Supabase)
5. nxtcloud-admin mock → 실제 쿼리 전환
6. nxtcloud-admin 인사이트 관리 페이지 추가
7. 양쪽 프로젝트 테스트

## 검증
- nxtcloud-homepage: 뉴스룸/미디어/인사이트 페이지에서 실데이터 표시 확인
- nxtcloud-admin: 로그인 → 각 CRUD 동작 확인
- admin에서 수정 → homepage에 반영되는지 확인
