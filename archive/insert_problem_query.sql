INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write 7 + (3 * 2) as an S-expression',
'(+ 7 (* 3 2))',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(+ 7 (* 3 2))" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write (8 - 5) + 9 as an S-expression',
'(+ (- 8 5) 9)',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(+ (- 8 5) 9)" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write 12 - 4 as an S-expression',
'(- 12 4)',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(- 12 4)" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write 6 * 5 as an S-expression',
'(* 6 5)',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(* 6 5)" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write 20 / 4 as an S-expression',
'(/ 20 4)',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(/ 20 4)" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write 3 + 4 as an S-expression',
'(+ 3 4)',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(+ 3 4)" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write 15 - 9 as an S-expression',
'(- 15 9)',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(- 15 9)" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write 9 + (10 / 2) as an S-expression',
'(+ 9 (/ 10 2))',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(+ 9 (/ 10 2))" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write (5 + 7) * 2 as an S-expression',
'(* (+ 5 7) 2)',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(* (+ 5 7) 2)" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write 18 / (3 + 3) as an S-expression',
'(/ 18 (+ 3 3))',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(/ 18 (+ 3 3))" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write (9 - 2) * 4 as an S-expression',
'(* (- 9 2) 4)',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(* (- 9 2) 4)" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write 14 + (6 - 3) as an S-expression',
'(+ 14 (- 6 3))',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(+ 14 (- 6 3))" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write (4 * 3) + 11 as an S-expression',
'(+ (* 4 3) 11)',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(+ (* 4 3) 11)" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write 25 - (8 + 6) as an S-expression',
'(- 25 (+ 8 6))',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(- 25 (+ 8 6))" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write (12 / 3) + 7 as an S-expression',
'(+ (/ 12 3) 7)',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(+ (/ 12 3) 7)" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write 5 * (2 + 9) as an S-expression',
'(* 5 (+ 2 9))',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(* 5 (+ 2 9))" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write (10 - 4) / 3 as an S-expression',
'(/ (- 10 4) 3)',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(/ (- 10 4) 3)" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write 16 / (2 * 2) as an S-expression',
'(/ 16 (* 2 2))',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(/ 16 (* 2 2))" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write (7 + 8) / 5 as an S-expression',
'(/ (+ 7 8) 5)',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(/ (+ 7 8) 5)" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write 19 - (5 * 3) as an S-expression',
'(- 19 (* 5 3))',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(- 19 (* 5 3))" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write (6 + 6) - 4 as an S-expression',
'(- (+ 6 6) 4)',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(- (+ 6 6) 4)" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write 8 * (3 - 1) as an S-expression',
'(* 8 (- 3 1))',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(* 8 (- 3 1))" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write (9 * 2) - 7 as an S-expression',
'(- (* 9 2) 7)',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(- (* 9 2) 7)" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write 22 - (12 / 3) as an S-expression',
'(- 22 (/ 12 3))',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(- 22 (/ 12 3))" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write (5 + 5) + (6 * 2) as an S-expression',
'(+ (+ 5 5) (* 6 2))',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(+ (+ 5 5) (* 6 2))" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write (18 - 9) + (3 * 4) as an S-expression',
'(+ (- 18 9) (* 3 4))',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(+ (- 18 9) (* 3 4))" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write 21 / (7 - 4) as an S-expression',
'(/ 21 (- 7 4))',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(/ 21 (- 7 4))" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write (8 + 12) / (5 - 2) as an S-expression',
'(/ (+ 8 12) (- 5 2))',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(/ (+ 8 12) (- 5 2))" } ]
}'::jsonb
);

INSERT INTO problem (lesson_id, prompt_text, answer_text, validator_kind, validator_spec)
VALUES (
1,
'Write (9 - 3) * (4 + 2) as an S-expression',
'(* (- 9 3) (+ 4 2))',
'racket',
'{
"mode": "eval",
"lang": "racket/base",
"tests": [ { "expr": "(* (- 9 3) (+ 4 2))" } ]
}'::jsonb
);
