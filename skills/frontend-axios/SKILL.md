---
name: frontend-axios
description: Use when setting up API calls or configuring HTTP client. Defines Axios instance with interceptors, API function patterns in features folder, and 3-tier error handling structure.
allowed-tools: Read, Write, Edit, Glob, Grep
---

# Axios 사용 패턴

## 1. Axios 인스턴스 설정 (lib/api/axios.ts)
```typescript
import axios, { type AxiosInstance } from 'axios';

const BASE_URL = process.env.NEXT_PUBLIC_API_URL || '';

export const api: AxiosInstance = axios.create({
  baseURL: BASE_URL,
  timeout: 30000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// 요청 인터셉터 (SSR 가드 + 토큰 추가)
api.interceptors.request.use((config) => {
  if (typeof window !== 'undefined') {
    const token = localStorage.getItem('access_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
  }
  return config;
});

// 응답 인터셉터 (Refresh Token 자동 갱신)
let isRefreshing = false;
let failedQueue: Array<{
  resolve: (token: string) => void;
  reject: (error: unknown) => void;
}> = [];

function processQueue(error: unknown, token: string | null) {
  failedQueue.forEach((promise) => {
    if (token) {
      promise.resolve(token);
    } else {
      promise.reject(error);
    }
  });
  failedQueue = [];
}

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const originalRequest = error.config;

    if (
      error.response?.status === 401 &&
      !originalRequest._retry &&
      !originalRequest.url?.includes('/auth/refresh') &&
      !originalRequest.url?.includes('/auth/login')
    ) {
      if (isRefreshing) {
        return new Promise((resolve, reject) => {
          failedQueue.push({
            resolve: (token: string) => {
              originalRequest.headers.Authorization = `Bearer ${token}`;
              resolve(api(originalRequest));
            },
            reject,
          });
        });
      }

      originalRequest._retry = true;
      isRefreshing = true;

      const refreshToken = localStorage.getItem('refresh_token');
      if (!refreshToken) {
        isRefreshing = false;
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        return Promise.reject(error);
      }

      try {
        const response = await axios.post(
          `${BASE_URL}/api/v1/auth/refresh`,
          { refresh_token: refreshToken },
        );
        const { access_token, refresh_token } = response.data.result;
        localStorage.setItem('access_token', access_token);
        localStorage.setItem('refresh_token', refresh_token);
        processQueue(null, access_token);
        originalRequest.headers.Authorization = `Bearer ${access_token}`;
        return api(originalRequest);
      } catch (refreshError) {
        processQueue(refreshError, null);
        localStorage.removeItem('access_token');
        localStorage.removeItem('refresh_token');
        return Promise.reject(refreshError);
      } finally {
        isRefreshing = false;
      }
    }

    return Promise.reject(error);
  },
);
```

## 2. API 함수 작성 (features/[domain]/[feature]/api.ts)
```typescript
import { api } from '@/lib/api/axios';
import type { MeResponse, CreateUserRequest } from './types';

// 패턴: [동사][명사]Api
export async function getMeApi(): Promise<MeResponse> {
  const response = await api.get<MeResponse>('/api/v1/members/me');
  return response.data;
}

export async function createUserApi(data: CreateUserRequest) {
  const response = await api.post('/api/v1/users', data);
  return response.data;
}

export async function deleteUserApi(userId: string): Promise<void> {
  await api.delete(`/api/v1/users/${userId}`);
}
```

## 3. 타입 정의 (features/[domain]/[feature]/types.ts)
```typescript
import type { BaseResponse } from '@/features/shared/response';

// API 요청 타입
export interface CreateUserRequest {
  name: string;
  email: string;
  password: string;
}

// API 응답 타입
export interface UserItem {
  id: string;
  name: string;
  email: string;
  createdAt: string;
}

export interface MeResponse extends BaseResponse<UserItem> {}
```

## 4. 공통 응답 타입 (features/shared/response.ts)
```typescript
export interface BaseResponse<T> {
  success: boolean;
  result: T;
}
```

## 에러 핸들링 (3단계 구조)

### 1단계: Interceptor - 전역 에러 처리
```typescript
// lib/api/axios.ts에서 처리
- 401: refresh token 시도 → 실패 시 토큰 제거
- refresh/login 요청은 retry 제외
```

### 2단계: API 함수 - 특정 에러 처리
```typescript
// features/user/api.ts
export async function getUserProfileApi(userId: string) {
  try {
    const { data } = await api.get(`/users/${userId}`);
    return { data, error: null };
  } catch (error) {
    if (axios.isAxiosError(error) && error.response?.status === 404) {
      return { data: null, error: '사용자를 찾을 수 없습니다' };
    }
    return { data: null, error: '알 수 없는 오류' };
  }
}
```

### 3단계: 컴포넌트 - UI 피드백
```typescript
// components/user/UserProfile/index.tsx
const { data, error } = await getUserProfileApi(userId);

if (error) return <ErrorMessage message={error} />;
return <div>{data.name}</div>;
```

## 에러별 처리 위치

| 에러 종류 | 처리 위치 | 이유 |
|----------|----------|------|
| 401 (인증 만료) | Interceptor | refresh token 자동 갱신 |
| 404 (특정 리소스) | API 함수 | 상황별 메시지 |
| 폼 검증 에러 | 컴포넌트 | 필드별 UI 피드백 |
