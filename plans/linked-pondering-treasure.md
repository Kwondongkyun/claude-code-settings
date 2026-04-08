# 하네스 엔지니어링 v2 문서화 계획

## Context

기존 "Harness Engineering 연구 노트" (3/5)는 Ralph Loop + Open/Closed-loop 실험 중심.
이번 세션에서 Anthropic 블로그 기반으로 6축 평가 + 4개 Gap 구현.
별도 연구 문서로 정리한다.

## 생성 파일

- 폴더: `Harness Engineering — 멀티에이전트 하네스 설계/`
- 파일: `harness-multi-agent-design_2026-03-30.md`

## 문서 구조

```
Part 1: 하네스 엔지니어링이란
  - 정의: AI 모델을 감싸는 운영 구조
  - Claude Code에서 하네스를 구성하는 요소들
    (agents, skills, commands, hooks, templates, scripts, CLAUDE.md)
  - Anthropic이 제시한 6축
  - 하네스를 만들고 관리하는 방법론

Part 2: Anthropic의 하네스 설계 사례
  - 2가지 핵심 문제 (Context Anxiety + 자기 평가 한계)
  - 디자인 실험 (Generator/Evaluator + 채점 기준표 + 네덜란드 미술관)
  - 풀스택 앱 (3인 체제 + Sprint Contract + Solo vs 3-Agent 비교)
  - 모델 진화에 따른 하네스 재설계 (Opus 4.5→4.6)

Part 3: 내 하네스 현황 + 평가 (6축)
  - 현황: 에이전트 6개, 스킬 40+, 커맨드 7개, 훅 5개, 프로세스 Phase 0~8
  - 평가: 6축 기준으로 채점 + 강점/Gap 도출

Part 4: Gap 개선 — 무엇을 만들었나
  - Gap 2: evaluator (Playwright + 4축 가중 채점)
  - Gap 1: handoff.md (구조화된 인수인계)
  - Gap 3: stall-detector + /pivot-check (방향 전환)
  - Gap 5: /sprint-contract (합격 기준 합의)

Part 5: 업데이트된 프로세스 (Phase 0~8 + 에이전트/스킬 매핑)

핵심 인사이트
```

## 소스

- Anthropic 원문 블로그 WebFetch 내용 (대화 내 보유)
- LinkedIn 번역 글 (사용자 제공 본문)
- 이번 세션 대화 내용 (평가, 구현, 프로세스 업데이트)
- 기존 연구 노트 (교차 참조)

## Notion 동기화

완성 후 Notion "재밌는거" 페이지 하위에 생성 (ID: 3142156c-eb5f-80cb-bcef-eb2f9595fe77)

## 검증

- 템플릿 형식: `# 제목 — 부제` → `> 최종 수정` → `## TL;DR` → `## Part N:` → `## 핵심 인사이트`
- 파일명: `slug_YYYY-MM-DD.md`
- Notion 동기화 확인
