# 테스트 코드 도입 (Vitest)

## Context
게임 핵심 비즈니스 로직(스탯 계산, 게임오버 판정, 점수 계산, 업적 판정)이 순수 함수로 잘 분리되어 있어 테스트 작성이 용이하다. 현재 테스트 인프라가 전혀 없으므로 Vitest를 도입해 핵심 로직의 신뢰성을 확보한다.

Next.js 공식 문서 및 Zustand 공식 문서 모두 Vitest를 권장한다. 순수 함수만 테스트하므로 `@vitejs/plugin-react`나 jsdom 불필요, `node` 환경으로 빠르게 실행.

## 1. 설치

```bash
npm install --save-dev vitest @vitest/coverage-v8 vite-tsconfig-paths
```

- `vitest` — 테스트 러너
- `@vitest/coverage-v8` — V8 기반 커버리지 (babel 불필요)
- `vite-tsconfig-paths` — tsconfig의 `@/*` 경로 별칭 자동 해석

## 2. vitest.config.ts (프로젝트 루트에 신규 생성)

```ts
import { defineConfig } from 'vitest/config';
import tsconfigPaths from 'vite-tsconfig-paths';

export default defineConfig({
  plugins: [tsconfigPaths()],
  test: {
    environment: 'node',
    globals: true,
    include: ['src/**/*.test.ts'],
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html'],
      include: ['src/lib/**/*.ts', 'src/stores/**/*.ts'],
      exclude: ['src/lib/scenarios.ts', 'src/lib/supabase.ts'],
    },
  },
});
```

## 3. package.json scripts 추가

```json
"test": "vitest run",
"test:watch": "vitest",
"test:coverage": "vitest run --coverage"
```

## 4. 파일 구조

```
src/
  lib/
    __tests__/
      gameEngine.test.ts    ← 순수 함수 6개
      achievements.test.ts  ← 업적 로직 2개
  stores/
    __tests__/
      gameStore.test.ts     ← Zustand 상태 전이
```

## 5. 테스트 케이스 설계

### gameEngine.test.ts (`src/lib/gameEngine.ts`)

#### applyChoice
| 케이스 | 입력 | 기대값 |
|--------|------|--------|
| 기본 효과 적용 | satisfaction:60 + 효과+10 | 70 |
| 100 초과 클램핑 | satisfaction:95 + 효과+20 | 100 |
| 0 미만 클램핑 | budget:5 + 효과-20 | 0 |
| 모든 효과 0 | — | 원본과 동일 |
| 경계값 정확히 100 | satisfaction:90 + 효과+10 | 100 |
| 경계값 정확히 0 | budget:10 + 효과-10 | 0 |

#### checkGameOver
| 케이스 | 입력 | 기대값 |
|--------|------|--------|
| 정상 스탯 | 모두 60 | null |
| satisfaction = 0 | — | `'학생들의 불만이 폭발했습니다! 탄핵 투표가 통과되었습니다.'` |
| budget = 0 | — | `'학생회 예산이 바닥났습니다! 운영이 불가능합니다.'` |
| career = 0 | — | `'진로 지원이 무너졌습니다! 취업률이 급락하며 학생들이 학교를 외면하기 시작했습니다.'` |
| academic = 0 | — | `'학업 분위기가 완전히 무너졌습니다! 교수회의에서 퇴진 요구가 나왔습니다.'` |
| satisfaction = 1 | — | null |
| satisfaction+budget 동시 0 | — | satisfaction 우선 (탄핵 메시지) |

#### canUseEmergency (THRESHOLD=30, strictly `<`)
| 케이스 | 기대값 |
|--------|--------|
| stats.satisfaction=29, used=0, max=3 | true |
| used=3, max=3 | false |
| 모든 스탯 정확히 30 (30은 < 30 아님) | false |
| stats.career=29, used=1 | true |

#### applyEmergency (THRESHOLD=30, RECOVER_TO=35)
| 케이스 | 기대값 |
|--------|--------|
| satisfaction=20 | 35 |
| satisfaction=30 (30 < 30 아님) | 30 그대로 |
| 모두 30 미만 | 모두 35 |
| 모두 30 이상 | 변화 없음 |

