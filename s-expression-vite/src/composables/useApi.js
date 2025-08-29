// composables/useApi.js
export function useApi() {
    const API_BASE = import.meta.env.VITE_API_BASE || "/api"

    const listLessons = async () => {
        const res = await fetch(`${API_BASE}/lessons`)
        if (!res.ok) throw new Error("Failed to list lessons")
        return await res.json()
    }

    const loadLesson = async (lessonId) => {
        const res = await fetch(`${API_BASE}/lessons/${lessonId}`)
        if (!res.ok) throw new Error("Lesson not found")
        return await res.json()
    }

    const loadProblems = async (lessonId) => {
        const res = await fetch(`${API_BASE}/lessons/${lessonId}/problems`)
        if (!res.ok) throw new Error("Failed to load problems")
        return await res.json()
    }

    const backendValidate = async (problemId, submission) => {
        const res = await fetch(`${API_BASE}/validate`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ problem_id: problemId, submission }),
        })
        if (!res.ok) {
            const text = await res.text().catch(() => "")
            throw new Error(`Backend error (${res.status}): ${text || "unknown"}`)
        }
        return await res.json()
    }

    //   const recordAttempt = async (username, problemId, submission, backendResult, stage = null) => {
    //     if (!username) return
    //     try {
    //       await fetch(`${API_BASE}/attempts`, {
    //         method: "POST",
    //         headers: { "Content-Type": "application/json" },
    //         body: JSON.stringify({
    //           username,
    //           problem_id: problemId,
    //           submitted_text: submission,
    //           is_correct: !!backendResult.ok,
    //           stage: stage || backendResult.stage || null,
    //           error_reason: backendResult.ok ? null : backendResult.error || null,
    //           details: backendResult.details || null,
    //         }),
    //       })
    //     } catch (e) {
    //       console.warn("Failed to record attempt:", e)
    //     }
    //   }

    const recordAttempt = async (username, problemId, submission, backendResult, stage = null) => {
        if (!username) return
        const res = await fetch(`${API_BASE}/attempts`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({
                username,
                problem_id: problemId,
                submitted_text: submission,
                is_correct: !!backendResult.ok,
                stage: stage || backendResult.stage || null,
                error_reason: backendResult.ok ? null : backendResult.error || null,
                details: backendResult.details || null,
            }),
        })
        if (!res.ok) {
            const text = await res.text().catch(() => "")
            throw new Error(`recordAttempt failed ${res.status}: ${text || "no body"}`)
        }
    }


    const getUserByUsername = async (uname) => {
        const res = await fetch(
            `${API_BASE}/users/by-username/${encodeURIComponent(uname)}`
        )
        if (!res.ok) {
            const text = await res.text().catch(() => "")
            throw new Error(text || `Failed to load user (${res.status})`)
        }
        return await res.json()
    }

    const loginWithUsername = async (username) => {
        const res = await fetch(`${API_BASE}/login`, {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ username }),
        })
        if (!res.ok) {
            const text = await res.text().catch(() => "")
            throw new Error(text || `Login failed (${res.status})`)
        }
        return await res.json()
    }

    const advanceUser = async (username) => {
        const res = await fetch(
            `${API_BASE}/users/by-username/${encodeURIComponent(username)}/advance`,
            { method: "POST" }
        )
        if (!res.ok) {
            const text = await res.text().catch(() => "")
            throw new Error(text || `Advance failed (${res.status})`)
        }
        return await res.json()
    }

    const fetchNextReviewByUsername = async (username) => {
        try {
            const res = await fetch(
                `${API_BASE}/users/by-username/${encodeURIComponent(username)}/next-review`
            )
            if (!res.ok) return null
            return await res.json()
        } catch {
            return null
        }
    }

    return {
        listLessons,
        loadLesson,
        loadProblems,
        backendValidate,
        recordAttempt,
        getUserByUsername,
        loginWithUsername,
        advanceUser,
        fetchNextReviewByUsername,
    }
}