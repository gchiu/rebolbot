Rebol [
	file: %rebolbot.r3
	author: [ "Graham Chiu" "Adrian Sampaleanu" ]
	date: [28-Feb-2013 11-Apr-2013 2-June-2013] ; leave this as a block plz!  It's used by version command
	version: 0.1.1
	purpose: {Perform useful, automated actions in Stackoverflow chat rooms}
	Notes: {You'll need to capture your own cookie and fkey using wireshark or similar.}
	License: 'Apache2
	Needs: [
		%bot-api.r3 
		http://reb4.me/r3/altjson 
		http://reb4.me/r3/altxml
	]
]

;-- optionally load patched version of prot-http.r
; do %prot-my-http.r

system/options/default-suffix: %.r3
command-dir: %commands/

do sync-commands: func [] [
	clear head lib/commands: []
	foreach command read command-dir [
		append lib/commands cmd: import/no-lib rejoin [command-dir command]
	]
]

if not value? 'shrink [
	shrink: load http://www.rebol.org/download-a-script.r?script-name=shrink.r
	eliza: make object! shrink/4
	eliza/rules: shrink/6
]

lib/chat-length-limit: 500 ; SO chat limits to 500 chars if a message contains a link

; config botname - e.g. @MyBot
either exists? %bot-config.r [
	bot-config: object load %bot-config.r
	lib/botname: bot-config/botname
	room-id: bot-config/room-id
	room-descriptor: bot-config/room-descriptor
	lib/greet-message: bot-config/greet-message
	lib/low-rep-message: bot-config/low-rep-message
	bot-cookie: bot-config/bot-cookie
	bot-fkey: bot-config/bot-fkey
] [
	lib/botname: "-- name me --"
	room-id: 0 
	room-descriptor: "-- room name --"
	lib/greet-message: "-- set my welcome message --"
	lib/low-rep-message: "-- set my low reputation message --"
	bot-cookie: "-- get your own --"
	bot-fkey: "-- get your own"
]

; write %bot-config.r compose [
; 	botname: (mold lib/botname) #"^/"
; 	room-id: (room-id) #"^/"
; 	room-descriptor: (mold room-descriptor) #"^/"
; 	greet-message: (mold lib/greet-message) #"^/"
; 	bot-cookie: (mold bot-cookie) #"^/"
; 	bot-fkey: (mold bot-fkey)
; ]

lib/pause-period: 5 ; 5 seconds between each poll of the chat
lib/no-of-messages: 5 ; fetch 5 messages each time
lib/max-scan-messages: 200 ; max to fetch to scan for links by a user

; these users can remove keys - uses userids, the names are there just so that you know who they are!
lib/privileged-users: []

lastmessage-no: 8743137
last-message-file: %lastmessage-no.r

if exists? last-message-file [
	attempt [
		lastmessage-no: load last-message-file
	]
]

?? lastmessage-no

