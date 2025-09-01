from typing import List, Optional, Any, Dict
from fastapi import FastAPI, HTTPException
from fastapi.middleware.cors import CORSMiddleware
from pydantic import BaseModel
from pydantic_settings import BaseSettings
from psycopg_pool import AsyncConnectionPool
import psycopg
import httpx
import json
from datetime import datetime, timedelta, timezone

# --- settings ---
class Settings(BaseSettings):
    DATABASE_URL: str
    RACKET_RUNNER_URL: str
    class Config:
        env_file = ".env"

settings = Settings()
pool = AsyncConnectionPool(settings.DATABASE_URL, min_size=1, max_size=10, open=False)

# --- app ---
app = FastAPI(title="S-Expression Lessons API", version="0.4.0")
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],  # tighten in prod
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# --- models ---
class LessonCreate(BaseModel):
    title: str
    body_md: str

class LessonOut(LessonCreate):
    id: int

class ProblemCreate(BaseModel):
    lesson_id: int
    prompt_text: str
    answer_text: str

class ProblemOut(ProblemCreate):
    id: int

class ValidateReq(BaseModel):
    problem_id: int
    submission: str

# class AttemptIn(BaseModel):
#     username: Optional[str] = None      # preferred: login by username
#     user_id: Optional[int] = None       # kept for backward compat
#     problem_id: int
#     submitted_text: str
#     is_correct: bool
#     stage: Optional[str] = None
#     error_reason: Optional[str] = None
#     details: Optional[Dict[str, Any]] = None

class AttemptIn(BaseModel):
    username: Optional[str] = None
    user_id: Optional[int] = None
    problem_id: int
    submitted_text: str
    is_correct: bool
    stage: Optional[str] = None
    error_reason: Optional[str] = None
    details: Optional[Any] = None   # <- allow any JSON, not just dict


class UserCreate(BaseModel):
    username: str
    active_lesson: Optional[int] = None

class UserOut(BaseModel):
    user_id: int
    username: str
    active_lesson: Optional[int]
    lessons: List[int]

class LoginReq(BaseModel):
    username: str

class LastAttemptPerLesson(BaseModel):
    user_id: int
    lesson_id: int
    last_attempt_utc: datetime

class NextReviewOut(BaseModel):
    lesson_id: int
    due_at: datetime
    box: int

# --- SR schedule config (Leitner) ---
MAX_BOX = 6
BOX_INTERVALS = {
    1: timedelta(minutes=15),
    2: timedelta(hours=8),
    3: timedelta(days=1),
    4: timedelta(days=3),
    5: timedelta(days=7),
    6: timedelta(days=14),
}

def _now_utc() -> datetime:
    return datetime.now(timezone.utc)

