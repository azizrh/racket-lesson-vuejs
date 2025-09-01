# S-Expression Learning App - High-Level Workflow

## System Architecture

```
Frontend (Vue.js) ←→ Backend API (FastAPI) ←→ Database (PostgreSQL)
                                  ↓
                           Racket Runner Service
```

## Core Workflow

### 1. User Onboarding & Authentication
- **Landing Page**: Hero section explaining S-expressions with getting started guide
- **Simple Auth**: Username-based login (no passwords)
- **User Creation**: Automatic account creation if username doesn't exist
- **Progress Tracking**: Each user gets a profile with unlocked lessons and active lesson

### 2. Progressive Lesson System
- **Sequential Unlocking**: Users start with Lesson 1, must complete to unlock next
- **Lesson Structure**: Each lesson contains:
  - Markdown-formatted educational content
  - Multiple practice problems with expected answers
  - Validation configuration (CFG or Racket-based)

### 3. Practice & Validation Flow
- **Problem Display**: Show current problem from active lesson
- **Answer Input**: User types S-expression answer
- **Real-time Validation**: 
  - Submit to backend `/validate` endpoint
  - Backend uses Racket runner service for execution/evaluation
  - Returns success/failure with detailed feedback
- **Attempt Recording**: All submissions logged to database for analytics

### 4. Progress & Advancement
- **Streak Tracking**: Count consecutive correct answers
- **Unlock Trigger**: 3 correct answers in a row unlocks next lesson
- **Congratulations Modal**: Celebrates achievement and offers advancement
- **Lesson Navigation**: Browse unlocked lessons, disabled navigation for locked content

### 5. Spaced Repetition System
- **Review Scheduling**: Leitner box system for optimal retention
- **Automatic Reviews**: Random prompts appear to reinforce previous lessons
- **Progressive Intervals**: 15min → 8hr → 1day → 3day → 7day → 14day

## Data Models

### Core Entities
- **Lesson**: `{id, title, body_md, validator_config}`
- **Problem**: `{id, lesson_id, prompt_text, answer_text, validator_spec}`
- **User**: `{user_id, username, active_lesson, lessons[]}`
- **Attempt**: `{id, user_id, problem_id, submitted_text, is_correct, stage, details}`
- **Review Schedule**: `{user_id, lesson_id, box, due_at}`

## Key Features

### Educational Flow
1. **Structured Learning**: Lessons progress from basic S-expressions to complex nested forms
2. **Interactive Examples**: Markdown lessons with code examples and explanations
3. **Immediate Feedback**: Real-time validation with specific error messages

### User Experience
- **Responsive Design**: Works on desktop and mobile
- **Keyboard Shortcuts**: Enter to check, Ctrl+Enter to reveal
- **Visual Feedback**: Color-coded success/error states
- **Progress Indicators**: Shows unlocked lessons and completion status

### Technical Validation
- **Dual Validation**: Context-Free Grammar parsing + Racket evaluation
- **Flexible Configuration**: Per-lesson and per-problem validator settings
- **Sandbox Execution**: Safe Racket code execution with memory/time limits

## User Journey

### New User
1. Arrives at landing page → sees hero + getting started
2. Clicks "Get Started" → username login modal
3. Enters username → account created, redirected to Lesson 1
4. Reads lesson content → attempts practice problems
5. Gets 3 correct → congratulations modal → unlocks Lesson 2

### Returning User
1. Lands on homepage → sees progress dashboard
2. Can choose to continue active lesson or review previous lessons
3. Random review prompts appear based on spaced repetition schedule
4. Can advance through unlocked lessons at own pace

## Backend Services

### FastAPI Application (`app.py`)
- RESTful API endpoints for lessons, problems, users, validation
- PostgreSQL connection pooling
- User management with lesson unlocking logic
- Attempt tracking and spaced repetition scheduling

### Racket Runner Service
- Sandboxed Racket code execution
- Memory and time limit enforcement
- JSON-based communication with main API
- Supports both parsing validation and expression evaluation

### Database Schema
- **Normalized design** with foreign key constraints
- **Efficient indexing** for user queries and attempt lookups
- **JSON fields** for flexible validator configurations
- **Array fields** for user's unlocked lessons list

## Development & Deployment

### Local Development
```bash
docker-compose --profile development up  # Full stack with hot reload
```

### Production Deployment
```bash
docker-compose --profile production up   # Nginx + built frontend
```

### Key Technologies
- **Frontend**: Vue.js 3 + Vite + Tailwind CSS
- **Backend**: FastAPI + psycopg (async PostgreSQL)
- **Validation**: Racket language runtime
- **Infrastructure**: Docker Compose with health checks