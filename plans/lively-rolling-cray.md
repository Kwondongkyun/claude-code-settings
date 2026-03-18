# repository.py .in_() 파라미터 한계 초과 수정

## Context
PostgreSQL은 쿼리당 최대 65,535개의 파라미터를 허용하는데, 수만 개의 항목을 `.in_()` 에 넣어 이 한계를 초과함.
1,000개씩 청크로 나눠 여러 번 쿼리하도록 수정.

## 문제 위치 (app/repository.py)
- line 85: `OrderPlan.order_plan_unty_no.in_(unty_nos)` - bulk_upsert
- line 160: `BidNotice.bid_ntce_no.in_(bid_ntce_nos)` - find_existing_bid_ntce_nos
- line 188: `BidNotice.bid_ntce_no.in_(bid_nos)` - bulk_save

## 수정 방법
CHUNK_SIZE = 1000 으로 리스트를 나눠 반복 쿼리 후 결과 합산

### 1. bulk_upsert (line 82~90)
```python
CHUNK_SIZE = 1000
existing_plans = {}
for i in range(0, len(unty_nos), CHUNK_SIZE):
    chunk = unty_nos[i:i + CHUNK_SIZE]
    statement = select(OrderPlan).where(OrderPlan.order_plan_unty_no.in_(chunk))
    for plan in self.session.exec(statement).all():
        existing_plans[plan.order_plan_unty_no] = plan
```

### 2. find_existing_bid_ntce_nos (line 155~162)
```python
CHUNK_SIZE = 1000
existing = set()
for i in range(0, len(bid_ntce_nos), CHUNK_SIZE):
    chunk = bid_ntce_nos[i:i + CHUNK_SIZE]
    statement = select(BidNotice.bid_ntce_no).where(BidNotice.bid_ntce_no.in_(chunk))
    existing.update(self.session.exec(statement).all())
return existing
```

### 3. bulk_save (line 185~190)
```python
CHUNK_SIZE = 1000
existing_nos = set()
for i in range(0, len(bid_nos), CHUNK_SIZE):
    chunk = bid_nos[i:i + CHUNK_SIZE]
    statement = select(BidNotice.bid_ntce_no).where(BidNotice.bid_ntce_no.in_(chunk))
    existing_nos.update(self.session.exec(statement).all())
```

## 수정 파일
- `app/repository.py`

## 검증
EC2에서 데이터 수집 실행 후 에러 없이 완료되는지 확인