# --- lifecycle ---
@app.on_event("startup")
async def on_startup():
    await pool.open()
    ddl = """
    -- LESSON
    CREATE TABLE IF NOT EXISTS lesson (
      id BIGSERIAL PRIMARY KEY,
      title TEXT NOT NULL UNIQUE,
      body_md TEXT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      validator_default TEXT NOT NULL DEFAULT 'cfg',
      validator_spec JSONB NOT NULL DEFAULT '{}'::jsonb
    );

    -- PROBLEM
    CREATE TABLE IF NOT EXISTS problem (
      id BIGSERIAL PRIMARY KEY,
      lesson_id BIGINT NOT NULL REFERENCES lesson(id) ON DELETE CASCADE,
      prompt_text TEXT NOT NULL,
      answer_text TEXT NOT NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      validator_kind TEXT NULL,
      validator_spec JSONB NULL
    );
    CREATE INDEX IF NOT EXISTS idx_problem_lesson_id ON problem(lesson_id);

    -- USER (array-based)
    CREATE TABLE IF NOT EXISTS public."user" (
      user_id        BIGSERIAL PRIMARY KEY,
      username       TEXT NOT NULL UNIQUE,
      active_lesson  BIGINT NULL REFERENCES lesson(id) ON DELETE SET NULL,
      lessons        BIGINT[] NOT NULL DEFAULT '{}',
      created_at     TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      CONSTRAINT user_active_in_lessons_chk
        CHECK (active_lesson IS NULL OR active_lesson = ANY (lessons))
    );
    CREATE INDEX IF NOT EXISTS idx_user_active_lesson ON public."user"(active_lesson);
    CREATE INDEX IF NOT EXISTS idx_user_lessons_gin ON public."user" USING GIN (lessons);

    -- ATTEMPT
    CREATE TABLE IF NOT EXISTS attempt (
      id BIGSERIAL PRIMARY KEY,
      problem_id BIGINT NOT NULL REFERENCES problem(id) ON DELETE CASCADE,
      submitted_text TEXT NOT NULL,
      is_correct BOOLEAN NOT NULL,
      stage TEXT NULL,
      error_reason TEXT NULL,
      details_json JSONB NULL,
      created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      user_id BIGINT NULL REFERENCES public."user"(user_id) ON DELETE CASCADE
    );
    CREATE INDEX IF NOT EXISTS attempt_problem_id_created_at_idx
      ON attempt (problem_id, created_at DESC);
    CREATE INDEX IF NOT EXISTS attempt_user_created_at_idx
      ON attempt (user_id, created_at DESC);

    -- USER LESSON REVIEW (spaced repetition schedule)
    CREATE TABLE IF NOT EXISTS user_lesson_review (
      user_id   BIGINT NOT NULL REFERENCES public."user"(user_id) ON DELETE CASCADE,
      lesson_id BIGINT NOT NULL REFERENCES lesson(id) ON DELETE CASCADE,
      box       INT NOT NULL DEFAULT 1,
      due_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
      updated_at TIMESTAMPTZ NULL,
      PRIMARY KEY (user_id, lesson_id)
    );
    CREATE INDEX IF NOT EXISTS idx_user_lesson_review_due
      ON user_lesson_review (user_id, due_at);
    """
    async with pool.connection() as con:
        async with con.cursor() as cur:
            await cur.execute(ddl)
        await con.commit()

@app.on_event("shutdown")
async def on_shutdown():
    await pool.close()

# --- health ---
@app.get("/health")
async def health():
    return {"status": "ok"}

# --- lessons ---
@app.post("/lessons", response_model=LessonOut)
async def create_lesson(payload: LessonCreate):
    q = "INSERT INTO lesson (title, body_md) VALUES (%s, %s) RETURNING id, title, body_md"
    async with pool.connection() as con:
        async with con.cursor() as cur:
            try:
                await cur.execute(q, (payload.title, payload.body_md))
                row = await cur.fetchone()
            except Exception as e:
                raise HTTPException(400, str(e))
        await con.commit()
    return LessonOut(id=row[0], title=row[1], body_md=row[2])

@app.get("/lessons/{lesson_id}", response_model=LessonOut)
async def get_lesson(lesson_id: int):
    q = "SELECT id, title, body_md FROM lesson WHERE id = %s"
    async with pool.connection() as con:
        async with con.cursor() as cur:
            await cur.execute(q, (lesson_id,))
            row = await cur.fetchone()
            if not row:
                raise HTTPException(404, "Lesson not found")
    return LessonOut(id=row[0], title=row[1], body_md=row[2])

@app.get("/lessons")
async def list_lessons():
    q = "SELECT id, title, body_md FROM lesson ORDER BY created_at ASC, id ASC"
    async with pool.connection() as con:
        async with con.cursor() as cur:
            await cur.execute(q)
            rows = await cur.fetchall()
    return [{"id": r[0], "title": r[1], "body_md": r[2]} for r in rows]

# --- problems ---
@app.post("/problems", response_model=ProblemOut)
async def create_problem(payload: ProblemCreate):
    async with pool.connection() as con:
        async with con.cursor() as cur:
            await cur.execute("SELECT 1 FROM lesson WHERE id = %s", (payload.lesson_id,))
            if not await cur.fetchone():
                raise HTTPException(404, "Lesson not found")
            q = """INSERT INTO problem (lesson_id, prompt_text, answer_text)
                   VALUES (%s, %s, %s)
                   RETURNING id, lesson_id, prompt_text, answer_text"""
            await cur.execute(q, (payload.lesson_id, payload.prompt_text, payload.answer_text))
            row = await cur.fetchone()
        await con.commit()
    return ProblemOut(id=row[0], lesson_id=row[1], prompt_text=row[2], answer_text=row[3])