so-chat-url: http://chat.stackoverflow.com/
profile-url: http://stackoverflow.com/users/
chat-target-url: rejoin write-chat-block: [so-chat-url 'chats "/" room-id "/" 'messages/new]
lib/referrer-url: rejoin [so-chat-url 'rooms "/" room-id "/" room-descriptor]
lib/html-url: rejoin [lib/referrer-url "?highlights=false"]
read-target-url: rejoin [so-chat-url 'chats "/" room-id "/" 'events]
delete-url: [so-chat-url 'messages "/" (lib/parent-id) "/" 'delete]

lib/id-rule: charset [#"0" - #"9"]
non-space: complement space: charset #" "

lib/percent-encode: func [char [char!]] [
	char: enbase/base to-binary char 16
	parse char [
		copy char some [char: 2 skip (insert char "%") skip]
	]
	char
]

lib/url-encode: use [ch mk] [
	ch: charset ["-." #"0" - #"9" #"A" - #"Z" #"-" #"a" - #"z" #"~"]
	func [text [any-string!]] [
		either parse/all text: form text [
			any [
				some ch | end | change " " "+" |
				mk: (mk: lib/percent-encode mk/1)
				change skip mk
			]
		] [to-string text] [""]
	]
]

; updated to remove the /local pad
lib/to-itime: func [
	{Returns a standard internet time string (two digits for each segment)}
	time [time! number! block! none!]
] [
	time: make time! time
	rejoin [
		next form 100 + time/hour ":"
		next form 100 + time/minute ":"
		next form 100 + round/down time/second
	]
]

lib/to-idate: func [
	"Returns a standard Internet date string."
	date [date!]
	/local str
] [
	str: form date/zone
	remove find str ":"
	if (first str) <> #"-" [insert str #"+"]
	if (length? str) <= 4 [insert next str #"0"]
	reform [
		pick ["Mon," "Tue," "Wed," "Thu," "Fri," "Sat," "Sun,"] date/weekday
		date/day
		pick ["Jan" "Feb" "Mar" "Apr" "May" "Jun" "Jul" "Aug" "Sep" "Oct" "Nov" "Dec"] date/month
		date/year
		to-itime any [date/time 0:00]
		str
	]
]

; perhaps not all of this header is required
header: compose [
	Host: "chat.stackoverflow.com"
	Origin: "http://chat.stackoverflow.com"
	Accept: "application/json, text/javascript, */*; q=0.01"
	X-Requested-With: "XMLHttpRequest"
	Referer: (lib/referrer-url)
	Accept-Encoding: "gzip,deflate"
	Accept-Language: "en-US"
	Accept-Charset: "ISO-8859-1,utf-8;q=0.7,*;q=0.3"
	Content-Type: "application/x-www-form-urlencoded"
	cookie: (bot-cookie)
]

lib/speak-private: func [message room-id] [
	bind write-chat-block 'room-id
	probe rejoin compose copy write-chat-block
	to string! write rejoin compose copy write-chat-block compose/deep copy/deep [
		POST
		[(header)]
		(rejoin ["text=" lib/url-encode message "&fkey=" bot-fkey])
	]
]

lib/speak: func [message /local err] [
	if error? set/any 'err try [
		to string! write ?? chat-target-url compose/deep copy/deep [
			POST
			[(header)]
			(rejoin ["text=" lib/url-encode ?? message "&fkey=" bot-fkey])
		]
	] [
		mold err
	]
]

lib/read-messages: func [cnt] [
	to string! write read-target-url compose/deep copy/deep [
		POST
		[(header)]
		(rejoin ["since=0&mode=Messages&msgCount=" cnt "&fkey=" bot-fkey])
	]
]

lib/delete-message: func [parent-id message-id /silent
	/local result mess
] [
	; POST /messages/8034726/delete HTTP/1.1
	result: to string! write probe mess: rejoin compose copy delete-url compose/deep copy/deep [
		POST
		[(header)]
		(rejoin ["fkey=" bot-fkey])
	]
	if not silent [
		switch/default result [
			{"It is too late to delete this message"} [lib/reply message-id ["sorry, it's too late to do this now.  Be quicker next time"]]
			{"ok"} [lib/reply message-id ["done"]]
		] [
			lib/reply message-id ["SO says: " result]
		]
	]
]

lib/reply: func [message-id text [string! block!]] [
	if block? text [text: ajoin text]
	lib/speak ajoin [":" message-id " " text]
]

process-dialect: funct [expression
] [
	default-rule: [
		; default .. checks for a word and sends it to the check-keys
		opt '? [set search-key word! | set search-key string!] opt ['for set recipient word!] (
			lib/done: true
			either found? recipient [
				recipient: ajoin ["@" recipient]
			] [
				recipient: copy ""
			]
			process-key-search trim ajoin [?? search-key " " ?? recipient]
		)
	]

	dialect-rule: collect [
		foreach command lib/commands [
			keep/only command/dialect-rule keep '|
		]
	]
	insert tail insert dialect-rule quote ((recipient: none)) default-rule
	lib/done: false

	if error? err: try [
		; what to do about illegal rebol values eg @Graham
		if error? err2: try [
			to block! expression
		] [
			if find mold err2 {arg1: "email"} [
				replace/all expression "@" ""
			]
		]
		probe parse expression: to block! ?? expression ?? dialect-rule
		unless lib/done [lib/reply lib/message-id eliza/match mold expression]
	] [
		; sends error
		lib/reply lib/message-id mold err
		; now uses Eliza
		; lib/reply lib/message-id eliza/match mold expression
	]
]

process-key-search: func [expression
	/local understood search-key person
] [
	understood: false
	set [search-key person] parse expression none
	unless all [
		person
		parse person ["@" to end]
	] [person: none]
	; remove punctuation of ! and ?
	if find [#"!" #"?"] last search-key [remove back tail search-key]
	foreach [key data] ?? lib/bot-expressions [
		if find/part probe key probe search-key length? search-key [
			understood: true
			lib/reply lib/message-id ["[" data/1 "](" data/2 ") " either found? person [person] [""]]
			break
		]
	]
	if not understood [
		; lib/reply message-id [ {sorry "} expression {" is not in my current repertoire.  Try /h for help} ]
		lib/reply lib/message-id eliza/match mold expression
	]
]

bot-cmd-rule: [
	lib/botname some space
	[
		copy key to end (
			; process-key-search message-id trim key
			process-dialect key
		)
	]
]

message-rule: [
	<event_type> quote 1 |
	<time_stamp> integer! |
	<content> set content string! |
	<id> integer! |
	<user_id> set person-id integer! |
	<user_name> set user-name string! |
	<room_id> integer! |
	<room_name> string! |
	<message_id> set message-no integer! |
	<parent_id> set parent-id integer! |
	<show_parent> logic! |
	tag! skip |
	end
	(lib/person-id: person-id lib/user-name: user-name lib/message-id: message-no lib/parent-id: parent-id )
]

; lastmessage-no: 7999529

call-command-pulse: funct[] [
	foreach command lib/commands [
		if all [
			callback: find words-of command 'pulse-callback
			type? :callback = function!
		] [command/pulse-callback]
	]
]

cnt: 0 ; rescan for new users every 10 iterations ( for 5 seconds, that's 50 seconds )
forever [
	++ cnt
	if error? set/any 'errmain try [
		result: load-json/flat lib/read-messages lib/no-of-messages
		messages: result/2
		; now skip thru each message and see if any unread
		foreach msg messages [
			content: lib/user-name: none message-no: 0
			either parse ?? msg [some message-rule] [
				print "parsed"
			] [print "failed"]
			content: trim decode-xml content
			; new message?
			if message-no > lastmessage-no [
				print "New message"
				save last-message-file lastmessage-no: message-no
				; {<div class='full'>@RebolBot /x a: "Hello" <br> print a</div>}
				; <content> {<div class='full'>@rebolbot <br> print &quot;ehll&quot;</div>}
				parse content [
					<div class='full'> opt space copy content to </div>
					(
						if parse content [lib/botname #" " <br> to end] [
							; treat a newline after botname as a do-rule
							replace content <br> "do "
						]
						replace/all content <br> " " trim content
					)
				]
				if parse content bot-cmd-rule [
					print "message for me, we should have dealt with it in the parse rule"
				]
			]
		]
	] [
		probe mold errmain
	]
	if cnt >= 10 [
		cnt: 0
		call-command-pulse
	]
	sync-commands
	attempt [ wait lib/pause-period ]
]

halt
