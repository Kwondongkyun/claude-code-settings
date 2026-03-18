# 영업 고객 페르소나 에이전트 Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 영업팀이 고객 AI 페르소나를 생성하고 Claude와 대화하는 Electron 데스크탑 앱 구축

**Architecture:** Electron(Main Process) + React+TailwindCSS(Renderer Process) 2-process 구조.
Main process에서 better-sqlite3로 페르소나 데이터 관리, Anthropic SDK로 Claude API 스트리밍 호출.
IPC(contextBridge)로 프로세스 간 통신. Zustand로 Renderer 상태 관리.

**Tech Stack:** Electron + electron-vite + React + TypeScript + TailwindCSS + better-sqlite3 + @anthropic-ai/sdk + Zustand + Vitest

**Project Root:** `/Users/kwondong-kyun/projects/sales-persona-agent/`

---

## 목표 폴더 구조

```
sales-persona-agent/
├── src/
│   ├── shared/
│   │   └── types.ts                  # 공유 타입 + IPC 채널 상수
│   ├── main/
│   │   ├── index.ts                  # Electron 진입점
│   │   ├── db/
│   │   │   ├── database.ts           # SQLite 초기화 + 마이그레이션
│   │   │   └── repositories/
│   │   │       └── personaRepository.ts
│   │   ├── ipc/
│   │   │   ├── handlers.ts           # 핸들러 등록 entry
│   │   │   ├── personaHandlers.ts
│   │   │   ├── chatHandlers.ts
│   │   │   └── settingsHandlers.ts
│   │   └── services/
│   │       ├── claudeService.ts      # Anthropic SDK 래퍼 + system prompt 생성
│   │       └── settingsService.ts    # safeStorage 래퍼
│   ├── preload/
│   │   └── index.ts                  # contextBridge API 노출
│   └── renderer/src/
│       ├── App.tsx
│       ├── env.d.ts                  # window.api 타입 선언
│       ├── store/appStore.ts         # Zustand
│       ├── hooks/
│       │   ├── usePersonas.ts
│       │   └── useChat.ts
│       └── components/
│           ├── layout/MainLayout.tsx
│           ├── persona/
│           │   ├── PersonaList.tsx
│           │   ├── PersonaListItem.tsx
│           │   ├── PersonaForm.tsx
│           │   └── PersonaDetail.tsx
│           ├── chat/
│           │   ├── ChatWindow.tsx
│           │   ├── MessageBubble.tsx
│           │   └── ChatInput.tsx
│           └── settings/
│               └── SettingsModal.tsx
├── __tests__/
│   ├── setup.ts
│   └── main/db/personaRepository.test.ts
├── electron.vite.config.ts
├── vitest.config.ts
└── tailwind.config.js
```

---

## Task 1: 프로젝트 초기화

**Files:** `package.json`, `electron.vite.config.ts`, `vitest.config.ts`, `tailwind.config.js`

**Step 1:** electron-vite 보일러플레이트 생성
```bash
cd /Users/kwondong-kyun/projects/sales-persona-agent
npm create @quick-start/electron@latest . -- --template react-ts
npm install
```

**Step 2:** 추가 의존성 설치
```bash
npm install better-sqlite3 @anthropic-ai/sdk zustand
npm install -D tailwindcss postcss autoprefixer @types/better-sqlite3 \
  vitest @vitest/coverage-v8 @testing-library/react \
  @testing-library/user-event @testing-library/jest-dom happy-dom
npx tailwindcss init -p
```

**Step 3:** `vitest.config.ts` 작성
```typescript
import { defineConfig } from 'vitest/config'
import react from '@vitejs/plugin-react'
import { resolve } from 'path'

export default defineConfig({
  plugins: [react()],
  test: {
    environment: 'happy-dom',
    globals: true,
    setupFiles: './__tests__/setup.ts',
  },
  resolve: {
    alias: { '@renderer': resolve(__dirname, 'src/renderer/src') },
  },
})
```

**Step 4:** `__tests__/setup.ts` — Electron IPC mock
```typescript
import '@testing-library/jest-dom'
vi.mock('electron', () => ({
  ipcRenderer: { invoke: vi.fn(), on: vi.fn(), removeAllListeners: vi.fn() },
}))
```

**Step 5:** `tailwind.config.js` content 경로 설정
```js
export default {
  content: ['./src/renderer/**/*.{html,js,ts,jsx,tsx}'],
  theme: { extend: {} },
  plugins: [],
}
```

