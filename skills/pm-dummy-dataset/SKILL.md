---
name: pm-dummy-dataset
description: spec.md 기반으로 현실적인 테스트 데이터를 TypeScript 목 데이터와 SQL seed로 동시 생성한다. Foundation 단계에서 DB 시딩에 사용.
effort: high
allowed-tools: Read, Glob, Grep, Write, Bash
---

# 더미 데이터셋 생성

spec.md의 엔티티/데이터 모델을 분석하여 현실적인 시드 데이터를 생성한다.

## 입력

spec.md를 읽고 다음을 추출한다:
- Part 1 > 기능 요구사항의 엔티티/데이터 필드
- Part 1 > 화면별 상태 정의 (Default, Empty 상태에 필요한 데이터)
- Part 1 > 엣지케이스 (경계값 테스트용 데이터)
- Part 1 > 비기능 요구사항 (데이터 제약사항)

spec.md 경로가 주어지지 않으면 `docs/specs/` 하위 폴더에서 선택한다.

## 데이터 생성 원칙

### 현실성
- 한국어 이름/주소/전화번호 사용
- 실제 서비스에서 나올 법한 데이터 패턴
- 날짜는 현재 기준 상대적 (최근 1년 이내)
- 이메일은 `user1@example.com` 형식 (실제 도메인 사용 금지)

### 커버리지

각 엔티티에 대해 다음 데이터를 반드시 포함한다. 리스트/테이블이 보통 5~10행을 한 화면에 표시하므로, 정상 데이터는 스크롤/페이지네이션 테스트가 가능한 10~20건이 적절. edge/empty는 해당 상태를 재현하기 위한 최소 건수.

| 유형 | 건수 | 용도 | `_tag` |
|------|------|------|--------|
| 정상 데이터 | 10~20건 | Default 상태 렌더링 | `normal` |
| 경계값 데이터 | 2~3건 | 최대 길이, 최소값, 특수문자 | `edge` |
| 빈 데이터 세트 | 1건 | Empty 상태 테스트 (선택적 필드 전부 null) | `empty` |
| 에러 유발 데이터 | 2~3건 | 유효성 검사 테스트 | `error` |

### ID 규칙
- UUID v4 사용 (하드코딩된 고정값으로 — 랜덤 생성 아님)
- 관계형 데이터 간 FK 정합성 보장
- 부모 테이블 데이터를 먼저 정의

### enum/상태값
- spec.md에 정의된 값만 사용
- 모든 enum 값이 최소 1건씩 포함되도록

## 출력 형식

### 1. TypeScript 목 데이터

파일: `docs/specs/[기능명]/seed-data.ts`

```typescript
// Auto-generated from spec.md — 수동 수정 금지
// 생성일: YYYY-MM-DD

export interface [엔티티]Seed {
  id: string;
  // ... spec.md에서 추출한 필드
  _tag: 'normal' | 'edge' | 'empty' | 'error';
}

export const [엔티티]Seeds: [엔티티]Seed[] = [
  {
    id: '550e8400-e29b-41d4-a716-446655440001',
    // ... 필드값
    _tag: 'normal',
  },
  // ...
];
```

**TypeScript 규칙:**
- `_tag` 필드로 데이터 유형 구분 (필터링용)
- interface를 먼저 정의하고 데이터 배열 작성
- 날짜는 ISO 8601 문자열
- 관계 ID는 다른 엔티티의 실제 seed ID 참조

### 2. SQL seed 데이터

파일: `docs/specs/[기능명]/seed-data.sql`

```sql
-- Auto-generated from spec.md — 수동 수정 금지
-- 생성일: YYYY-MM-DD
-- 실행 대상: Supabase PostgreSQL

-- 순서: 부모 테이블 → 자식 테이블 (FK 의존성)

INSERT INTO [테이블명] (id, ...) VALUES
  ('550e8400-e29b-41d4-a716-446655440001', ...),
  ('550e8400-e29b-41d4-a716-446655440002', ...);
```

**SQL 규칙:**
- 부모 테이블 INSERT가 자식보다 먼저
- TypeScript seed와 동일한 ID/값 사용 (정합성)
- `_tag` 컬럼은 SQL에 포함하지 않음 (개발용 메타데이터)
- 한 테이블당 하나의 INSERT문 (VALUES 여러 행)

## 프로세스

1. spec.md 읽기 → 엔티티, 필드, 관계, 제약조건 추출
2. 엔티티 간 의존성 그래프 파악 (FK 관계)
3. 부모 → 자식 순서로 시드 데이터 생성
4. TypeScript 파일과 SQL 파일 동시 작성
5. 생성 요약 출력:
   - 엔티티 수, 총 레코드 수
   - 각 엔티티별 normal/edge/empty/error 건수
   - FK 참조 관계 다이어그램 (텍스트)