@app.get("/lessons/{lesson_id}/problems", response_model=List[ProblemOut])
async def list_problems(lesson_id: int):
    q = """SELECT id, lesson_id, prompt_text, answer_text
           FROM problem WHERE lesson_id = %s ORDER BY id"""
    async with pool.connection() as con:
        async with con.cursor() as cur:
            await cur.execute(q, (lesson_id,))
            rows = await cur.fetchall()
    return [ProblemOut(id=r[0], lesson_id=r[1], prompt_text=r[2], answer_text=r[3]) for r in rows]

@app.delete("/problems/{problem_id}")
async def delete_problem(problem_id: int):
    q = "DELETE FROM problem WHERE id = %s RETURNING id"
    async with pool.connection() as con:
        async with con.cursor() as cur:
            await cur.execute(q, (problem_id,))
            row = await cur.fetchone()
            if not row:
                raise HTTPException(404, "Problem not found")
        await con.commit()
    return {"deleted_id": row[0]}

# --- validate ---
@app.post("/validate")
async def validate(req: ValidateReq):
    q = """SELECT p.id, p.prompt_text, p.answer_text,
                  l.validator_default, l.validator_spec,
                  p.validator_kind, p.validator_spec
           FROM problem p
           JOIN lesson l ON l.id = p.lesson_id
           WHERE p.id = %s"""
    async with pool.connection() as con:
        async with con.cursor() as cur:
            await cur.execute(q, (req.problem_id,))
            row = await cur.fetchone()
            if not row:
                raise HTTPException(404, "Problem not found")

    (_pid, _prompt, answer, l_def, l_spec, p_kind, p_spec) = row
    l_def = l_def or "cfg"
    l_spec = l_spec or {}
    p_spec = p_spec or {}
    kind = p_kind or l_def

    if kind == "cfg":
        ok = (req.submission.strip() == answer.strip())
        return {"ok": bool(ok), "stage": "cfg",
                "error": None if ok else "answer mismatch",
                "details": {"expected": answer}}

    if kind == "racket":
        def merge(a, b):
            aa = a or {}
            bb = b or {}
            out = dict(aa); out.update(bb); return out
        spec = merge(l_spec, p_spec)
        payload = {
            "submission": req.submission,
            "mode": spec.get("mode", "parse"),
            "lang": spec.get("lang", "racket/base"),
            "time_ms": spec.get("time_ms", 200),
            "mem_mb": spec.get("mem_mb", 64),
            "tests": spec.get("tests", [])
        }
        try:
            async with httpx.AsyncClient(timeout=3.0) as client:
                r = await client.post(
                    f"{settings.RACKET_RUNNER_URL}/validate",
                    content=json.dumps(payload),
                    headers={"Content-Type": "application/json"},
                )
            r.raise_for_status()
            data = r.json()
            if isinstance(data.get("details"), str):
                data["details"] = {"message": data["details"]}
            return data
        except Exception as e:
            raise HTTPException(400, f"racket runner error: {e}")

    raise HTTPException(400, f"Unknown validator kind: {kind}")

# --- internal helpers: spaced repetition ---
async def _ensure_review_rows_for_unlocked_lessons(con, user_id: int):
    """
    Ensure a user_lesson_review row exists for each unlocked lesson.
    New rows start at box=1 and due_at=NOW().
    """
    # Get user's unlocked lessons
    async with con.cursor() as cur:
        await cur.execute('SELECT lessons FROM public."user" WHERE user_id = %s', (user_id,))
        row = await cur.fetchone()
        if not row:
            return
        unlocked = row[0] or []
        if not unlocked:
            return

        # Insert missing rows
        await cur.execute("""
            INSERT INTO user_lesson_review (user_id, lesson_id, box, due_at)
            SELECT %s, l_id, 1, NOW()
            FROM UNNEST(%s::bigint[]) AS l_id
            ON CONFLICT (user_id, lesson_id) DO NOTHING
        """, (user_id, unlocked))

