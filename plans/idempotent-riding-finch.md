# DevFeed 대시보드 리텐션 중심 재구성

## Context

현재 대시보드는 운영 모니터링 80% + 성장 분석 20% 구성. 사용자의 핵심 목표는 **리텐션 향상**이므로, 리텐션/성장 지표를 상단에 배치하고 운영 섹션은 축소/접기 처리하여 **리텐션 70% + 운영 30%** 구조로 전환한다.

## 새로운 레이아웃 (위→아래)

```
1. 헤더 (유지)
2. 에러 로그 (조건부, 유지)
3. ★ 리텐션 KPI 카드 (NEW - 기존 KPI 대체)
4. 실시간 트래픽 (유지)
5. 트래픽 추이 차트 (유지 - 리텐션 메트릭 이미 포함)
6. ★ 리텐션 인사이트 3패널 (NEW)
7. 방문자 분석 4패널 (유지)
8. 피드백 (유지)
9. ★ 운영 섹션 (크론+유저+아티클 통합, 기본 접힘)
10. 푸터 (유지)
```

---

## Step 1: 데이터 레이어 확장

**파일: `lib/analytics.ts`**

- `getMonthlyActiveUsers()` 함수 추가 — 30일 전체 activeUsers 집계 (Stickiness 계산용)

**파일: `app/page.tsx` > `getData()`**

Promise.all에 4개 호출 추가:
```
getDimensionReport("newVsReturning", "sessions", 30, 2)   → 신규 vs 재방문
getDimensionReport("landingPage", "bounceRate", 30, 10)    → 랜딩페이지별 이탈률
getDimensionReport("hour", "activeUsers", 30, 24)          → 시간대별 활성 패턴
getMonthlyActiveUsers()                                     → MAU (Stickiness 계산)
```

**주의 - GA4 API 쿼터**: 현재 revalidate=60초 + 14호출 = ~20,160토큰/일. 18호출로 증가 시 ~25,920토큰으로 일일 쿼터(25,000) 초과 가능. → `revalidate`를 120초로 변경하여 ~12,960토큰/일로 안전하게 유지.

---

## Step 2: 새 컴포넌트 생성

### 2-1. `app/components/CollapsibleSection.tsx` (신규, ~40줄)
- Props: `title: string`, `defaultOpen?: boolean`, `children: ReactNode`
- useState로 open/close 토글, 화살표 아이콘 회전
- 기존 section 헤더 스타일 유지 (text-sm font-bold uppercase tracking-widest)

### 2-2. `app/components/RetentionKPICards.tsx` (신규, ~100줄)

기존 KPI (총 아티클/유저/알림/크론) **완전 제거** → 리텐션 지표 4개로 교체:
(기존 총 아티클/유저 수치는 운영 섹션 탭 내에서 확인)

| 카드 | 데이터 소스 | 계산 |
|---|---|---|
| 재방문율 | newVsReturning | returning / total * 100 |
| Stickiness | yesterdayActiveUsers / mau | DAU/MAU * 100 |
| 참여율 (30일 평균) | monthlyTraffic | engagementRate 평균 * 100 |
| 세션/유저 (30일 평균) | monthlyTraffic | sessionsPerUser 평균 |

- 전주 대비 변화율 표시 (↑ 초록, ↓ 빨강)
- 기존 KPI 카드 레이아웃 그대로 (grid-cols-4 + ShimmerOverlay)

### 2-3. `app/components/RetentionInsights.tsx` (신규, ~180줄)

3패널 그리드 (grid-cols-3):

**(a) 신규 vs 재방문** — PieChart (AnalyticsPanels 디바이스 도넛 패턴 재사용)
**(b) 시간대별 활성 패턴** — BarChart (0~23시, 피크 시간 하이라이트)
**(c) 랜딩페이지별 이탈률** — 수평 바 리스트 (이탈률 70%+ 빨강 경고)

### 2-4. `app/components/OperationsSection.tsx` (신규, ~250줄)

기존 page.tsx에서 추출:
- CollapsibleSection으로 감싸기 (`defaultOpen={false}`)
- 내부에 Radix Tabs 4개: 크론로그 / 유저 / 소스별 아티클 / 최근 아티클
- 코드 이동만, 로직 변경 없음

---

## Step 3: page.tsx 재구성

- getData() 확장: 새 데이터 소스 4개 추가 + return에 포함
- 기존 KPI 카드 → `<RetentionKPICards>` 교체
- 리텐션 인사이트 섹션 추가: `<RetentionInsights>`
- 운영 관련 JSX 전체 → `<OperationsSection>`으로 대체
- revalidate: 60 → 120
- 예상 577줄 → ~180줄로 축소

---

## Step 4: AnalyticsPanels 내부 유틸 export

**파일: `app/components/AnalyticsPanels.tsx`**

- 내부 `PanelCard`를 named export로 변경 (RetentionInsights에서 재사용)

---

## 구현 순서 & 병렬화

```
[병렬 A] Step 1: analytics.ts + Step 2-1: CollapsibleSection + Step 4: PanelCard export
    ↓
[병렬 B] Step 2-2: RetentionKPICards + Step 2-3: RetentionInsights + Step 2-4: OperationsSection
    ↓
[단독]   Step 3: page.tsx 통합
```

---

## 수정 파일 목록

| 파일 | 변경 |
|---|---|
| `lib/analytics.ts` | getMonthlyActiveUsers 추가 |
| `app/components/CollapsibleSection.tsx` | 신규 |
| `app/components/RetentionKPICards.tsx` | 신규 |
| `app/components/RetentionInsights.tsx` | 신규 |
| `app/components/OperationsSection.tsx` | 신규 |
| `app/components/AnalyticsPanels.tsx` | PanelCard export 추가 |
| `app/page.tsx` | getData 확장 + 레이아웃 재구성 |

---

## 검증

1. `npx tsc --noEmit` — 타입 에러 없는지 확인
2. `npm run dev` — 로컬에서 대시보드 렌더링 확인
3. 리텐션 KPI 카드 4개가 정상 계산되는지 확인
4. 리텐션 인사이트 3패널 차트 렌더링 확인
5. 운영 섹션 접기/펼치기 동작 확인
6. GA4 API 호출 수 확인 (서버 로그)