**Step 6:** 커밋
```bash
git add . && git commit -m "chore: init electron-vite + TailwindCSS + Vitest"
```

---

## Task 2: 공유 타입 정의

**Files:** Create `src/shared/types.ts`

**Step 1:** 타입 및 IPC 채널 상수 작성
```typescript
export interface Persona {
  id: string
  name: string
  company: string
  position: string
  contact: string
  commStyle: string
  salesHistory: string
  needs: string
  objectionPattern: string
  decisionStructure: string
  relationshipNotes: string
  createdAt: number
  updatedAt: number
}

export type PersonaCreateInput = Omit<Persona, 'id' | 'createdAt' | 'updatedAt'>
export type PersonaUpdateInput = Partial<PersonaCreateInput> & { id: string }

export interface Message {
  id: string
  role: 'user' | 'assistant'
  content: string
  timestamp: number
}

export const IPC_CHANNELS = {
  PERSONA: {
    LIST: 'persona:list', GET: 'persona:get',
    CREATE: 'persona:create', UPDATE: 'persona:update', DELETE: 'persona:delete',
  },
  CHAT: {
    SEND: 'chat:send',
    STREAM_CHUNK: 'chat:stream-chunk',
    STREAM_END: 'chat:stream-end',
    STREAM_ERROR: 'chat:stream-error',
  },
  SETTINGS: {
    GET_API_KEY: 'settings:get-api-key',
    SET_API_KEY: 'settings:set-api-key',
    HAS_API_KEY: 'settings:has-api-key',
  },
} as const
```

**Step 2:** 커밋
```bash
git add . && git commit -m "feat: add shared types and IPC channel constants"
```

---

## Task 3: SQLite 레이어 (TDD)

**Files:**
- Create: `src/main/db/database.ts`
- Create: `src/main/db/repositories/personaRepository.ts`
- Test: `__tests__/main/db/personaRepository.test.ts`

**Step 1:** failing test 작성 (`__tests__/main/db/personaRepository.test.ts`)
```typescript
import { describe, it, expect, beforeEach, afterEach } from 'vitest'
import Database from 'better-sqlite3'
import { PersonaRepository } from '../../../src/main/db/repositories/personaRepository'

const CREATE_TABLE_SQL = `
  CREATE TABLE IF NOT EXISTS personas (
    id TEXT PRIMARY KEY, name TEXT NOT NULL,
    company TEXT NOT NULL DEFAULT '', position TEXT NOT NULL DEFAULT '',
    contact TEXT NOT NULL DEFAULT '', comm_style TEXT NOT NULL DEFAULT '',
    sales_history TEXT NOT NULL DEFAULT '', needs TEXT NOT NULL DEFAULT '',
    objection_pattern TEXT NOT NULL DEFAULT '',
    decision_structure TEXT NOT NULL DEFAULT '',
    relationship_notes TEXT NOT NULL DEFAULT '',
    created_at INTEGER NOT NULL, updated_at INTEGER NOT NULL
  )`

describe('PersonaRepository', () => {
  let db: Database.Database
  let repo: PersonaRepository

  beforeEach(() => {
    db = new Database(':memory:')
    db.prepare(CREATE_TABLE_SQL).run()   // better-sqlite3 DDL via prepare+run
    repo = new PersonaRepository(db)
  })
  afterEach(() => db.close())

  it('빈 DB에서 list()는 빈 배열 반환', () => {
    expect(repo.list()).toEqual([])
  })

  it('create() 후 list()에서 조회 가능', () => {
    const created = repo.create({
      name: '김철수', company: 'ABC', position: 'CTO', contact: '',
      commStyle: '', salesHistory: '', needs: '',
      objectionPattern: '', decisionStructure: '', relationshipNotes: '',
    })
    expect(created.id).toBeTruthy()
    expect(repo.list()).toHaveLength(1)
  })

  it('update() 후 변경사항 반영', () => {
    const created = repo.create({
      name: '이영희', company: 'XYZ', position: 'PM', contact: '',
      commStyle: '', salesHistory: '', needs: '',
      objectionPattern: '', decisionStructure: '', relationshipNotes: '',
    })
    const updated = repo.update({ id: created.id, company: 'NewCorp' })
    expect(updated?.company).toBe('NewCorp')
    expect(updated?.name).toBe('이영희')
  })

  it('delete() 후 list()에서 제거', () => {
    const created = repo.create({
      name: '박민준', company: '', position: '', contact: '',
      commStyle: '', salesHistory: '', needs: '',
      objectionPattern: '', decisionStructure: '', relationshipNotes: '',
    })
    repo.delete(created.id)
    expect(repo.list()).toHaveLength(0)
  })
})
```