async def _bump_review_after_attempt(con, user_id: Optional[int], problem_id: int, is_correct: bool):
    """
    After an attempt, update the spaced-repetition schedule for that (user, lesson).
    """
    if not user_id:
        return  # anonymous attempts do not affect schedule

    # Resolve lesson from problem
    async with con.cursor() as cur:
        await cur.execute("SELECT lesson_id FROM problem WHERE id = %s", (problem_id,))
        row = await cur.fetchone()
        if not row:
            return
        lesson_id = row[0]

        # Ensure row exists
        await cur.execute("""
            INSERT INTO user_lesson_review (user_id, lesson_id, box, due_at, updated_at)
            VALUES (%s, %s, 1, NOW(), NOW())
            ON CONFLICT (user_id, lesson_id) DO NOTHING
        """, (user_id, lesson_id))

        # Fetch current box
        await cur.execute("""
            SELECT box FROM user_lesson_review
            WHERE user_id = %s AND lesson_id = %s
        """, (user_id, lesson_id))
        r2 = await cur.fetchone()
        cur_box = r2[0] if r2 else 1

        # Compute next box & due
        next_box = 1 if not is_correct else min(cur_box + 1, MAX_BOX)
        interval = BOX_INTERVALS.get(next_box, BOX_INTERVALS[MAX_BOX])
        due_at = _now_utc() + interval

        # Update
        await cur.execute("""
            UPDATE user_lesson_review
            SET box = %s,
                due_at = %s,
                updated_at = NOW()
            WHERE user_id = %s AND lesson_id = %s
        """, (next_box, due_at, user_id, lesson_id))

# # --- attempts ---
# @app.post("/attempts")
# async def create_attempt(a: AttemptIn):
#     # Resolve user_id if username provided
#     resolved_user_id = a.user_id
#     if a.username and not resolved_user_id:
#         async with pool.connection() as con:
#             async with con.cursor() as cur:
#                 await cur.execute('SELECT user_id FROM public."user" WHERE username = %s', (a.username,))
#                 r = await cur.fetchone()
#                 if not r:
#                     raise HTTPException(404, "username not found")
#                 resolved_user_id = r[0]

#     async with pool.connection() as con:
#         async with con.cursor() as cur:
#             q = """INSERT INTO attempt (user_id, problem_id, submitted_text, is_correct, stage, error_reason, details_json)
#                    VALUES (%s, %s, %s, %s, %s, %s, %s)
#                    RETURNING id, created_at"""
#             await cur.execute(q, (
#                 resolved_user_id, a.problem_id, a.submitted_text, a.is_correct,
#                 a.stage, a.error_reason, json.dumps(a.details) if a.details is not None else None
#             ))
#             row = await cur.fetchone()

#         # SR bump (same transaction)
#         await _bump_review_after_attempt(con, resolved_user_id, a.problem_id, a.is_correct)

#         await con.commit()
#     return {"id": row[0], "created_at": row[1]}

@app.post("/attempts")
async def create_attempt(a: AttemptIn):
    # Resolve user_id if username provided
    resolved_user_id = a.user_id
    if a.username and not resolved_user_id:
        async with pool.connection() as con:
            async with con.cursor() as cur:
                await cur.execute('SELECT user_id FROM public."user" WHERE username = %s', (a.username,))
                r = await cur.fetchone()
                if not r:
                    raise HTTPException(404, "username not found")
                resolved_user_id = r[0]

    async with pool.connection() as con:
        try:
            async with con.cursor() as cur:
                q = """INSERT INTO attempt
                         (user_id, problem_id, submitted_text, is_correct, stage, error_reason, details_json)
                       VALUES (%s, %s, %s, %s, %s, %s, %s)
                       RETURNING id, created_at"""
                await cur.execute(q, (
                    resolved_user_id,
                    a.problem_id,
                    a.submitted_text,
                    a.is_correct,
                    a.stage,
                    a.error_reason,
                    json.dumps(a.details) if a.details is not None else None,
                ))
                row = await cur.fetchone()

            # SR bump (same txn)
            await _bump_review_after_attempt(con, resolved_user_id, a.problem_id, a.is_correct)

            await con.commit()
            return {"id": row[0], "created_at": row[1]}

        except psycopg.errors.ForeignKeyViolation:
            await con.rollback()
            # problem_id doesn't exist (FK to problem.id)
            raise HTTPException(404, "problem_id not found")
        except Exception as e:
            await con.rollback()
            # show a helpful message during dev
            raise HTTPException(400, f"attempt insert failed: {e}")


