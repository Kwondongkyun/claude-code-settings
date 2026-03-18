# 오답 피드백 UX 개선

## Context
사용자 피드백: 오답 이미지를 클릭했을 때 피드백이 불친절하여, 오답인 줄 모르고 같은 이미지를 반복 클릭하며 "왜 안 넘어가지?" 라는 혼란을 겪음. 현재 오답 시 빨간 테두리 + 흔들림만 있고 800ms 후 조용히 초기화되어 재클릭 가능해짐.

**방향:** 오답 피드백 강화 + 재시도 유지 (게임 난이도 유지)

## 변경 사항

### 1. `src/stores/gameStore.ts` — 오답 이미지 비활성화 유지
**현재:** 오답 클릭 → selected=true → 800ms 후 selected=false 초기화 (재클릭 가능)
**변경:** 오답 클릭 → selected=true 유지 (초기화하지 않음) → 재클릭 불가

```
// 변경: setTimeout 내부에서 selected를 false로 초기화하지 않음
// selectedImageId와 isCorrect만 초기화하여 다음 클릭 감지 가능하게
setTimeout(() => {
  set({
    selectedImageId: null,
    isCorrect: null,
  });
}, 800);
```

`image.selected`가 true로 유지되므로 `selectImage()`의 `if (image.selected) return;` 체크에 의해 자연스럽게 재클릭 방지됨.

### 2. `src/components/game/ImageCard.tsx` — 오답 시각 피드백 강화
**현재:** 오답 이미지에 이미지 타입 기반 색상 (AI=빨강, Real=초록) → 혼란 유발
**변경:**

- 오답 이미지 (selected && !revealed): 항상 danger 색상 테두리 (이미지 타입 무관)
- 오답 오버레이 추가: 반투명 빨간 배경 + X 아이콘 + "오답" 라벨
- 흔들림 애니메이션 유지

```tsx
// getBorderClass() 수정
if (image.selected && !image.revealed) return 'border-danger/60 ring-1 ring-danger/30';

// getOverlay()에 오답 오버레이 추가
if (image.selected && !image.revealed) {
  return (
    <div className="absolute inset-0 bg-black/50 flex items-center justify-center rounded-lg">
      <span className="bg-danger/90 text-white text-xs font-bold px-2 py-1 rounded flex items-center gap-1">
        <XCircle size={12} /> 오답
      </span>
    </div>
  );
}
```

### 3. `src/app/game/page.tsx` — 토스트 피드백 메시지 + 감점 표시
오답 클릭 시 화면에 토스트 메시지 표시:
- **"오답! -50점"** — 감점 정보를 명확히 보여줌
- framer-motion AnimatePresence로 슬라이드 인/아웃
- 1.5초 후 자동 사라짐

```tsx
// isCorrect === false 감지하여 토스트 표시
const [showWrongToast, setShowWrongToast] = useState(false);

useEffect(() => {
  if (isCorrect === false) {
    setShowWrongToast(true);
    const timer = setTimeout(() => setShowWrongToast(false), 1500);
    return () => clearTimeout(timer);
  }
}, [isCorrect, wrongClicks]); // wrongClicks를 deps에 포함하여 연속 오답 감지
```

토스트 UI 예시:
```tsx
<AnimatePresence>
  {showWrongToast && (
    <motion.div
      initial={{ opacity: 0, y: -20 }}
      animate={{ opacity: 1, y: 0 }}
      exit={{ opacity: 0, y: -20 }}
      className="... bg-danger/90 text-white ..."
    >
      <XCircle /> 오답! -50점
    </motion.div>
  )}
</AnimatePresence>
```

이미지 그리드 상단에 오버레이로 표시, 게임 진행을 방해하지 않는 위치.

## 수정 파일 목록
| 파일 | 변경 내용 |
|------|----------|
| `src/stores/gameStore.ts` | 오답 시 selected 초기화 제거 (3줄 수정) |
| `src/components/game/ImageCard.tsx` | 오답 테두리 통일 + 오답 오버레이 추가 |
| `src/app/game/page.tsx` | 토스트 피드백 메시지 추가 |

## 검증
1. `npm run build` — 빌드 에러 없는지 확인
2. 브라우저에서 게임 플레이 테스트:
   - 오답 클릭 시 "오답" 오버레이 + 토스트 메시지 표시 확인
   - 오답 이미지 재클릭 불가 확인
   - 정답 클릭 시 기존 동작(모든 이미지 공개 + 라운드 완료) 유지 확인
   - 시간 초과 시 기존 동작 유지 확인
