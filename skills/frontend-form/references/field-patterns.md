# 복합 필드 패턴

## Select

```typescript
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from '@/components/ui/select';

<FormField
  control={form.control}
  name="role"
  render={({ field }) => (
    <FormItem>
      <FormLabel>역할</FormLabel>
      <Select onValueChange={field.onChange} defaultValue={field.value}>
        <FormControl>
          <SelectTrigger>
            <SelectValue placeholder="역할을 선택해주세요" />
          </SelectTrigger>
        </FormControl>
        <SelectContent>
          <SelectItem value="admin">관리자</SelectItem>
          <SelectItem value="user">사용자</SelectItem>
        </SelectContent>
      </Select>
      <FormMessage />
    </FormItem>
  )}
/>
```

## Checkbox

```typescript
import { Checkbox } from '@/components/ui/checkbox';

<FormField
  control={form.control}
  name="agreeTerms"
  render={({ field }) => (
    <FormItem className="flex items-center gap-2">
      <FormControl>
        <Checkbox
          checked={field.value}
          onCheckedChange={field.onChange}
        />
      </FormControl>
      <FormLabel className="!mt-0">이용약관에 동의합니다</FormLabel>
      <FormMessage />
    </FormItem>
  )}
/>
```

## 수정 폼 (기존 데이터 편집)

```typescript
const form = useForm<FormValues>({
  resolver: zodResolver(schema),
  defaultValues: {
    name: user?.name ?? '',
    email: user?.email ?? '',
  },
});

// 비동기로 데이터 로드 후 reset
useEffect(() => {
  if (user) {
    form.reset(user);
  }
}, [user, form]);
```