**Step 2:** test 실행 → FAIL 확인
```bash
npm test -- personaRepository
# Expected: FAIL (PersonaRepository not found)
```

**Step 3:** `database.ts` 구현 (better-sqlite3 WAL mode + 마이그레이션)

- `app.getPath('userData')` 경로에 `sales-persona.db` 파일 생성
- `pragma('journal_mode = WAL')` 설정
- `_migrations` 테이블로 버전 관리
- personas 테이블 DDL: `db.prepare(sql).run()` 패턴 사용 (shell과 무관한 SQLite API)

**Step 4:** `personaRepository.ts` 구현
```typescript
import Database from 'better-sqlite3'
import { randomUUID } from 'crypto'
import type { Persona, PersonaCreateInput, PersonaUpdateInput } from '../../../shared/types'

// SQLite row → Persona (snake_case → camelCase)
function rowToPersona(row: Record<string, unknown>): Persona {
  return {
    id: row.id as string,
    name: row.name as string,
    company: row.company as string,
    position: row.position as string,
    contact: row.contact as string,
    commStyle: row.comm_style as string,
    salesHistory: row.sales_history as string,
    needs: row.needs as string,
    objectionPattern: row.objection_pattern as string,
    decisionStructure: row.decision_structure as string,
    relationshipNotes: row.relationship_notes as string,
    createdAt: row.created_at as number,
    updatedAt: row.updated_at as number,
  }
}

export class PersonaRepository {
  constructor(private db: Database.Database) {}

  list(): Persona[] {
    return (
      this.db
        .prepare('SELECT * FROM personas ORDER BY updated_at DESC')
        .all() as Record<string, unknown>[]
    ).map(rowToPersona)
  }

  getById(id: string): Persona | undefined {
    const row = this.db
      .prepare('SELECT * FROM personas WHERE id = ?')
      .get(id) as Record<string, unknown> | undefined
    return row ? rowToPersona(row) : undefined
  }

  create(input: PersonaCreateInput): Persona {
    const now = Date.now()
    const id = randomUUID()
    this.db
      .prepare(`
        INSERT INTO personas (
          id, name, company, position, contact,
          comm_style, sales_history, needs,
          objection_pattern, decision_structure,
          relationship_notes, created_at, updated_at
        ) VALUES (
          @id, @name, @company, @position, @contact,
          @commStyle, @salesHistory, @needs,
          @objectionPattern, @decisionStructure,
          @relationshipNotes, @createdAt, @updatedAt
        )
      `)
      .run({ id, ...input, createdAt: now, updatedAt: now })
    return this.getById(id)!
  }

  update(input: PersonaUpdateInput): Persona | undefined {
    const existing = this.getById(input.id)
    if (!existing) return undefined
    const merged = { ...existing, ...input, updatedAt: Date.now() }
    this.db
      .prepare(`
        UPDATE personas SET
          name=@name, company=@company, position=@position,
          contact=@contact, comm_style=@commStyle,
          sales_history=@salesHistory, needs=@needs,
          objection_pattern=@objectionPattern,
          decision_structure=@decisionStructure,
          relationship_notes=@relationshipNotes,
          updated_at=@updatedAt
        WHERE id=@id
      `)
      .run(merged)
    return this.getById(input.id)
  }

  delete(id: string): boolean {
    return this.db.prepare('DELETE FROM personas WHERE id = ?').run(id).changes > 0
  }
}
```

**Step 5:** test 실행 → PASS 확인
```bash
npm test -- personaRepository
# Expected: PASS (4 tests)
```

**Step 6:** 커밋
```bash
git add . && git commit -m "feat: implement PersonaRepository with SQLite (TDD)"
```

---

## Task 4: Main Process 서비스 + IPC 핸들러

**Files:**
- Create: `src/main/services/settingsService.ts`
- Create: `src/main/services/claudeService.ts`
- Create: `src/main/ipc/personaHandlers.ts`
- Create: `src/main/ipc/chatHandlers.ts`
- Create: `src/main/ipc/settingsHandlers.ts`
- Create: `src/main/ipc/handlers.ts`
- Modify: `src/preload/index.ts`
- Modify: `src/main/index.ts`

