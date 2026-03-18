# 크론 일 1회 변경 + 즐겨찾기 소스 알림 기능

## Context
현재 크론잡이 매 1시간 실행되는데, 하루 1회로 변경하고 싶다. 또한 로그인 사용자가 즐겨찾기한 블로그에 새 글이 올라오면 알림을 받을 수 있도록 한다. 사이트 내 토스트 + 헤더 벨 아이콘(읽지 않은 개수 뱃지) + 알림 내역 팝오버를 구현한다.

## 수정 대상 파일

### 1. 크론 스케줄 변경
**파일:** `.github/workflows/cron-fetch-feeds.yml`
- `cron: "0 * * * *"` → `cron: "0 9 * * *"` (매일 KST 18시 = UTC 9시)

### 2. Supabase `notification` 테이블 생성 (수동 SQL)
사용자가 Supabase 대시보드에서 직접 실행:
```sql
CREATE TABLE notification (
  id BIGSERIAL PRIMARY KEY,
  user_id BIGINT NOT NULL REFERENCES "user"(id) ON DELETE CASCADE,
  article_id BIGINT NOT NULL REFERENCES article(id) ON DELETE CASCADE,
  source_id UUID NOT NULL REFERENCES source(id) ON DELETE CASCADE,
  is_read BOOLEAN NOT NULL DEFAULT false,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notification_user_unread ON notification(user_id, is_read) WHERE is_read = false;
CREATE INDEX idx_notification_user_created ON notification(user_id, created_at DESC);
```

### 3. fetch-feeds에 알림 생성 로직 추가
**파일:** `src/app/api/v1/cron/fetch-feeds/route.ts`
- 새 글 insert 후, `favorite_source` 테이블 조회
- 해당 source를 즐겨찾기한 사용자들에게 `notification` 레코드 bulk insert
- 기존 로직 흐름: fetch → dedup → insert → **(추가) 알림 생성**

### 4. 알림 API 엔드포인트 3개 추가

**`src/app/api/v1/auth/notifications/route.ts`** (신규)
- `GET`: 로그인 사용자의 알림 목록 (최근 50개, article+source join)

**`src/app/api/v1/auth/notifications/unread-count/route.ts`** (신규)
- `GET`: 읽지 않은 알림 개수 반환

**`src/app/api/v1/auth/notifications/read/route.ts`** (신규)
- `POST`: 알림 읽음 처리 (`{ notificationIds: number[] }` 또는 `{ all: true }`)

### 5. 클라이언트 feature 파일
**`src/features/notification/types.ts`** (신규)
- `Notification` 타입 정의

**`src/features/notification/api.ts`** (신규)
- `fetchNotifications()`, `fetchUnreadCount()`, `markAsRead()` API 함수

### 6. shadcn/ui Popover 설치
```bash
npx shadcn@latest add popover
```

### 7. NotificationBell 컴포넌트
**`src/components/common/NotificationBell/index.tsx`** (신규)
- Bell 아이콘 (lucide-react `Bell`)
- 읽지 않은 알림 수 뱃지 (빨간 원 + 숫자)
- 클릭 시 Popover로 알림 목록 표시
- 각 알림: 소스명 + 글 제목 + 시간, 클릭 시 해당 글로 이동 + 읽음 처리
- "모두 읽음" 버튼
- 빈 상태: "새로운 알림이 없습니다"
- 30초마다 unread count polling
- 새 알림 감지 시 sonner toast 표시

### 8. Header에 NotificationBell 추가
**파일:** `src/components/common/Header/index.tsx`
- 로그인 상태일 때 테마 토글 버튼 왼쪽에 `<NotificationBell />` 추가

## 구현 순서
1. 크론 스케줄 변경
2. Supabase SQL 안내
3. fetch-feeds 알림 생성 로직
4. 알림 API 3개
5. 클라이언트 feature 파일 (types, api)
6. shadcn popover 설치
7. NotificationBell 컴포넌트
8. Header 연동

## 검증
1. 로컬에서 fetch-feeds API 호출 → notification 테이블에 레코드 생성 확인
2. 알림 API 3개 정상 응답 확인
3. 헤더에서 벨 아이콘 + 뱃지 + 팝오버 동작 확인
4. 알림 클릭 시 글 이동 + 읽음 처리 확인