#### getScenarioForWeek
- 정상 주차 → 해당 시나리오 반환
- 없는 주차 (99) → null
- 빈 배열 → null

#### calculateScore
| 케이스 | 계산 | 기대값 |
|--------|------|--------|
| week=30, all 60, used=0 | 3000+1200+500-0 | total=4700, grade='명예 졸업' |
| week=30, all 100, used=0 | 3000+2000+500-0 | total=5500, grade='전설의 학생회장' |
| week=30, all 60, used=2 | 4700-600 | total=4100, grade='명예 졸업' |
| week=30, all 75, used=0 | 3000+1500+500 | total=5000, grade='전설의 학생회장' (경계) |
| efficiencyBonus 캡 | minStat=100 → 1000 → 500 | efficiencyBonus=500 |
| 음수 방지 | week=1, all 1, used=3 → -770 | total=0, grade='자퇴 권유' |

### achievements.test.ts (`src/lib/achievements.ts`)

`checkAchievements`는 `Pick<GameState, 'stats' | 'emergencyUsed' | 'lowestStatEver' | 'firstTenWeeksClean'>`를 받음 (전체 GameState 불필요).

| 업적 id | 달성 조건 | Happy | Edge |
|---------|-----------|-------|------|
| no_emergency | emergencyUsed === 0 | 0 → 획득 | 1 → 미획득 |
| all_emergency | emergencyUsed >= 3 | 3 → 획득 | 2 → 미획득 |
| legend | grade === '전설의 학생회장' | 해당 → 획득 | 다른 grade → 미획득 |
| comeback | lowestStatEver <= 30 | 30 → 획득 | 31 → 미획득 |
| perfect_stats | 모든 스탯 >= 75 | 모두 75 → 획득 | 하나 74 → 미획득 |
| early_clean | firstTenWeeksClean | true → 획득 | false → 미획득 |
| budget_master | budget >= 80 | 80 → 획득 | 79 → 미획득 |
| popularity | satisfaction >= 85 | 85 → 획득 | 84 → 미획득 |

추가:
- 모든 조건 동시 충족 → 7개 이상 반환
- 아무 조건 미충족 → 빈 배열 반환
- `calcAchievementBonus`: no_emergency(300) + perfect_stats(600) → 900, 빈 배열 → 0

### gameStore.test.ts (`src/stores/gameStore.ts`)

Zustand는 React 없이 `getState()` / `setState()` 직접 접근 가능 → node 환경에서 실행.
`beforeEach`: `useGameStore.getState().reset()` 으로 테스트 격리.
`makeChoice()` 호출 시 `currentScenario`가 non-null이어야 함 → `startGame()` 먼저 호출.

| 케이스 | 검증 내용 |
|--------|----------|
| startGame() | phase='playing', week=1, currentScenario≠null |
| makeChoice() 안전 선택 | phase='playing' 유지 |
| makeChoice() 모든 스탯 -100 | phase='gameOver', gameOverReason 설정 |
| week=30에서 makeChoice() 안전 선택 | phase='victory' |
| lowestStatEver 추적 | satisfaction 60→15 이후 lowestStatEver <= 15 |
| useEmergency() | emergencyUsed+1, emergencyCount-1 |
| getScore() | ScoreResult 반환, totalScore는 number |
| reset() | phase='landing', week=0, emergencyUsed=0 |

## 6. 수정/생성 파일

| 파일 | 변경 |
|------|------|
| `vitest.config.ts` | 신규 생성 |
| `package.json` | scripts 3개 추가 |
| `src/lib/__tests__/gameEngine.test.ts` | 신규 생성 |
| `src/lib/__tests__/achievements.test.ts` | 신규 생성 |
| `src/stores/__tests__/gameStore.test.ts` | 신규 생성 |

## 7. 검증

```bash
npm install --save-dev vitest @vitest/coverage-v8 vite-tsconfig-paths
npm test                 # 전체 테스트 통과 확인
npm run test:coverage    # lib 커버리지 80%+ 목표
```
