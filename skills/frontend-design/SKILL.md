---
name: frontend-design
description: Use when building web UI, pages, dashboards, or landing pages. Enforces design thinking process, typography/color/motion guidelines, and prevents generic AI aesthetics.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# 프론트엔드 디자인 품질 가이드

## Design Thinking — 코딩 전 필수

UI를 만들기 전에 반드시 미적 방향을 결정한다:

1. **Purpose**: 이 인터페이스가 해결하는 문제는? 누가 사용하는가?
2. **Tone**: 어떤 분위기인가? (미니멀, 럭셔리, 에디토리얼, 브루탈리즘, 레트로 등)
3. **Constraints**: 기술 요구사항 (프레임워크, 성능, 접근성)
4. **Differentiation**: 이 디자인을 기억에 남게 만드는 단 하나의 것은?

핵심: **의도성(intentionality)**이 중요하지, 강도(intensity)가 아니다. 대담한 맥시멀리즘과 정제된 미니멀리즘 모두 좋다 — 일관성 있게 실행하면 된다.

## AI Slop 금지 목록

AI가 반복적으로 선택하는 제네릭 패턴을 금지한다:

### 폰트 금지
```
Inter, Roboto, Arial, system-ui (기본 시스템 폰트)
Space Grotesk (AI가 자주 선택하는 폰트)
```

독특한 디스플레이 폰트 + 세련된 본문 폰트를 페어링한다. 매번 다른 폰트를 선택한다.

### 색상 금지
```
보라색 그라디언트 + 흰색 배경 (AI의 대표적 클리셰)
```

지배적 색상 + 날카로운 액센트가 소심하게 균등 분배된 팔레트보다 효과적이다.

### 레이아웃 금지
```
예측 가능한 카드 그리드, 동일한 섹션 반복, 좌우 대칭 히어로
```

## 타이포그래피

- 폰트 선택이 디자인의 50%를 결정한다
- Google Fonts에서 독특한 조합을 찾는다
- 디스플레이 폰트 (제목용) + 본문 폰트를 분리한다
- 폰트 크기 간 시각적 계층을 명확히 한다

## 색상 & 테마

- CSS 변수(custom properties)로 색상 체계를 일관되게 관리한다
- 라이트/다크 테마를 번갈아 시도한다 — 항상 같은 테마로 수렴하지 않는다
- 브랜드 컬러 1~2개 + 뉴트럴 톤으로 구성한다

```css
:root {
  --color-primary: #...;
  --color-accent: #...;
  --color-bg: #...;
  --color-text: #...;
}
```

## 모션

- **전략**: 잘 조율된 페이지 로드 애니메이션 1개 (animation-delay로 순차 reveal)가 산발적 마이크로 인터랙션 10개보다 낫다
- HTML: CSS-only 솔루션 우선
- React: Motion 라이브러리 (framer-motion) 사용
- scroll-trigger와 hover 상태를 활용한다

## 공간 구성

- 예상치 못한 레이아웃: 비대칭, 겹침, 대각선 흐름
- 그리드를 의도적으로 깨는 요소를 1~2개 배치
- 넓은 여백 또는 통제된 밀도 — 중간은 없다

## 배경 & 시각 디테일

단색 배경을 기본값으로 쓰지 않는다. 분위기와 깊이감을 만든다:
- gradient meshes, noise textures
- geometric patterns, layered transparencies
- dramatic shadows, grain overlays

## 복잡도 매칭

구현 복잡도를 미적 비전에 맞춘다:
- **맥시멀리즘**: 정교한 코드 + 풍부한 애니메이션 + 이펙트
- **미니멀리즘**: 절제 + 정밀함 + 간격/타이포/서틀 디테일에 집중
