#lang racket
(require web-server/servlet
         web-server/servlet-env
         web-server/dispatch
         json
         racket/port
         racket/path)

;; JSON response helper
(define (json-response code data)
  (response/output
   #:code code
   #:headers (list (header #"Content-Type" #"application/json"))
   (λ (out) (write-json data out))))

;; -------- /validate handler --------
(define (handle-validate req)
  (let/ec abort
    (with-handlers ([exn:fail?
                     (λ (e)
                       (abort (json-response
                               400
                               (hash 'ok #f
                                     'error "bad request"
                                     'details (hash 'message (exn-message e))))))])
      (define body-bytes (request-post-data/raw req))

      ;; Find racket binary
      (define racket-bin
        (or (find-executable-path "racket")
            (and (file-exists? "/usr/bin/racket") (string->path "/usr/bin/racket"))
            (and (file-exists? "/usr/local/bin/racket") (string->path "/usr/local/bin/racket"))))
      (unless racket-bin
        (abort (json-response
                500
                (hash 'ok #f
                      'error "racket binary not found"
                      'details (hash 'hint "ensure racket is installed and in PATH"
                                     'tried '("find-executable-path" "/usr/bin/racket" "/usr/local/bin/racket"))))))

      ;; Resolve validator path
      (define validator-path
        (cond [(file-exists? "/srv/validator.rkt") (string->path "/srv/validator.rkt")]
              [(file-exists? "validator.rkt")      (string->path "validator.rkt")]
              [else #f]))
      (unless validator-path
        (abort (json-response
                500
                (hash 'ok #f
                      'error "validator.rkt not found"
                      'details (hash 'tried '("/srv/validator.rkt" "./validator.rkt"))))))

      ;; Spawn validator
      (define-values (proc stdout stdin stderr)
        (with-handlers ([exn:fail?
                         (λ (e)
                           (abort (json-response
                                   500
                                   (hash 'ok #f
                                         'error "subprocess spawn failed"
                                         'details (hash 'message (exn-message e)
                                                        'racket (path->string racket-bin)
                                                        'validator (path->string validator-path))))))])
          (subprocess #f #f #f racket-bin validator-path)))

      ;; Send body to validator STDIN
      (display (bytes->string/utf-8 body-bytes) stdin)
      (flush-output stdin)
      (close-output-port stdin)

      ;; Read outputs
      (define out-str (port->string stdout))
      (define err-str (port->string stderr))
      (close-input-port stdout)
      (close-input-port stderr)
      (subprocess-wait proc)

      (cond
        [(not (string=? err-str ""))
         (json-response
          200
          (hash 'ok #f
                'error "runner stderr"
                'details (hash 'stderr err-str)))]
        [else
         (with-handlers ([exn:fail?
                          (λ (_)
                            (json-response
                             200
                             (hash 'ok #f
                                   'error "invalid runner output"
                                   'details (hash 'output out-str))))])
           (json-response 200 (string->jsexpr out-str)))]))))

;; -------- Dispatcher --------
(define-values (dispatcher _)
  (dispatch-rules
   [("health")   #:method "get"  (λ (req) (json-response 200 (hash 'ok #t)))]
   [("validate") #:method "post" handle-validate]
   [else (λ (req) (json-response 404 (hash 'ok #f 'error "not found")))]))

(serve/servlet dispatcher
  #:port 8080
  #:servlet-regexp #rx""
  #:launch-browser? #f
  #:listen-ip #f)