# --- users ---
@app.post("/users", response_model=UserOut)
async def create_user(payload: UserCreate):
    if not payload or not payload.username:
        raise HTTPException(400, "username is required")

    async with pool.connection() as con:
        async with con.cursor() as cur:
            # If exists, return it
            await cur.execute('SELECT user_id, username, active_lesson, lessons FROM public."user" WHERE username = %s', (payload.username,))
            existing = await cur.fetchone()
            if existing:
                # Ensure review rows exist for unlocked lessons
                await _ensure_review_rows_for_unlocked_lessons(con, existing[0])
                await con.commit()
                return UserOut(user_id=existing[0], username=existing[1], active_lesson=existing[2], lessons=existing[3])

            # Choose active lesson
            if payload.active_lesson is not None:
                await cur.execute("SELECT id FROM lesson WHERE id = %s", (payload.active_lesson,))
                r = await cur.fetchone()
                if not r:
                    raise HTTPException(404, "active_lesson not found")
                active = payload.active_lesson
            else:
                await cur.execute("""SELECT id FROM lesson ORDER BY created_at ASC, id ASC LIMIT 1""")
                r = await cur.fetchone()
                if not r:
                    raise HTTPException(400, "No lessons exist yet")
                active = r[0]

            # Insert user
            await cur.execute("""
                INSERT INTO public."user" (username, active_lesson, lessons)
                VALUES (%s, %s, ARRAY[%s]::bigint[])
                RETURNING user_id, username, active_lesson, lessons
            """, (payload.username, active, active))
            row = await cur.fetchone()

            # Seed review rows
            await _ensure_review_rows_for_unlocked_lessons(con, row[0])

        await con.commit()
    return UserOut(user_id=row[0], username=row[1], active_lesson=row[2], lessons=row[3])

@app.get("/users/{user_id}", response_model=UserOut)
async def get_user(user_id: int):
    q = 'SELECT user_id, username, active_lesson, lessons FROM public."user" WHERE user_id = %s'
    async with pool.connection() as con:
        async with con.cursor() as cur:
            await cur.execute(q, (user_id,))
            row = await cur.fetchone()
            if not row:
                raise HTTPException(404, "User not found")
    return UserOut(user_id=row[0], username=row[1], active_lesson=row[2], lessons=row[3])

@app.get("/users/by-username/{username}", response_model=UserOut)
async def get_user_by_username(username: str):
    q = 'SELECT user_id, username, active_lesson, lessons FROM public."user" WHERE username = %s'
    async with pool.connection() as con:
        async with con.cursor() as cur:
            await cur.execute(q, (username,))
            row = await cur.fetchone()
            if not row:
                raise HTTPException(404, "User not found")

            # Ensure review rows exist for unlocked lessons (lazy sync)
            await _ensure_review_rows_for_unlocked_lessons(con, row[0])
            await con.commit()

    return UserOut(user_id=row[0], username=row[1], active_lesson=row[2], lessons=row[3])

