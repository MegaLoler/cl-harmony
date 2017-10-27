(ql:quickload :dexador)
(ql:quickload :websocket-driver-client)
(ql:quickload :jonathan)


;; (TODO:) we should move this into a util.lisp file eventually
(defun str-concat (&rest strings)
  (apply #'concatenate 'string strings))


(defstruct (bot (:constructor primitive-bot-make))
  (token "" :type string :read-only t)
  (version "0.0.1" :type string)
  (url "N/A" :type string)
  (base-url "" :type string)
  (suffix "" :type string))

(defun make-bot (token &key
			 (version "0.0.1")
			 (url "N/A")
			 (api-ver "v6")
			 (suffix "/?v=6&encoding=json"))
  (unless token (error "No token specified!"))
  (primitive-bot-make :token token
		      :version version
		      :url url
		      :base-url (str-concat "https://discordapp.com/api/"
					    api-ver
					    "/")))

(defun user-agent (bot)
  (str-concat "DiscordBot (" (bot-url bot) ", " (bot-version bot) ")"))

(defun headers (bot &optional (length 0))
  (list (cons "Authorization" (str-concat "Bot " (bot-token bot)))
        (cons "User-Agent" (user-agent bot))
        (cons "Content-length" (format nil "~a" length))))

;; is 'get' reserved?
(defun get-rq (bot endpoint)
  (dex:get (str-concat (bot-base-url bot) "/" endpoint (bot-suffix bot))))

;; i added -rq to make the name match get-rq for now
(defun post-rq (endpoint bot)
  (dex:post (str-concat (bot-base-url bot) "/" endpoint (bot-suffix bot))
	    :headers (headers bot)))

(defun gateway (bot)
  (get-rq bot "gateway"))

(defun fetch-gateway-url (bot)
  (cadr (jonathan:parse (gateway bot))))

;; should this be combined with the above?
(defun gateway-url (bot)
  (str-concat (fetch-gateway-url bot) (bot-suffix bot)))

(defun make-ws-client (url)
  (wsd:make-client url))

;; i cant think off the top of my head the best way to structure these things
;; a lot of these can probably be merged
;; or better named
(defun get-ws-client (bot)
  (make-ws-client (gateway-url bot)))

;; im note sure what the *var* convention is, so im just going by the examples :p
(defun connect (bot)
  (defvar *client* (get-ws-client bot))
  (wsd:start-connection *client*)
  (wsd:on :message *client*
          (lambda (message)
	    (on-recv (jonathan:parse message)))))

;; on receive websock messages by opcode
;; opcode 0
(defun on-recv-dispatch (msg)
  nil)

;; opcode 1
(defun on-recv-heartbeat (msg)
  nil)

;; opcode 2
(defun on-recv-identify (msg)
  nil)

;; opcode 3
(defun on-recv-status-update (msg)
  nil)

;; opcode 4
(defun on-recv-voice-status-update (msg)
  nil)

;; opcode 5
(defun on-recv-voice-server-ping (msg)
  nil)

;; opcode 6
(defun on-recv-resume (msg)
  nil)

;; opcode 7
(defun on-recv-reconnect (msg)
  nil)

;; opcode 8
(defun on-recv-request-guild-members (msg)
  nil)

;; opcode 9
(defun on-recv-invalid-session (msg)
  nil)

;; opcode 10
(defun on-recv-hello (msg)
  (let ((heartbeat (getf (getf msg :|d|) :heartbeat_interval)))
    (print (str-concat "Heartbeat: " heartbeat))))

;; opcode 11
(defun on-recv-heartbeat-ack (msg)
  nil)

;; receive message from websock and dispatch to handler
(defun on-recv (msg)
  (print "Hello at all??")
  (let ((op (getf msg :|op|)))
    (cond ((= op 0)
	   (on-recv-dispatch msg))
	  ((= op 1)
	   (on-recv-heartbeat msg))
	  ((= op 2)
	   (on-recv-identify msg))
	  ((= op 3)
	   (on-recv-status-update msg))
	  ((= op 4)
	   (on-recv-voice-status-update msg))
	  ((= op 5)
	   (on-recv-voice-server-ping msg))
	  ((= op 6)
	   (on-recv-resume msg))
	  ((= op 7)
	   (on-recv-reconnect msg))
	  ((= op 8)
	   (on-recv-request-guild-members msg))
	  ((= op 9)
	   (on-recv-invalid-session msg))
	  ((= op 10)
	   (on-recv-hello msg))
	  ((= op 11)
	   (on-recv-heartbeat-ack msg))
	  (T
	    ;; not sure if this should be an error to the user or not?
	    (error "Received invalid opcode!")))))
