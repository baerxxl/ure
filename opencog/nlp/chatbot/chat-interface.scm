;
; chat-interface.scm
;
; Simple scheme interface to glue together the chat-bot to the cog-server.
; 
; Linas Vepstas April 2009
;

(use-modules (ice-9 rdelim))  ; for the system call

;; Hack to flush IO except this hack doesn't work :-(
;; doesn't work because of how the SchemEval.cc handles ports ... 
(define (fflush) (force-output (car  (fdes->ports 1))))

; -----------------------------------------------------------------------
; Debug printing support.  Turnging on debug printing will prevent
; output from being sent to the chat room.  It is still printed by the
; chatbot to its stdout, and so can be debugged there. The chat client
; explicitly looks for ":dbg" and ":end-dbg" in the chat stream.
;
(define (dbg-display x)
	(display "\n:dbg\n")
	(display x)
)
(define (end-dbg-display)
	(display "\n:end-dbg\n")
)

; -----------------------------------------------------------------------
; pseudo-multi-threading hack. The core problem here is the
; command-response nature of the current opencog server design,
; coupled to the fact that no response is generated until the 
; command completes, and that no response is possible after the 
; command completes. So instead, the chat server needs to poll
; the opencog server to see if there's more output expected.
;
; It would be nice to use call-with-current-continuation but 
; unfortuantely, scm_with_guile() erects a continuation barrier,
; making this hard/impossible. Argh.
;

(define (chat-return x)
	(throw 'cog-yield 
		(string-join 
			; Must use \r here, not \n, as else the chatbot will screw up.
			(list "\n:scm hush\r "
				(call-with-output-string (lambda (y) (display x y)))
				"\n"
			)
		)
	)
)

