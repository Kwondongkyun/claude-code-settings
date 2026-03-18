# devfeed-be → Next.js API Routes 마이그레이션 플랜

## Context

Python FastAPI 백엔드(devfeed-be)를 제거하고, 동일한 API를 Next.js App Router API Routes로 이식.
DB는 Supabase JS Client를 사용. 인증은 기존 Custom JWT(HS256 + bcrypt) 유지.
프론트엔드 API 호출 코드(features/*/api.ts)는 변경 없음 - 동일한 URL, 동일한 Request/Response 형식 유지.

## 새로운 아키텍처

```
Next.js (프론트 + API Routes)
  └── /api/v1/auth/register        POST
  └── /api/v1/auth/login           POST
  └── /api/v1/auth/refresh         POST
  └── /api/v1/auth/me              GET
  └── /api/v1/auth/favorites/sources        GET
  └── /api/v1/auth/favorites/sources/[id]  POST/DELETE
  └── /api/v1/sources              GET
  └── /api/v1/articles             GET
  └── /api/v1/articles/[id]/read   POST
  └── /api/v1/cron/fetch-feeds     POST
         ↓ Supabase JS Client
    Supabase PostgreSQL
```

## 설치 패키지 (devfeed)

```bash
npm install @supabase/supabase-js bcryptjs jsonwebtoken rss-parser
npm install -D @types/bcryptjs @types/jsonwebtoken @types/rss-parser
```

## 환경변수 (devfeed/.env)

```
NEXT_PUBLIC_API_URL=http://localhost:8002   # 삭제 (이제 같은 서버)
SUPABASE_URL=https://xnqaosegikdvqhbrtchg.supabase.co
SUPABASE_SERVICE_ROLE_KEY=<대시보드에서 확인>
JWT_SECRET=<기존 devfeed-be JWT_SECRET_KEY 값>
JWT_ACCESS_EXPIRE_MINUTES=30
JWT_REFRESH_EXPIRE_DAYS=7
CRON_SECRET=
```

## 생성할 파일 목록

### 인프라 레이어

1. **`src/lib/db/supabase.ts`**
   - `createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY)` - 서버용 service role client
   - export: `db`

2. **`src/lib/auth/jwt.ts`**
   - `signAccessToken(userId)` → JWT (30min)
   - `signRefreshToken(userId)` → JWT (7days)
   - `verifyToken(token, type)` → userId | null

3. **`src/lib/auth/password.ts`**
   - `hashPassword(plain)` → hash (bcryptjs, rounds=12)
   - `verifyPassword(plain, hash)` → boolean

4. **`src/lib/api/response.ts`**
   - `ok(data)` → `{ success: true, result: data }`
   - `err(msg, status)` → `{ success: false, error: { message } }`
   - 현재 axios.ts의 에러 interceptor와 호환되는 형식

5. **`src/lib/auth/getUser.ts`**
   - `getCurrentUser(req)` → User | null
   - Authorization 헤더에서 Bearer 토큰 추출 → verifyToken → Supabase에서 user 조회

### API Routes

6. **`src/app/api/v1/auth/register/route.ts`** - POST
   - email 중복 체크 → bcrypt hash → insert user → access/refresh token 반환

7. **`src/app/api/v1/auth/login/route.ts`** - POST
   - find user by email → verifyPassword → token 반환

8. **`src/app/api/v1/auth/refresh/route.ts`** - POST
   - verifyToken(type="refresh") → find user → 새 tokens 반환

9. **`src/app/api/v1/auth/me/route.ts`** - GET
   - getCurrentUser → user 반환

10. **`src/app/api/v1/auth/favorites/sources/route.ts`** - GET
    - getCurrentUser → favorite_source 테이블에서 source_id 목록 반환

11. **`src/app/api/v1/auth/favorites/sources/[sourceId]/route.ts`** - POST/DELETE
    - POST: insert into favorite_source (upsert)
    - DELETE: delete from favorite_source

12. **`src/app/api/v1/sources/route.ts`** - GET
    - source 테이블에서 is_active=true 전체 조회
    - 각 source의 최신 article.published_at 조회

13. **`src/app/api/v1/articles/route.ts`** - GET
    - source, search, cursor, limit, sort 파라미터 처리
    - Supabase query builder로 필터링 + cursor pagination
    - 인증 사용자면 read 여부 포함

14. **`src/app/api/v1/articles/[articleId]/read/route.ts`** - POST
    - getCurrentUser → upsert into read_article

15. **`src/app/api/v1/cron/fetch-feeds/route.ts`** - POST
    - RSS fetcher: `rss-parser` 패키지
    - HackerNews fetcher: fetch API
    - Dev.to fetcher: fetch API
    - 기존 URL 중복 체크 → bulk insert

### 프론트엔드 수정

16. **`src/features/feed/cron/api.ts`** 수정
    - API URL: `http://localhost:8002/api/v1/...` → `/api/v1/...` (상대 경로)

17. **`src/features/auth/api.ts`** 수정 (동일)

18. **`src/features/feed/articles/api.ts`** 수정 (동일)

19. **`src/features/feed/sources/api.ts`** 수정 (동일)

20. **`devfeed/.env`** 수정
    - `NEXT_PUBLIC_API_URL` 제거 (same-origin)

## 응답 형식 (기존과 동일)

```json
// 성공
{ "success": true, "result": <data> }

// 실패
{ "success": false, "error": { "message": "..." } }
```

현재 axios interceptor가 `error.response?.data?.message`를 읽으므로 그대로 유지.

## 마이그레이션 주의사항

- Supabase의 `service_role` key는 RLS를 우회 → 서버 사이드에서만 사용 (API Routes)
- `SUPABASE_SERVICE_ROLE_KEY`는 `NEXT_PUBLIC_` prefix 없이 → 클라이언트에 노출 금지
- 기존 Python 백엔드의 응답 wrapper: `{ success, result }` 형식 그대로 유지
- 현재 `NEXT_PUBLIC_API_URL`이 axios baseURL로 쓰이는데, 같은 서버가 되므로 빈 문자열("")로 변경 or 제거

## Supabase Service Role Key 확인 방법

Supabase 대시보드 → Project Settings → API → `service_role` key (secret)

## 검증 방법

1. `npm run dev` 실행 후 브라우저에서 devfeed 접속
2. 회원가입/로그인 동작 확인
3. 아티클 목록 로딩 확인
4. fetch_feeds 버튼 클릭 확인
5. 즐겨찾기 추가/제거 확인
6. Python 백엔드 완전 종료 후에도 동작 확인
