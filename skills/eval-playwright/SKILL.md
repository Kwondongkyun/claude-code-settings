---
name: eval-playwright
description: Playwright MCP로 실제 앱을 열어 동적 테스트를 수행하는 규칙. iteration-evaluator 에이전트의 2단계(동적 테스트)에서 사용.
effort: medium
allowed-tools: Read, Bash, Glob, Grep, mcp__playwright
---

# Playwright 동적 평가 규칙

## 목적

코드를 보는 게 아니라, **실제 브라우저에서 앱을 열어** 사용자가 보는 것과 같은 화면을 검증한다.

## 사전 확인

테스트 시작 전 반드시:

```bash
# 1. 앱 서버가 떠 있는지 확인
curl -s -o /dev/null -w "%{http_code}" http://localhost:3000 || echo "NOT RUNNING"
```

서버가 안 떠 있으면:
```bash
# 백그라운드로 서버 시작 (Next.js 기준)
npm run dev &
sleep 5
```

## Playwright MCP 도구 사용

### 페이지 열기
```
mcp__playwright → navigate to http://localhost:3000
```

### 스크린샷 캡처
```
mcp__playwright → screenshot
```
- 모든 주요 판정에 스크린샷을 첨부한다
- 스크린샷은 판정의 증거이다

### 인터랙션
```
mcp__playwright → click element "버튼 텍스트"
mcp__playwright → fill input "입력 필드" with "값"
mcp__playwright → select option "드롭다운" value "옵션"
```

### 반응형 테스트
```
mcp__playwright → set viewport 375x812    # 모바일
mcp__playwright → screenshot
mcp__playwright → set viewport 768x1024   # 태블릿
mcp__playwright → screenshot
mcp__playwright → set viewport 1440x900   # 데스크톱
mcp__playwright → screenshot
```

## 테스트 체크리스트

### 기능성 (40%)
- [ ] 메인 페이지가 에러 없이 로드되는가
- [ ] 주요 네비게이션이 작동하는가 (링크 클릭 → 페이지 이동)
- [ ] 핵심 기능의 버튼/폼이 작동하는가
- [ ] API 호출이 정상 응답하는가 (Network 탭 확인 또는 콘솔 에러 없음)
- [ ] 데이터가 올바르게 표시되는가

### 디자인 품질 (25%)
- [ ] 375px에서 가로 스크롤이 없는가
- [ ] 768px, 1440px에서 레이아웃이 자연스러운가
- [ ] 텍스트가 잘리거나 겹치지 않는가
- [ ] 색상/폰트가 일관적인가 (중구난방이 아닌가)
- [ ] "AI가 만든 티"가 나는가 (흰색 카드 + 보라색 그라데이션 같은 AI slop 패턴)

### 코드 품질 (20%)
- [ ] 콘솔에 에러가 없는가
- [ ] TypeScript 컴파일 에러가 없는가
- [ ] React hydration 에러가 없는가

### 완성도 (15%)
- [ ] 데이터가 없을 때 Empty 상태가 표시되는가
- [ ] 로딩 중 Loading 상태가 표시되는가
- [ ] 에러 발생 시 Error 상태가 표시되는가 (흰 화면이 아닌가)
- [ ] 404 페이지가 있는가

## contract.md가 있을 때

contract.md의 각 항목을 **순서대로** 검증한다:
1. 항목의 "검증 방법"을 읽는다
2. Playwright MCP로 해당 동작을 수행한다
3. 기대 결과와 비교한다
4. Pass/Fail + 스크린샷으로 기록한다

## 점수 산출 규칙

각 축의 점수:
- 해당 축의 체크리스트 항목 중 Pass 개수 / 전체 항목 수 × 100
- Critical 이슈(앱 크래시, 핵심 기능 불능)가 있는 축: 최대 50점 캡

## 주의사항

- `waitForTimeout` 사용 금지. 항상 `waitForResponse`, `waitForURL`, 또는 요소 대기 사용
- 스크린샷 없는 판정은 증거 불충분. 주요 결과마다 스크린샷 캡처
- 앱이 시작 안 되면 기능성 0점 + 즉시 FAIL 보고
- 후하게 채점하지 마라. "대충 돌아가면 OK"가 아니라 기준에 맞는지 엄격하게
