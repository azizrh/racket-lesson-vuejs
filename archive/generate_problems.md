You are a problem generator for S-expression math practice.

=== LESSON CONTEXT (use this as ground truth) ===
```markdown
An s-expression always has the form

`<left parenthesis> op data <right parenthesis>`

For example, `(+ 5 6)` is an s-expression that adds 5 to 6.

An s-expression can have multiple spaces in them. The following are valid s-expressions

- `( + 5 6)`
- `(+ 5     6)`
- `( + 5 6 )`
- `(   +  5  6 )`

The one rule is that we must keep at least one space between the operator and the data.

For example, the following is not a valid s-expression:

`(+5 6)`

because there is no space between + and 5.

The following is also not valid:

`(+ 56)`

For neatness purposes, don't put any spaces next to the parentheses even though you are allowed to do so. Also, only use one space between the data and the operator.

Example:

Make the following s-expression neater

( + 32  61 )

Answer:

(+ 32 61)

Example:

Make the following s-expression neater

( + 24  3)

Answer:

(+ 24 3)
```

Make the following s-expression neater:

```lisp
(- 5   2)
```

(- 5 2)

Make the following s-expression neater:

```lisp
( * 5 2)
```

(* 5 2)

Make the following s-expression neater:

```lisp
(*   5 2)
```

(* 5 2)

Make the following s-expression neater:

```lisp
(+ 5 3 )
```

(+ 5 3)

Make the following s-expression neater:

```lisp
( + 2 10)
```

(+ 2 10)
=== END CONTEXT ===

TASK:
Generate exactly 30 unique arithmetic exercises (addition, subtraction, multiplication, or division). Some should be nested, e.g. “(2 + 3) * 4” → “(* (+ 2 3) 4)”. Use only positive integers 1..30. Ensure the S-expression matches the infix prompt exactly (respect order for -, /). All rows must be unique in both the prompt and the S-expression.

OUTPUT FORMAT:
Return EXACTLY 30 SQL INSERT statements, no explanations, no code fences.

Use this exact SQL pattern (replace LESSON_ID if needed):
INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
    1,
    '{PROMPT}',
    '{ANSWER}',
    'racket',
    '{
      "mode": "eval",
      "lang": "racket/base",
      "tests": [ { "expr": "{ANSWER}" } ]
    }'::jsonb
);

CONSTRAINTS:
- Prompt style: “Write 7 + (3 * 2) as an S-expression”
- ANSWER is the correct S-expression (e.g., (+ 7 (* 3 2)))
- Use only +, -, *, / and parentheses
- Integers between 1 and 30
- Mix simple and nested forms
- Exactly 100 INSERTs
- Output ONLY the SQL lines, nothing else
- Escape single quotes in prompts if any appear
