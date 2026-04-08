# 메모이제이션 사용 기준

기본 원칙: **메모이제이션은 꼭 필요한 경우에만 사용한다.** 무분별한 사용은 코드 복잡도만 높이고 성능 이점이 없다.

## memo - 사용해야 하는 경우
```typescript
// ✅ 무거운 컴포넌트 + 부모가 자주 리렌더링될 때
export const HeavyList = memo(function HeavyList({ items }: Props) {
  return items.map((item) => <ComplexCard key={item.id} data={item} />);
});
```

사용 조건 (모두 충족해야 함):
- 자식 컴포넌트의 렌더링 비용이 큼 (리스트, 차트, 복잡한 UI)
- 부모가 자주 리렌더링됨
- 전달되는 props가 실제로 자주 변경되지 않음

## useCallback - 사용해야 하는 경우
```typescript
// ✅ memo로 감싼 자식에게 전달하는 콜백
const handleClick = useCallback((id: string) => {
  setSelectedId(id);
}, []);

<MemoizedChild onClick={handleClick} />

// ❌ memo로 감싸지 않은 자식에게는 불필요
const handleClick = useCallback(() => { ... }, []); // 의미 없음
<NormalChild onClick={handleClick} />
```

## useMemo - 사용해야 하는 경우
```typescript
// ✅ 비용이 큰 계산 (정렬, 필터, reduce 등)
const sorted = useMemo(
  () => [...items].sort((a, b) => b.price - a.price),
  [items]
);

// ✅ memo로 감싼 자식에게 전달하는 객체/배열
const config = useMemo(() => ({ page, keyword }), [page, keyword]);
<MemoizedChild config={config} />

// ❌ 단순 계산에는 불필요
const total = useMemo(() => a + b, [a, b]); // 오버헤드만 추가
```

## 사용 금지 케이스
```typescript
// ❌ 단순 값 계산
const fullName = useMemo(() => `${first} ${last}`, [first, last]);

// ❌ deps가 매번 바뀌는 useCallback (메모이제이션 효과 없음)
const handleClick = useCallback(() => {
  doSomething(obj);
}, [obj]); // obj가 매 렌더마다 새로 생성되면 무의미

// ❌ 가벼운 컴포넌트에 memo
export const Label = memo(function Label({ text }: Props) {
  return <span>{text}</span>; // 렌더링 비용이 거의 없음
});
```