**Step 1:** `settingsService.ts` — API 키 암호화 저장
```typescript
import { safeStorage } from 'electron'
import { app } from 'electron'
import path from 'path'
import fs from 'fs'

const keyFile = () => path.join(app.getPath('userData'), 'api-key.enc')

export const settingsService = {
  setApiKey(key: string): void {
    const encrypted = safeStorage.encryptString(key)
    fs.writeFileSync(keyFile(), encrypted)
  },
  getApiKey(): string | null {
    const kf = keyFile()
    if (!fs.existsSync(kf)) return null
    return safeStorage.decryptString(Buffer.from(fs.readFileSync(kf)))
  },
  hasApiKey(): boolean {
    return fs.existsSync(keyFile())
  },
}
```

**Step 2:** `claudeService.ts` — system prompt 자동 생성 + 스트리밍
```typescript
import Anthropic from '@anthropic-ai/sdk'
import type { Persona, Message } from '../../../shared/types'

export function buildSystemPrompt(persona: Persona): string {
  return `당신은 영업 미팅 시뮬레이션을 위한 고객 페르소나입니다.
아래 정보를 바탕으로 이 고객처럼 자연스럽게 대화해주세요.

## 기본 프로필
이름: ${persona.name} / 회사: ${persona.company} / 직책: ${persona.position}

## 커뮤니케이션 스타일
${persona.commStyle || '(정보 없음)'}

## 영업 히스토리
${persona.salesHistory || '(정보 없음)'}

## 구매 패턴 / 니즈
${persona.needs || '(정보 없음)'}

## 반대 패턴
${persona.objectionPattern || '(정보 없음)'}

## 의사결정 구조
${persona.decisionStructure || '(정보 없음)'}

## 관계 메모
${persona.relationshipNotes || '(정보 없음)'}

이 고객의 성격, 말투, 관심사를 유지하며 현실적으로 대화하세요.`
}

export async function* streamChat(
  apiKey: string,
  persona: Persona,
  messages: Message[]
): AsyncGenerator<string> {
  const client = new Anthropic({ apiKey })
  const stream = await client.messages.stream({
    model: 'claude-opus-4-6',
    max_tokens: 1024,
    system: buildSystemPrompt(persona),
    messages: messages.map((m) => ({ role: m.role, content: m.content })),
  })
  for await (const chunk of stream) {
    if (chunk.type === 'content_block_delta' && chunk.delta.type === 'text_delta') {
      yield chunk.delta.text
    }
  }
}
```

**Step 3:** IPC 핸들러 3개 작성

`personaHandlers.ts`:
```typescript
import { ipcMain } from 'electron'
import { IPC_CHANNELS } from '../../../shared/types'
import { getDatabase } from '../db/database'
import { PersonaRepository } from '../db/repositories/personaRepository'

const getRepo = () => new PersonaRepository(getDatabase())

export function registerPersonaHandlers(): void {
  ipcMain.handle(IPC_CHANNELS.PERSONA.LIST,   () => getRepo().list())
  ipcMain.handle(IPC_CHANNELS.PERSONA.GET,    (_, id) => getRepo().getById(id))
  ipcMain.handle(IPC_CHANNELS.PERSONA.CREATE, (_, input) => getRepo().create(input))
  ipcMain.handle(IPC_CHANNELS.PERSONA.UPDATE, (_, input) => getRepo().update(input))
  ipcMain.handle(IPC_CHANNELS.PERSONA.DELETE, (_, id) => getRepo().delete(id))
}
```

`chatHandlers.ts`:
```typescript
import { ipcMain, BrowserWindow } from 'electron'
import { IPC_CHANNELS } from '../../../shared/types'
import { streamChat } from '../services/claudeService'
import { settingsService } from '../services/settingsService'
import { getDatabase } from '../db/database'
import { PersonaRepository } from '../db/repositories/personaRepository'

export function registerChatHandlers(): void {
  ipcMain.handle(IPC_CHANNELS.CHAT.SEND, async (event, { personaId, messages }) => {
    const apiKey = settingsService.getApiKey()
    if (!apiKey) throw new Error('API 키가 설정되지 않았습니다.')
    const persona = new PersonaRepository(getDatabase()).getById(personaId)
    if (!persona) throw new Error('페르소나를 찾을 수 없습니다.')
    const win = BrowserWindow.fromWebContents(event.sender)!
    try {
      for await (const chunk of streamChat(apiKey, persona, messages)) {
        win.webContents.send(IPC_CHANNELS.CHAT.STREAM_CHUNK, chunk)
      }
      win.webContents.send(IPC_CHANNELS.CHAT.STREAM_END)
    } catch (err) {
      win.webContents.send(IPC_CHANNELS.CHAT.STREAM_ERROR, (err as Error).message)
    }
  })
}
```

