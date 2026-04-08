# shadcn/ui 컴포넌트 매핑

## UI 라이브러리 우선순위

1. **Shadcn UI** - 기본 UI 컴포넌트
2. **Kibo UI** - 고급 복합 컴포넌트
3. **Radix UI** - 접근성 기반 원시 컴포넌트
4. **Lucide Icons** - 아이콘 시스템

> shadcn/ui 컴포넌트 목록: https://ui.shadcn.com/docs/components

## HTML 태그 → shadcn/ui 대체

```typescript
// ✅ Good: shadcn/ui 컴포넌트
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';

<Button onClick={handleClick}>저장</Button>
<Input placeholder="이름 입력" value={name} onChange={handleChange} />

// ❌ Bad: shadcn/ui에 있는데 HTML 태그 직접 사용
<button onClick={handleClick}>저장</button>
<input placeholder="이름 입력" value={name} onChange={handleChange} />
```

### 자주 사용하는 HTML 태그 대체

| HTML 태그 | shadcn/ui 컴포넌트 |
|-----------|-------------------|
| `<button>` | `<Button>` |
| `<input>` | `<Input>` |
| `<textarea>` | `<Textarea>` |
| `<select>` | `<Select>` |
| `<table>` | `<Table>` |
| `<input type="checkbox">` | `<Checkbox>` |
| `<hr>` | `<Separator>` |

### UI 패턴 → shadcn/ui 컴포넌트 매핑

| UI 패턴 | shadcn/ui 컴포넌트 | 비고 |
|---------|-------------------|------|
| 모달/팝업 | `Dialog` | `AlertDialog`는 확인/취소용 |
| 토스트/알림 | `Sonner` 또는 `Toast` | |
| 드롭다운 메뉴 | `DropdownMenu` | 우클릭 메뉴도 포함 |
| 툴팁 | `Tooltip` | |
| 탭 | `Tabs` | |
| 아코디언/접기 | `Accordion` / `Collapsible` | |
| 사이드 패널 | `Sheet` | 슬라이드 아웃 |
| 팝오버 | `Popover` | |
| 날짜 선택 | `Calendar` + `Popover` | |
| 자동완성/콤보박스 | `Command` + `Popover` | |
| 로딩 스켈레톤 | `Skeleton` | |
| 뱃지/태그 | `Badge` | |
| 프로그레스 바 | `Progress` | |

위 표는 대표 예시일 뿐이다. shadcn/ui에서 제공하는 모든 컴포넌트를 우선 사용한다.

### HTML 태그 허용 케이스
- shadcn/ui에 대응 컴포넌트가 없는 경우
- `<form>`, `<fieldset>`, `<legend>` 등 시맨틱 폼 구조 태그
