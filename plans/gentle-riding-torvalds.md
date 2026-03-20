# Supabase 무료 플랜 자동 일시정지 방지 (Keep-Alive)

## Context

Supabase 무료 플랜은 **7일간 비활성 시 DB가 자동 일시정지(pause)** 된다. 이를 방지하기 위해 주기적으로 DB에 쿼리를 보내는 Cron Job을 설정한다.

## 구현 계획

### 1. API Route 생성: `src/app/api/cron/keep-alive/route.ts`

- Supabase `leaderboard_entries` 테이블에 간단한 `SELECT count` 쿼리 실행
- `Authorization` 헤더로 `CRON_SECRET` 검증 (외부 무단 호출 방지)
- 성공/실패 JSON 응답 반환

```ts
// 핵심 로직
const { count, error } = await supabase
  .from('leaderboard_entries')
  .select('*', { count: 'exact', head: true });
```

### 2. Vercel Cron 설정: `vercel.json` 생성

```json
{
  "crons": [
    {
      "path": "/api/cron/keep-alive",
      "schedule": "0 0 */5 * *"
    }
  ]
}
```

- **주기**: 5일마다 1회 (7일 제한 대비 충분한 여유)
- Vercel 무료 플랜: Cron Job 1개, 1일 1회까지 허용 → 5일 1회는 충분

### 3. 환경 변수 추가

- `CRON_SECRET`: Vercel 대시보드에서 설정 (Vercel이 Cron 호출 시 자동으로 `Authorization: Bearer <CRON_SECRET>` 전송)

## 수정 파일

| 파일 | 작업 |
|------|------|
| `src/app/api/cron/keep-alive/route.ts` | **신규** - Keep-alive API route |
| `vercel.json` | **신규** - Cron 스케줄 설정 |

## 검증

1. `curl http://localhost:3000/api/cron/keep-alive` 로 로컬 테스트
2. Vercel 배포 후 대시보드 > Settings > Cron Jobs에서 등록 확인
3. Vercel 로그에서 Cron 실행 기록 확인