`settingsHandlers.ts`:
```typescript
import { ipcMain } from 'electron'
import { IPC_CHANNELS } from '../../../shared/types'
import { settingsService } from '../services/settingsService'

export function registerSettingsHandlers(): void {
  ipcMain.handle(IPC_CHANNELS.SETTINGS.GET_API_KEY, () => settingsService.getApiKey())
  ipcMain.handle(IPC_CHANNELS.SETTINGS.SET_API_KEY, (_, key) => settingsService.setApiKey(key))
  ipcMain.handle(IPC_CHANNELS.SETTINGS.HAS_API_KEY, () => settingsService.hasApiKey())
}
```

**Step 4:** `handlers.ts` (entry) + `preload/index.ts`

`handlers.ts`:
```typescript
import { registerPersonaHandlers } from './personaHandlers'
import { registerChatHandlers } from './chatHandlers'
import { registerSettingsHandlers } from './settingsHandlers'

export function registerAllHandlers(): void {
  registerPersonaHandlers()
  registerChatHandlers()
  registerSettingsHandlers()
}
```

`preload/index.ts`:
```typescript
import { contextBridge, ipcRenderer } from 'electron'
import { IPC_CHANNELS } from '../../shared/types'

contextBridge.exposeInMainWorld('api', {
  persona: {
    list:   ()      => ipcRenderer.invoke(IPC_CHANNELS.PERSONA.LIST),
    get:    (id)    => ipcRenderer.invoke(IPC_CHANNELS.PERSONA.GET, id),
    create: (input) => ipcRenderer.invoke(IPC_CHANNELS.PERSONA.CREATE, input),
    update: (input) => ipcRenderer.invoke(IPC_CHANNELS.PERSONA.UPDATE, input),
    delete: (id)    => ipcRenderer.invoke(IPC_CHANNELS.PERSONA.DELETE, id),
  },
  chat: {
    send: (personaId, messages) =>
      ipcRenderer.invoke(IPC_CHANNELS.CHAT.SEND, { personaId, messages }),
    onChunk:  (cb) => ipcRenderer.on(IPC_CHANNELS.CHAT.STREAM_CHUNK, (_, chunk) => cb(chunk)),
    onEnd:    (cb) => ipcRenderer.on(IPC_CHANNELS.CHAT.STREAM_END, cb),
    onError:  (cb) => ipcRenderer.on(IPC_CHANNELS.CHAT.STREAM_ERROR, (_, err) => cb(err)),
    removeListeners: () => {
      ipcRenderer.removeAllListeners(IPC_CHANNELS.CHAT.STREAM_CHUNK)
      ipcRenderer.removeAllListeners(IPC_CHANNELS.CHAT.STREAM_END)
      ipcRenderer.removeAllListeners(IPC_CHANNELS.CHAT.STREAM_ERROR)
    },
  },
  settings: {
    getApiKey: () => ipcRenderer.invoke(IPC_CHANNELS.SETTINGS.GET_API_KEY),
    setApiKey: (key) => ipcRenderer.invoke(IPC_CHANNELS.SETTINGS.SET_API_KEY, key),
    hasApiKey: () => ipcRenderer.invoke(IPC_CHANNELS.SETTINGS.HAS_API_KEY),
  },
})
```

**Step 5:** `src/main/index.ts`에 핸들러 등록 (boilerplate 수정)
```typescript
// app.whenReady() 콜백 안에 추가:
import { registerAllHandlers } from './ipc/handlers'
import { closeDatabase } from './db/database'

registerAllHandlers()
// app.on('before-quit', closeDatabase) 추가
```

**Step 6:** 커밋
```bash
git add . && git commit -m "feat: add IPC handlers, Claude streaming service, settings service"
```

---

## Task 5: Renderer — Zustand Store + Hooks

**Files:**
- Create: `src/renderer/src/store/appStore.ts`
- Create: `src/renderer/src/hooks/usePersonas.ts`
- Create: `src/renderer/src/hooks/useChat.ts`