@app.post("/login", response_model=UserOut)
async def login(req: LoginReq):
    async with pool.connection() as con:
        async with con.cursor() as cur:
            # try to get existing
            await cur.execute('SELECT user_id, username, active_lesson, lessons FROM public."user" WHERE username = %s', (req.username,))
            row = await cur.fetchone()
            if row:
                await _ensure_review_rows_for_unlocked_lessons(con, row[0])
                await con.commit()
                return UserOut(user_id=row[0], username=row[1], active_lesson=row[2], lessons=row[3])

            # otherwise create with first lesson
            await cur.execute("""SELECT id FROM lesson ORDER BY created_at ASC, id ASC LIMIT 1""")
            r = await cur.fetchone()
            if not r:
                raise HTTPException(400, "No lessons exist yet")
            active = r[0]
            await cur.execute("""
                INSERT INTO public."user" (username, active_lesson, lessons)
                VALUES (%s, %s, ARRAY[%s]::bigint[])
                RETURNING user_id, username, active_lesson, lessons
            """, (req.username, active, active))
            created = await cur.fetchone()

            await _ensure_review_rows_for_unlocked_lessons(con, created[0])
        await con.commit()
    return UserOut(user_id=created[0], username=created[1], active_lesson=created[2], lessons=created[3])

# --- advance (by user_id, kept) ---
@app.post("/users/{user_id}/advance", response_model=UserOut)
async def advance_user_to_next_lesson(user_id: int):
    async with pool.connection() as con:
        async with con.cursor() as cur:
            # Load user
            await cur.execute('SELECT user_id, username, active_lesson, lessons FROM public."user" WHERE user_id = %s', (user_id,))
            user = await cur.fetchone()
            if not user:
                raise HTTPException(404, "User not found")
            _uid, _username, active_lesson, _lessons = user
            if active_lesson is None:
                raise HTTPException(400, "User has no active lesson")

            # Verify 3-in-a-row on active lesson
            await cur.execute("""
              SELECT a.is_correct
              FROM attempt a
              JOIN problem p ON p.id = a.problem_id
              WHERE a.user_id = %s AND p.lesson_id = %s
              ORDER BY a.created_at DESC, a.id DESC
              LIMIT 3
            """, (user_id, active_lesson))
            rows = await cur.fetchall()
            if len(rows) < 3 or not all(r[0] for r in rows):
                raise HTTPException(403, "Unlock requires 3 correct attempts in a row on the current lesson")

            # Next lesson
            await cur.execute("""SELECT id FROM lesson ORDER BY created_at ASC, id ASC""")
            all_lessons = [r[0] for r in await cur.fetchall()]
            if active_lesson not in all_lessons:
                raise HTTPException(400, "Active lesson not found in lesson list")
            idx = all_lessons.index(active_lesson)
            if idx == len(all_lessons) - 1:
                raise HTTPException(400, "No next lesson to advance to")
            next_lesson = all_lessons[idx + 1]

            # Update user (unlock next)
            await cur.execute("""
              UPDATE public."user"
              SET active_lesson = %s,
                  lessons = CASE
                      WHEN NOT (%s = ANY(lessons)) THEN array_append(lessons, %s)
                      ELSE lessons
                  END
              WHERE user_id = %s
              RETURNING user_id, username, active_lesson, lessons
            """, (next_lesson, next_lesson, next_lesson, user_id))
            updated = await cur.fetchone()

            # Seed review row for the newly unlocked lesson
            await _ensure_review_rows_for_unlocked_lessons(con, updated[0])

        await con.commit()

    return UserOut(user_id=updated[0], username=updated[1], active_lesson=updated[2], lessons=updated[3])

