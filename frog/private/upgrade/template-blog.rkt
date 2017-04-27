#lang scribble/text

@;; Evaluates to text for a blog.rkt equivalent of a user's old .frogrc.

@(require racket/format
          racket/function
          "old-config.rkt")

@;; Intended to be used when current directory contains .frogrc.
@(define frogrc ".frogrc")

@(define (get sym def)
   (get-config sym def frogrc))

@(define get/v (compose1 ~v get))

@;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
#lang racket/base

(require frog/params
         frog/enhance-body
         racket/contract
         rackjure/threading
         xml/xexpr)

(provide init
         enhance-body
         clean)

;; Called early when Frog launches. Use this to set parameters defined
;; in frog/params.
(define/contract (init)
  (-> any)
  @;; Many frogrc items directly correspond to parameters that still
  @;; exist, and the user should set in their `init`, here.
  @;; (For the rest, see `enhance-body` below.)
  @(define (p sym def)
     @list{(current-@sym @(get/v sym def))})
  @p['scheme/host "http://www.example.com"]
  @p['uri-prefix #f]
  @p['title "Untitled Site"]
  @p['author "The Unknown Author"]
  @p['editor "$EDITOR"]
  @p['editor-command "{editor} {filename}"]
  @p['show-tag-counts? #t]
  @p['permalink "/{year}/{month}/{title}.html"]
  @p['index-full? #f]
  @p['feed-full? #f]
  @p['max-feed-items 999]
  @p['decorate-feed-uris? #t]
  @p['feed-image-bugs? #f]
  @p['posts-per-page 10]
  @p['index-newest-first? #t]
  @p['posts-index-uri "/index.html"]
  @p['source-dir "_src"]
  @p['output-dir "."])

;; Called once per post and non-post page, on the contents.
(define/contract (enhance-body xs)
  (-> (listof xexpr/c) (listof xexpr/c))
  @;; The remaining frogrc items control whether we call certain
  @;; body-enhancing functions, or, are arguments to them:
  ;; Here we pass the xexprs through a series of functions.
  (~> xs
      @(add-newlines
        (list
         @list{(syntax-highlight #:python-executable @(get/v 'python-executable "python")
                                 #:line-numbers? @(get/v 'pygments-linenos? #t)
                                 #:css-class @(get/v 'pygments-cssclass "source"))}
         @(when (get 'auto-embed-tweets? #t)
            @list{(auto-embed-tweets #:parents? @(get/v 'embed-tweet-parents? #f))})
         @(let ([code?  (get 'racket-doc-link-code? #t)]
                [prose? (get 'racket-doc-link-prose? #f)])
            @(when (or code? prose?)
               @list{(add-racket-doc-links #:code? @~v[code?] #:prose? @~v[prose?])}))))))

;; clean : -> Void
;;
;; Called from `raco frog --clean`.
;;
;; In `enhance-body`, you can call a function that has the side-effect
;; of creating extra files (for example responsive images in a variety
;; of sizes). Such a function should provide a companion you can call
;; to delete those files; call it here.
(define/contract (clean)
  (-> any)
  (void))