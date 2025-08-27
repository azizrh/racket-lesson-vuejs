#lang racket
(require json
         racket/sandbox
         racket/string
         racket/match)

(define (write-jsonln x) (write-json x) (newline))

(define (fail msg details)
  (write-jsonln (hash 'ok #f 'stage "eval" 'error msg 'details details)))

(define (ok details)
  (write-jsonln (hash 'ok #t 'stage "eval" 'details details)))

;; Try both symbol and string keys. If absent, return default.
(define (hash-ref* h k [default (λ () (error 'hash-ref* "no key"))])
  (cond [(hash-has-key? h k)        (hash-ref h k)]
        [(and (symbol? k) (hash-has-key? h (symbol->string k)))
         (hash-ref h (symbol->string k))]
        [(and (string? k) (hash-has-key? h (string->symbol k)))
         (hash-ref h (string->symbol k))]
        [else (if (procedure? default) (default) default)]))

(define (has-key*? h k)
  (or (hash-has-key? h k)
      (and (symbol? k)  (hash-has-key? h (symbol->string k)))
      (and (string? k)  (hash-has-key? h (string->symbol k)))))

(define in-str (port->string (current-input-port)))

(with-handlers ([exn:fail?
                 (λ (e)
                   (fail "validator json parse failed"
                         (hash 'message (exn-message e) 'input in-str)))])
  (define payload (string->jsexpr in-str))

  (define mode  (hash-ref* payload 'mode "eval"))
  (define lang  (hash-ref* payload 'lang "racket/base"))
  (define submission (hash-ref* payload 'submission #f))
  (define tests0 (hash-ref* payload 'tests '()))

  (when (or (not submission) (not (string? submission)))
    (fail "submission must be a string" (hash)))

  ;; Normalise tests to a list
  (define tests
    (cond [(vector? tests0) (vector->list tests0)]
          [(list?   tests0) tests0]
          [else '()]))

  ;; Make a sandboxed evaluator
;; Normalize language to a module symbol (e.g., 'racket/base)
(define lang-mod
  (cond [(symbol? lang) lang]
        [(string? lang) (string->symbol lang)]
        [else 'racket/base]))

(define ev
  (parameterize ([sandbox-output (open-output-string)]
                 [sandbox-error-output (open-output-string)]
                 [sandbox-path-permissions '((read "/"))])
    (make-evaluator lang-mod)))


  (call-with-limits
   2.0   ; seconds
   256   ; MB
   (λ ()
     ;; Evaluate the student's submission once
     (define submission-val
       (with-handlers ([exn:fail?
                        (λ (e)
                          (fail "submission evaluation error"
                                (hash 'message (exn-message e)
                                      'submission submission)))])
         (ev (with-input-from-string submission read))))

     ;; Run tests
     (define results
       (for/list ([t tests] [i (in-naturals)])
         (cond
           ;; expect: numeric literal comparison
           [(and (has-key*? t 'expect)
                 (number? (hash-ref* t 'expect #f)))
            (define expected (hash-ref* t 'expect #f))
            (define pass? (equal? submission-val expected))
            (hash 'index i 'type "expect"
                  'expected expected
                  'actual submission-val
                  'pass pass?)]

           ;; expr: evaluate an expression and compare
           [(and (has-key*? t 'expr)
                 (string? (hash-ref* t 'expr #f)))
            (define expr-str (hash-ref* t 'expr #f))
            (define expr-val
              (with-handlers ([exn:fail?
                               (λ (e) (list 'error (exn-message e)))])
                (ev (with-input-from-string expr-str read))))
            (define pass?
              (and (not (and (list? expr-val) (eq? (first expr-val) 'error)))
                   (equal? submission-val expr-val)))
            (hash 'index i 'type "expr"
                  'expr expr-str
                  'exprValue expr-val
                  'actual submission-val
                  'pass pass?)]

           ;; invalid test entry
           [else
            (hash 'index i 'type "invalid" 'pass #f
                  'reason "each test needs numeric 'expect' or string 'expr'")])))

     (ok (hash 'tests (length tests)
               'passed (for/sum ([r results])
                         (if (hash-ref r 'pass #f) 1 0))
               'results results
               'value submission-val)))))
