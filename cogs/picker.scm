(require "helix/configuration.scm")
(require "helix/misc.scm")

(require "helix/components.scm")
(require (prefix-in helix. "helix/commands.scm"))

(require "helix/editor.scm")
(require (prefix-in helix.static. "helix/static.scm"))

(provide picker-selection)

(define (for-each-index func lst index)
  (if (null? lst)
      void
      (begin
        (func index (car lst))
        (when (null? lst)
          (return! void))
        (for-each-index func (cdr lst) (+ index 1)))))

;; Text field that can only be appended to - so either, push/pop/etc.
;; Swap and update in place in order to take advantage of it?
(struct MutableTextField (text) #:mutable)

;; We're not locking the text here, so use wisely
(define (push-character field char)
  ;; TODO: Try to use a list of characters instead?
  (define text (MutableTextField-text field))
  (set-MutableTextField-text! field '())
  (set-MutableTextField-text! field (cons char text)))

(define (pop-character field)
  (define text (MutableTextField-text field))
  (set-MutableTextField-text! field '())
  (set-MutableTextField-text! field
                              (if (empty? text)
                                  text
                                  (cdr text))))

(define (text-field->string field)
  (~> (MutableTextField-text field) reverse list->string))

;; The callback to call with the value found at that list
;; The list of items to be rendered, and the callback to call
;; with the value found at that list
(struct Picker
        (items items-view
               callback
               ;; Function to call to render the preview space
               preview-func
               ;; The input text buffer to perform fuzzy matching with
               text-buffer
               ;; the position in the list of items
               cursor
               ;; The max length to display. For now, this is initialized
               ;; to an empty box
               max-length
               ;; Where the window will start in the list
               window-start
               ;; How to format the item to show in the list
               value-formatter
               ;; If present, prefix the selected item with this
               highlight-prefix
               ;; The style to highlight the lines that are not selected
               default-style
               ;; The style to highlight the selected lines
               highlight-style
               ;; The cursor position
               cursor-position
               ;; Optional title shown above the search input
               title))

;; Moves the cursor down
(define (move-cursor-down picker)
  (define items-len (length (unbox (Picker-items-view picker))))
  (when (> items-len 0)
    (define current (Picker-cursor picker))
    (define window-start (Picker-window-start picker))

    (set-box! current (modulo (+ 1 (unbox current)) items-len))

    (when (> (unbox current) (+ (unbox window-start) (- (unbox (Picker-max-length picker)) 2)))
      (set-box! window-start (+ (unbox window-start) 1)))

    (when (< (unbox current) (unbox window-start))
      (set-box! window-start (unbox current)))))

(define (saturating-sub x y)
  (max (- x y) 0))

;; Moves the cursor up
(define (move-cursor-up picker)
  (define items-len (length (unbox (Picker-items-view picker))))
  (when (> items-len 0)
    (define current (Picker-cursor picker))
    (define window-start (Picker-window-start picker))

    (set-box! current (modulo (- (unbox current) 1) items-len))

    ;; Adjust viewport
    (when (< (unbox current) (unbox window-start))
      (set-box! window-start (- (unbox window-start) 1)))

    ;; Wrap around
    (when (> (unbox current) (+ (unbox window-start) (- (unbox (Picker-max-length picker)) 2)))
      (set-box! window-start
                (saturating-sub (unbox current) (- (unbox (Picker-max-length picker)) 2))))))

(define (picker-cursor-handler state _)
  (Picker-cursor-position state))

(define (picker-event-handler state event)
  (define char (key-event-char event))

  (cond
    ;; Consume, and enqueue a callback to close it
    [(key-event-escape? event) event-result/close]

    [(key-event-down? event)
     (move-cursor-down state)
     event-result/consume]

    [(key-event-up? event)
     (move-cursor-up state)
     event-result/consume]

    [(key-event-tab? event)
     (if (equal? (key-event-modifier event) key-modifier-shift)
         (move-cursor-up state)
         (move-cursor-down state))

     event-result/consume]

    ;; Map the current cursor -> item in the list
    ;; Call the function on that, close
    [(key-event-enter? event)
     (define view (unbox (Picker-items-view state)))
     (when (not (null? view))
       (define callback (Picker-callback state))
       (callback (list-ref view (unbox (Picker-cursor state)))))
     event-result/close]
    [(key-event-backspace? event)
     (pop-character (Picker-text-buffer state))

     (set-box! (Picker-items-view state)
               (fuzzy-match (text-field->string (Picker-text-buffer state))
                            (Picker-items state)))
     (set-box! (Picker-cursor state) 0)
     (set-box! (Picker-window-start state) 0)

     event-result/consume]
    [(char? char)
     (push-character (Picker-text-buffer state) char)

     (set-box! (Picker-items-view state)
               (fuzzy-match (text-field->string (Picker-text-buffer state))
                            (Picker-items state)))
     (set-box! (Picker-cursor state) 0)
     (set-box! (Picker-window-start state) 0)

     event-result/consume]

    [(mouse-event? event) event-result/ignore]

    [else event-result/consume]))

(define (picker-render state rect frame)
  (define cursor-position (unbox (Picker-cursor state)))

  (define half-parent-height (exact (round (/ (area-height rect) 2))))
  (define starting-y-offset (exact (round (/ (area-height rect) 4))))

  (define has-preview (function? (Picker-preview-func state)))

  (define list-width
    (if has-preview
        (exact (round (/ (area-width rect) 2)))
        (exact (round (/ (area-width rect) 2.5)))))

  (define starting-x-offset
    (exact (round (/ (- (area-width rect) list-width) 2))))

  (define block-area
    (area starting-x-offset
          (- starting-y-offset 1)
          list-width
          (+ 10
             (if (> (+ half-parent-height starting-y-offset) (area-height rect))
                 (- (area-height rect) starting-y-offset)
                 half-parent-height))))

  (define x (+ 1 (area-x block-area)))
  (define y (area-y block-area))

  (define start (unbox (Picker-window-start state)))
  (define currently-highlighted (- cursor-position (unbox (Picker-window-start state))))

  (define wide-string (make-string (- (area-width block-area) 2) #\space))

  (set-box! (Picker-max-length state) (area-height block-area))

  (define view-slice
    (slice (unbox (Picker-items-view state)) start (- (unbox (Picker-max-length state)) 1)))

  (define selection (try-list-ref view-slice currently-highlighted))

  (define found-style
    (~> (style)
        (style-bg (style->bg (theme-scope-ref "ui.background")))
        (style-fg (style->fg (theme-scope-ref "ui.text")))))

  (buffer/clear frame block-area)

  (block/render frame
                (area (- (area-x block-area) 1)
                      (- (area-y block-area) 1)
                      (+ 2 (area-width block-area))
                      (+ 2 (area-height block-area)))
                (make-block (theme-scope-ref "ui.background") found-style "all" "plain"))

  (when has-preview
    (define preview-area
      (area (exact (+ starting-x-offset (round (/ list-width 2))))
            (area-y block-area)
            (exact (- (round (/ (area-width block-area) 2)) 2))
            (area-height block-area)))

    (block/render frame
                  preview-area
                  (make-block (theme-scope-ref "ui.background") found-style "all" "plain"))

    (when selection
      ((Picker-preview-func state) state selection preview-area frame)))

  (define title (Picker-title state))
  (define has-title (string? title))

  (define title-scope (theme-scope-ref "ui.text.focus"))
  (define title-style
    (~> (style)
        (style-bg (style->bg (theme-scope-ref "ui.background")))
        (style-fg (style->fg (if title-scope title-scope (theme-scope-ref "ui.text"))))))

  (when has-title
    (frame-set-string! frame x y title title-style))

  (define input-y (if has-title (+ y 1) y))

  (frame-set-string! frame x input-y (text-field->string (Picker-text-buffer state)) found-style)

  (set-position-row! (Picker-cursor-position state) input-y)
  (set-position-col! (Picker-cursor-position state)
                     (+ x (length (MutableTextField-text (Picker-text-buffer state)))))

  (for-each-index
   (lambda (index row)
     (when (< (+ index input-y 1) (+ (area-y rect) (area-height rect)))

       (if (equal? index currently-highlighted)
           (begin
             (frame-set-string! frame
                                x
                                (+ index input-y 1)
                                wide-string
                                found-style)
             (frame-set-string! frame
                                x
                                (+ index input-y 1)
                                (if (string? (Picker-highlight-prefix state))
                                    (string-append (Picker-highlight-prefix state)
                                                   ((Picker-value-formatter state) row))
                                    (string-append "  " ((Picker-value-formatter state) row)))
                                found-style))
           (frame-set-string! frame
                              x
                              (+ index input-y 1)
                              (string-append "  " ((Picker-value-formatter state) row))
                              found-style))))
   view-slice
   0))

(define (default-formatter value)
  (with-output-to-string (lambda () (display value))))

;;@doc
;; Drop down at the given cursor. This does not push the component, but just creates it.
;; You are still responsible to call `push-component!` on this.
(define (picker-selection items
                          on-selection
                          ;; If we have a preview function, we can use it.
                          ;; TODO: Fill in the function signature here
                          #:preview-function [preview-function void]
                          #:value-formatter [formatter default-formatter]
                          #:highlight-prefix [highlight-prefix void]
                          #:default-style [default-style (style)]
                          #:highlight-style [highlight-style (style-bg (style) Color/Gray)]
                          #:title [title void])

  (new-component! "steel-picker"
                  (Picker items
                          ;; Just use a mutable view on to the original items
                          (box items)
                          on-selection
                          preview-function
                          ;; Just use an empty list here
                          (MutableTextField (list))
                          (box 0)
                          (box (- (length items) 1)) ;; Dummy max length
                          (box 0)
                          formatter
                          highlight-prefix
                          default-style
                          highlight-style
                          (position 0 0)
                          title)
                  picker-render
                  (hash "handle_event" picker-event-handler "cursor" picker-cursor-handler)))

; (define (test-list _)
;   (list "foo" "bar" "baz" "bananas" "fuzzy-matching" "this seems to work pretty well"))

; (define (np)
;   (push-component!
;    (picker-selection
;     (flatten (map test-list (range 0 10)))
;     (lambda (_) void)
;     #:preview-function
;     (lambda (picker selection rect frame)
;       (frame-set-string! frame (+ 1 (area-x rect)) (+ 1 (area-y rect)) selection (style)))
;     #:highlight-prefix "> ")))