**Step 1:** `appStore.ts`
```typescript
import { create } from 'zustand'
import type { Persona, Message } from '../../../shared/types'

interface AppStore {
  personas: Persona[]
  selectedPersonaId: string | null
  messages: Message[]
  isStreaming: boolean
  setPersonas: (p: Persona[]) => void
  selectPersona: (id: string | null) => void
  addMessage: (m: Message) => void
  appendToLastMessage: (chunk: string) => void
  setStreaming: (v: boolean) => void
}

export const useAppStore = create<AppStore>((set) => ({
  personas: [],
  selectedPersonaId: null,
  messages: [],
  isStreaming: false,
  setPersonas: (personas) => set({ personas }),
  selectPersona: (id) => set({ selectedPersonaId: id, messages: [] }),
  addMessage: (m) => set((s) => ({ messages: [...s.messages, m] })),
  appendToLastMessage: (chunk) =>
    set((s) => {
      const msgs = [...s.messages]
      if (!msgs.length) return s
      msgs[msgs.length - 1] = {
        ...msgs[msgs.length - 1],
        content: msgs[msgs.length - 1].content + chunk,
      }
      return { messages: msgs }
    }),
  setStreaming: (isStreaming) => set({ isStreaming }),
}))
```

**Step 2:** `usePersonas.ts`
```typescript
import { useEffect } from 'react'
import { useAppStore } from '../store/appStore'
import type { PersonaCreateInput, PersonaUpdateInput } from '../../../../shared/types'

export function usePersonas() {
  const { personas, setPersonas } = useAppStore()

  const load = async () => setPersonas(await window.api.persona.list())

  useEffect(() => { load() }, [])

  return {
    personas,
    create: async (input: PersonaCreateInput) => {
      await window.api.persona.create(input)
      await load()
    },
    update: async (input: PersonaUpdateInput) => {
      await window.api.persona.update(input)
      await load()
    },
    remove: async (id: string) => {
      await window.api.persona.delete(id)
      await load()
    },
  }
}
```

**Step 3:** `useChat.ts`
```typescript
import { useEffect } from 'react'
import { useAppStore } from '../store/appStore'

export function useChat() {
  const { messages, isStreaming, selectedPersonaId, addMessage, appendToLastMessage, setStreaming } =
    useAppStore()

  useEffect(() => {
    window.api.chat.onChunk((chunk) => appendToLastMessage(chunk))
    window.api.chat.onEnd(() => setStreaming(false))
    window.api.chat.onError(() => setStreaming(false))
    return () => window.api.chat.removeListeners()
  }, [])

  const sendMessage = async (content: string) => {
    if (!selectedPersonaId || isStreaming || !content.trim()) return
    const userMsg = {
      id: crypto.randomUUID(),
      role: 'user' as const,
      content,
      timestamp: Date.now(),
    }
    addMessage(userMsg)
    addMessage({
      id: crypto.randomUUID(),
      role: 'assistant' as const,
      content: '',
      timestamp: Date.now(),
    })
    setStreaming(true)
    await window.api.chat.send(selectedPersonaId, [...messages, userMsg])
  }

  return { messages, isStreaming, sendMessage }
}
```

**Step 4:** 커밋
```bash
git add . && git commit -m "feat: add Zustand store and hooks for personas/chat"
```

---

## Task 6: UI 컴포넌트

**Files:**
- Create: `src/renderer/src/components/layout/MainLayout.tsx`
- Create: `src/renderer/src/components/persona/PersonaList.tsx`
- Create: `src/renderer/src/components/persona/PersonaForm.tsx`
- Create: `src/renderer/src/components/chat/ChatWindow.tsx`
- Create: `src/renderer/src/components/chat/MessageBubble.tsx`
- Create: `src/renderer/src/components/chat/ChatInput.tsx`
- Create: `src/renderer/src/components/settings/SettingsModal.tsx`
- Modify: `src/renderer/src/App.tsx`

**Step 1:** `MainLayout.tsx` — 2-panel (좌 280px 고객목록 + 우 채팅)
```tsx
export function MainLayout({ sidebar, chat }: { sidebar: React.ReactNode; chat: React.ReactNode }) {
  return (
    <div className="flex h-screen bg-gray-50 text-gray-900">
      <aside className="w-72 min-w-60 border-r border-gray-200 bg-white flex flex-col shrink-0">
        {sidebar}
      </aside>
      <main className="flex-1 flex flex-col overflow-hidden">{chat}</main>
    </div>
  )
}
```