# --- advance (by username) ---
@app.post("/users/by-username/{username}/advance", response_model=UserOut)
async def advance_user_to_next_lesson_by_username(username: str):
    async with pool.connection() as con:
        async with con.cursor() as cur:
            # Load user by username
            await cur.execute('SELECT user_id, username, active_lesson, lessons FROM public."user" WHERE username = %s', (username,))
            user = await cur.fetchone()
            if not user:
                raise HTTPException(404, "User not found")
            user_id, _username, active_lesson, _lessons = user
            if active_lesson is None:
                raise HTTPException(400, "User has no active lesson")

            # Verify 3-in-a-row on active lesson
            await cur.execute("""
              SELECT a.is_correct
              FROM attempt a
              JOIN problem p ON p.id = a.problem_id
              WHERE a.user_id = %s AND p.lesson_id = %s
              ORDER BY a.created_at DESC, a.id DESC
              LIMIT 3
            """, (user_id, active_lesson))
            rows = await cur.fetchall()
            if len(rows) < 3 or not all(r[0] for r in rows):
                raise HTTPException(403, "Unlock requires 3 correct attempts in a row on the current lesson")

            # Next lesson
            await cur.execute("""SELECT id FROM lesson ORDER BY created_at ASC, id ASC""")
            all_lessons = [r[0] for r in await cur.fetchall()]
            if active_lesson not in all_lessons:
                raise HTTPException(400, "Active lesson not found in lesson list")
            idx = all_lessons.index(active_lesson)
            if idx == len(all_lessons) - 1:
                raise HTTPException(400, "No next lesson to advance to")
            next_lesson = all_lessons[idx + 1]

            # Update user
            await cur.execute("""
              UPDATE public."user"
              SET active_lesson = %s,
                  lessons = CASE
                      WHEN NOT (%s = ANY(lessons)) THEN array_append(lessons, %s)
                      ELSE lessons
                  END
              WHERE user_id = %s
              RETURNING user_id, username, active_lesson, lessons
            """, (next_lesson, next_lesson, next_lesson, user_id))
            updated = await cur.fetchone()

            # Seed review row for the newly unlocked lesson
            await _ensure_review_rows_for_unlocked_lessons(con, updated[0])

        await con.commit()

    return UserOut(user_id=updated[0], username=updated[1], active_lesson=updated[2], lessons=updated[3])

# --- reporting: last attempt per lesson ---
@app.get("/users/by-username/{username}/last-attempts-per-lesson", response_model=List[LastAttemptPerLesson])
async def last_attempts_per_lesson_by_username(username: str):
    # resolve user_id
    async with pool.connection() as con:
        async with con.cursor() as cur:
            await cur.execute('SELECT user_id FROM public."user" WHERE username = %s', (username,))
            row = await cur.fetchone()
            if not row:
                raise HTTPException(404, "User not found")
            user_id = row[0]

    q = """
    WITH joined AS (
      SELECT a.id, a.user_id, p.lesson_id, a.created_at
      FROM attempt a
      JOIN problem p ON p.id = a.problem_id
      WHERE a.user_id = %s
    ),
    ranked AS (
      SELECT *,
             ROW_NUMBER() OVER (
               PARTITION BY user_id, lesson_id
               ORDER BY created_at DESC, id DESC
             ) AS rn
      FROM joined
    )
    SELECT user_id, lesson_id, created_at AS last_attempt_utc
    FROM ranked
    WHERE rn = 1
    ORDER BY lesson_id
    """
    async with pool.connection() as con:
        async with con.cursor() as cur:
            await cur.execute(q, (user_id,))
            rows = await cur.fetchall()

    return [
        LastAttemptPerLesson(
            user_id=r[0],
            lesson_id=r[1],
            last_attempt_utc=r[2],
        )
        for r in rows
    ]

# --- spaced repetition: next review ---
@app.get("/users/by-username/{username}/next-review", response_model=Optional[NextReviewOut])
async def next_review_by_username(username: str):
    """
    Returns the earliest (soonest) review row for this user across unlocked lessons.
    May be in the future (client can decide whether it's due yet).
    """
    async with pool.connection() as con:
        async with con.cursor() as cur:
            # resolve user
            await cur.execute('SELECT user_id, lessons FROM public."user" WHERE username = %s', (username,))
            user = await cur.fetchone()
            if not user:
                raise HTTPException(404, "User not found")
            user_id, lessons_array = user
            # ensure a row exists per unlocked lesson
            await _ensure_review_rows_for_unlocked_lessons(con, user_id)

            # pick the soonest due across those lessons
            await cur.execute("""
              SELECT ulr.lesson_id, ulr.due_at, ulr.box
              FROM user_lesson_review ulr
              WHERE ulr.user_id = %s
              ORDER BY ulr.box ASC ,ulr.due_at ASC
              LIMIT 1
            """, (user_id,))
            row = await cur.fetchone()
        await con.commit()

    if not row:
        return None
    return NextReviewOut(lesson_id=row[0], due_at=row[1], box=row[2])