; -----------------------------------------------------------------------
; chat-get-simple-answer -- get single-word replies to a question.
;
; This is a super-dooper cheesy way of reporting the answer to a question.
; Right now, its looks for Nodes attached, via ListLink, to an 
; AnchorNode called "# QUERY SOLUTION". Some other stage of processing 
; needs to have attached the nodes to this anchor.
;
; Anyway, three different kinds of things can be found:
; WordNodes, almost always "yes", in answer to a yes/no question.
; WordInstanceNodes, in answer to simple pattern matching.
; SemeNodes, in answer to triples matching.
; A list of these "answers" is returned.
; 
(define query-soln-anchor (AnchorNode "# QUERY SOLUTION"))
(define (chat-get-simple-answer)
	(define (do-one-answer answ)
		(let ((tipo (cog-type answ)))
			(cond 
				((eq? tipo 'WordNode) answ)
				((eq? tipo 'WordInstanceNode) (word-inst-get-lemma answ))
				((eq? tipo 'SemeNode) 
					; the lemma-link for a seme might still be sitting on disk!
					(load-referers answ)
					(word-inst-get-lemma answ)
				)

				; Explicitly ignore VariableNodes, these can be there
				; due to ImplicationLinks ... 
				((eq? tipo 'VariableNode) '())
				(else '())
			)
		)
	)
	(delete-duplicates! ;; remove dup answers
		(remove! null?     ; remove nulls
			(map            ; get each answer ... 
				(lambda (x) (do-one-answer (cadr (cog-outgoing-set x)))) 
				(cog-incoming-set query-soln-anchor)
			)
		)
	)
)
(define (chat-delete-simple-answer)
	(for-each (lambda (x) (cog-delete x)) 
		(cog-incoming-set query-soln-anchor)
	)
)

; -----------------------------------------------------------------------
; chat-prt-soln -- print a list of words as the answer to a question
;
; Typically, this routine will be used to print single-word replies
; e.g. "yes", but sometimes a list of words shows up for extensive
; questions (e.g. "what is an instrument" lists many instruments)
;
(define (chat-prt-soln soln-list)
	(define (do-prt-soln soln-list)
		;; display *all* items in the list.
		(define (show-item wlist)
			(if (not (null? wlist))
				(let ((wrd (car wlist)))
					(if (null? wrd)
						(display "(null)")
						(display (cog-name wrd))
					)
					(display " ")
					(show-item (cdr wlist))
				)
			)
		)
		(display "The answer to your question is: ")
		(show-item soln-list)
	)

	(if (not (null? soln-list))
		(do-prt-soln soln-list)
	)
)

; -----------------------------------------------------------------------
; say-id-english -- process user input from chatbot.
; args are: user nick from the IRC channel, and the text that the user 
; entered.
;
; IMPORTANT NOTE: To get semi-interactive I/O while potentially lengthly
; processing is going on, the processing as been split into stages,
; designed so that each stage returns from the scheme interpreter,
; with some output for the chatbot.  The next stage of processing can
; then be continued by writing "\n:scm hush\r (scheme code)\n" to the 
; chat processor. The "\n:scm" and the "\r" are both important parts of
; the syntax, as the chat bridge looks for these. Don't mess them up.
; Or use (chat-return ) instead.
;
; This interactive design is not very pretty, and it would be better
; to come up with some sort of multi-threaded design, with one of the 
; threads listening on the scheme port.  FIXME XXX This should be fixed,
; because the current approach has *many* problems. However, the fix is
; hard, so we just punt for now.
;
(define (say-id-english nick txt)

	; Declare some state variables for the imperative style to follow
	(define sents '())
	(define is-question #f)

	(display "Hello ")
	(display nick)
	; (display ", parsing ...\n")
	(display ", cogita is currently broken, but will try anyway ...\n")

	; Parse the input, send it to the question processor
	(relex-parse txt)

	(set! sents (get-new-parsed-sentences))

	; Hmm. Seems like sents is never null, unless there's a 
	; programmig error in RelEx.  Otherwise, it always returns 
	; something, even if the input was non-sense.
	(if (null? sents)
		(let ()
			(display nick)
			(display ", you said: \"")
			(display txt)
			(display "\" but I couldn't parse that.")
			(newline)
		)

		; Perform a simple pattern matching to the syntactic
		; form of the sentence.
		(set! is-question (cog-ad-hoc "question" (car sents)))
	)

	;; Was a question asked?
	(if is-question 
		(let ((ans (chat-get-simple-answer)))
			(display nick)
			(display ", you asked a question: ")
			(display txt)
			(newline)

			; If pattern-matching found an answer, print it.
			(if (null? ans)
				(display "There was no simple answer; attempting triples search\n")
				(chat-prt-soln ans)
			)
		)
		(let ()
			(display nick)
			(display ", you made a statement: ")
			(display txt)
			(newline)
		)
	)

	; Invoke the next step of processing.
	(chat-return (list "say-part-2 " is-question))
)

; -----------------------------------------------------------------------
; re-anchor the result triples
;
(define bottom-anchor (AnchorNode "# TRIPLE BOTTOM ANCHOR"))
(define (anchor-bottom-side trip-list)
	(define (re-anchor-one trip)
		(let* ((ll (cadr (cog-outgoing-set trip)))
				(li (cadr (cog-outgoing-set ll)))
				)
			(ListLink (stv 1 1) bottom-anchor li)
		)
	)
	(map re-anchor-one trip-list)
)

(define (delete-bottom-anchor)
   (for-each (lambda (x) (cog-delete x))
      (cog-incoming-set bottom-anchor)
   )
)


; -----------------------------------------------------------------------
; say-part-2 -- run part 2 of the chat processing
; The first part, "say-id-english", parsed the user input, and made
; some quick replies. Processing continues below.
;
(define (say-part-2 is-question)

	; Run the triples processing.
	(attach-sents-for-triple-processing (get-new-parsed-sentences))
	(create-triples)
	(dettach-sents-from-triple-anchor)

   ; If a question was asked, and the simple syntactic pattern matching
   ; failed to come up with anything, then try again with pattern
   ; matching on the triples.
   (if (and is-question (null? (chat-get-simple-answer)))
		(let* ((trips (get-new-triples))
				; We need to anchor becasue of ??? why?
				(ancs (anchor-bottom-side trips))

				; Pull in any semes that might be related...
				(s (fetch-related-semes trips))

				; Now try to find answers to the question
				(rslt (cog-ad-hoc "do-varscope" quest-rule-vscope-0))

				; The do-varscope returns a list-link. We need to nuke
				; that, as it will only cause trouble later.
				(ax (cog-delete rslt))
				(ans (chat-get-simple-answer))
			)
(dbg-display "duude question trips are:\n")
(display trips)
(end-dbg-display)

			(if (null? ans)
				(let ()
					(display "No triples found, attempting deduction.\n")
					(chat-return "(say-part-3)")
				)
				(let ()
					; print, and skip to the end of processing
					(chat-prt-soln ans)
					(chat-return "(say-final-cleanup)")
				)
			)
		)
	)

	; Invoke the next step of processing.
	(if is-question
		(chat-return "(say-part-3)")
		(chat-return "(say-final-cleanup)")
	)
)

; -----------------------------------------------------------------------
; convert hypothetical isa to plain is but nuke the truth value
; This is needed for PLN.

(define (hypothetical-to-uncertain triple)
	(EvaluationLink
		(DefinedLinguisticRelationshipNode "isa")
		(cadr (cog-outgoing-set triple))
	)
)

; -----------------------------------------------------------------------
; say-part-3 -- run part 3 of the chat processing
; This attempts to do some basic deduction
;
(define (say-part-3)

	; If we still don't have an answer, try making a deduction
	; (this is an extremely simple-minded hack right now)
	; First, the question needs to be promoted to semes,
	(let* ((trips (get-new-triples))
			(trip-semes (promote-to-seme same-lemma-promoter trips))
		)
		(if (not (null? trip-semes))
			(let* ((ftrip (car trip-semes))
					(ans (cog-ad-hoc "do-varscope" (make-simple-chain ftrip)))
				)
(dbg-display "duude trip-semes are:\n")
(display trip-semes)
(newline)
(display"and the chain is\n")
(display (make-simple-chain ftrip))
(end-dbg-display)
				(if ans
					(display "Yes.\n")
					(display "Simple deduction found no answer.\n")
				)
			)
		)
	)

	; Call the final stage
	(newline)
	"\n:scm hush\r (say-final-cleanup)"
)

; -----------------------------------------------------------------------
; say-final-cleanup -- run cleanup of the chat processing
;
(define (say-final-cleanup)

(display "duude cleaning up now\n")
(newline)

	; Delete re-anchored triples
	(delete-bottom-anchor)

	; Delete list of triples, so they don't interfere with the next question.
	(delete-result-triple-links)

	; Delete  the list of solutions, so that we don't accidentally
	; replay it when the next question is asked.
	(chat-delete-simple-answer)

	; cleanup -- these sentences are not new any more
	(delete-new-parsed-sent-links)
	""
)

; -----------------------------------------------------------------------