**Step 2:** `PersonaList.tsx` — 고객 목록 + 검색 + 추가 버튼
- useState로 검색어 관리, persona.name/company 필터
- 선택 시 `selectPersona(id)` 호출
- `+ 새 고객` 버튼으로 PersonaForm 모달 오픈

**Step 3:** `PersonaForm.tsx` — 생성/편집 모달 (7개 섹션)
- 필수: `name` (비어있으면 Submit 비활성화)
- 선택: 나머지 6개 필드 (textarea)
- `onSubmit`: create or update

**Step 4:** `ChatWindow.tsx` — 스크롤 + 스트리밍 표시
```tsx
export function ChatWindow() {
  const { messages, isStreaming, sendMessage } = useChat()
  const selectedId = useAppStore((s) => s.selectedPersonaId)
  const bottomRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  if (!selectedId)
    return (
      <div className="flex-1 flex items-center justify-center text-gray-400">
        왼쪽에서 고객을 선택하세요
      </div>
    )

  return (
    <div className="flex flex-col h-full">
      <div className="flex-1 overflow-y-auto p-4 space-y-3">
        {messages.map((m) => (
          <MessageBubble key={m.id} message={m} />
        ))}
        {isStreaming && <div className="text-xs text-gray-400 animate-pulse">답변 작성 중...</div>}
        <div ref={bottomRef} />
      </div>
      <ChatInput onSend={sendMessage} disabled={isStreaming} />
    </div>
  )
}
```

**Step 5:** `MessageBubble.tsx` — user(오른쪽 파란색) / assistant(왼쪽 회색)

**Step 6:** `ChatInput.tsx` — Enter 전송, Shift+Enter 줄바꿈, 빈 메시지 방지

**Step 7:** `SettingsModal.tsx` — API 키 입력 + safeStorage 저장
```tsx
// sk-ant- 접두어 검증, 저장 완료 후 1초 뒤 닫기
```

**Step 8:** `App.tsx` 통합
```tsx
// 앱 시작 시 hasApiKey() 체크 → false이면 SettingsModal 자동 표시
useEffect(() => {
  window.api.settings.hasApiKey().then((has) => {
    if (!has) setShowSettings(true)
  })
}, [])
```

**Step 9:** 앱 실행 확인
```bash
npm run dev
```

**Step 10:** 커밋
```bash
git add . && git commit -m "feat: add complete UI components (layout, persona, chat, settings)"
```

---

## Task 7: E2E 수동 검증

```bash
npm run dev
```

수동 체크리스트:
- [ ] 앱 첫 실행 → API 키 설정 모달 자동 표시
- [ ] API 키 저장 → 재시작 후에도 유지 (Settings 모달 안 뜸)
- [ ] `+ 새 고객` → 폼 입력 → 저장 → 좌측 목록에 표시
- [ ] 고객 클릭 → 우측 채팅창 활성화
- [ ] 메시지 입력 → 스트리밍으로 페르소나 응답 (타이핑 효과)
- [ ] 다른 고객 선택 → 채팅 히스토리 초기화
- [ ] 고객 편집/삭제 정상 동작

```bash
# 단위 테스트
npm test

# 타입 체크
npm run typecheck

# 빌드
npm run build
```

**최종 커밋:**
```bash
git add . && git commit -m "feat: complete sales persona agent MVP"
```

---

## 참고: window.api 타입 선언 (`src/renderer/src/env.d.ts`)

```typescript
import type { Persona, PersonaCreateInput, PersonaUpdateInput, Message } from '../../shared/types'

declare global {
  interface Window {
    api: {
      persona: {
        list(): Promise<Persona[]>
        get(id: string): Promise<Persona | undefined>
        create(input: PersonaCreateInput): Promise<Persona>
        update(input: PersonaUpdateInput): Promise<Persona | undefined>
        delete(id: string): Promise<boolean>
      }
      chat: {
        send(personaId: string, messages: Message[]): Promise<void>
        onChunk(cb: (chunk: string) => void): void
        onEnd(cb: () => void): void
        onError(cb: (err: string) => void): void
        removeListeners(): void
      }
      settings: {
        getApiKey(): Promise<string | null>
        setApiKey(key: string): Promise<void>
        hasApiKey(): Promise<boolean>
      }
    }
  }
}
```
