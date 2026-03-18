# 게임 피드백 버그 수정 계획

## Context

사용자 피드백 5건 중 핵심 버그: 정답을 맞췄는데도 "시간 초과"가 표시됨.
원인은 **오답 클릭의 800ms setTimeout이 정답의 `isCorrect: true`를 `null`로 덮어쓰는 레이스 컨디션**.

## 버그 원인 분석

`gameStore.ts` selectImage 오답 처리 (104-123행):
```
오답 클릭 → isCorrect: false → 800ms 후 isCorrect: null로 리셋
```

시나리오:
1. 오답 클릭 → `isCorrect: false`, 800ms 타이머 시작
2. **200ms 후** 정답 클릭 → `isCorrect: true`, `phase: "feedback"`
3. **600ms 후** 오답의 setTimeout 실행 → `isCorrect: null`로 덮어씀
4. 1500ms 후 `roundComplete` → `isCorrect ?? false` = `false` → **"시간 초과" 표시**

추가로 `handleTimeout()`에도 phase 체크가 없어서, 정답 클릭 직후 타이머가 끝나면 덮어쓰는 문제도 있음.

---

## 수정 사항

### 1. 오답 setTimeout에 phase 가드 추가
**파일**: `src/stores/gameStore.ts` (117-122행)

오답의 800ms setTimeout에서 phase가 아직 "playing"인 경우에만 isCorrect를 리셋:
```typescript
setTimeout(() => {
  const { phase } = get();
  if (phase === 'playing') {
    set({ selectedImageId: null, isCorrect: null });
  }
}, 800);
```

### 2. handleTimeout에 phase 가드 추가
**파일**: `src/stores/gameStore.ts` (126행)

이미 정답을 맞춘 상태면 timeout을 무시:
```typescript
handleTimeout: () => {
  const { phase, gridImages } = get();
  if (phase !== 'playing') return;
  // ... 기존 로직
}
```

### 3. RoundComplete 메시지 3가지 상태로 분리
**파일**: `src/components/game/RoundComplete.tsx`

현재: 정답 / "시간 초과" 2가지 → 정답 / 오답(시간 초과) / 오답(못 맞춤) 구분

방법: `roundScore`와 `isCorrect`로 판단:
- `isCorrect === true` → "정답을 맞췄습니다!"
- `isCorrect === false` (타임아웃) → "시간 초과..."

사실 현재 게임에서 라운드가 끝나는 경우는 정답 또는 타임아웃 2가지뿐이므로, 위 가드만 추가하면 정답을 맞췄을 때 "시간 초과"가 뜨는 버그는 해결됨.

### 4. 미션 텍스트 강조 (피드백 2)
**파일**: `src/components/game/GameHUD.tsx` (59-61행)

현재: `text-sm font-semibold text-white/90` (작고 흰색)

수정:
- 글씨 크기 키우기: `text-sm` → `text-base`
- 미션별 색상 구분: pickAI → 빨간 계열, pickReal → 초록 계열
- 미션 키워드 강조

**파일**: `src/components/game/GameHUD.tsx` — missionText 대신 mission 타입도 props로 받아서 색상 분기

### 5. AI 이미지 1장 안내 추가 (피드백 4)
**파일**: `src/components/game/RoundBriefing.tsx`

브리핑 화면의 기존 grid 2x2 정보 카드에 AI 이미지 수 정보 추가.
또는 미션 텍스트를 더 구체적으로 변경:
- "AI가 만든 이미지를 찾으세요!" → "AI가 만든 이미지 **1장**을 찾으세요!"
- "실제 이미지를 고르세요!" → "실제 이미지 **1장**을 고르세요!"

`constants.ts`의 missionText를 수정하거나, RoundBriefing에서 aiCount를 활용하여 동적 표시.

---

## 수정 파일 목록

| 파일 | 변경 내용 |
|------|----------|
| `src/stores/gameStore.ts` | 오답 setTimeout 가드, handleTimeout 가드 |
| `src/components/game/GameHUD.tsx` | 미션 텍스트 강조 (크기/색상) |
| `src/components/game/RoundBriefing.tsx` | AI 이미지 장수 안내 |
| `src/lib/constants.ts` | missionText에 장수 포함 (선택) |

## 검증

1. `npm run build` 빌드 성공 확인
2. 로컬에서 게임 플레이:
   - 오답 여러 번 클릭 후 정답 → "정답 맞췄습니다!" 확인
   - 시간 초과 시 → "시간 초과..." 확인
   - 미션 텍스트가 눈에 잘 띄는지 확인
   - 브리핑에서 AI 이미지 장수 표시 확인
