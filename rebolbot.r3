Rebol [
    file:       %rebolbot.r3
    author:     ["Graham Chiu" "Adrian Sampaleanu" "John Kenyon"]
    date:       [28-Feb-2013 11-Apr-2013 2-June-2013 20-June-2013 20-July-2013 25-Mar-2014 13-May-2015 16-May-2017] ; leave this as a block plz!  It's used by version command
    version:    0.1.5
    purpose:    {Perform useful, automated actions in Stackoverflow chat rooms}
    License:    'Apache2
    Notes:      {16-May-2017 first attempt to update to ren-c}
    Needs:      [
                    ; %twitter.r3
                    ;%bot-api.r3 f
                    ;%altwebform.reb
                    ;%prot-http.r3 ;required for login2so functino
                    ;http://reb4.me/r3/altjson
                    ;http://reb4.me/r3/altwebform
                    ; http://reb4.me/r3/altxml
                ]
]
do %bot-api.r3
import <webform> ; %webform.reb
import <json>
import <xml>

system/options/default-suffix: %.r3
command-dir: %commands/

sync-commands: func [ /local cmd-header err ] [
    lib/commands: copy []
    for-each command read command-dir [
        if error? err: trap [ 
            if all [
                system/options/default-suffix = suffix? command
                cmd-header: load/header join-of command-dir command
                find cmd-header/1/Needs 'bot-api
                cmd-header/1/Role = 'command
            ][
                append lib/commands cmd: import/no-lib rejoin [command-dir command]
            ]
        ][
            probe err
        ]
    ]
]

sync-commands

if not set? 'shrink [
    shrink: load %../shrink.reb ; https://raw.githubusercontent.com/gchiu/rebolbot/master/shrink.reb
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
    bot-user: bot-config/bot-user
    bot-pass: bot-config/bot-pass

;    dump bot-config
; don't know the credentials
;    lib/ideone-user: bot-config/ideone-user
;    lib/ideone-pass: bot-config/ideone-pass
;    lib/ideone-url: bot-config/ideone-url
    log-file: bot-config/log-file
] [
    lib/botname: "-- name me --"
    room-id: 0 
    room-descriptor: "-- room name --"
    lib/greet-message: "-- set my welcome message --"
    lib/low-rep-message: "-- set my low reputation message --"
    lib/ideone-user: "-- get your own --"
    lib/ideone-pass: "-- get your own --"
    lib/ideone-url: http://apiurl
    log-file: %log.txt
]

; put this into bot-config
lib/storage: %messages/
if not exists? lib/storage [
    make-dir lib/storage
]

; write %bot-config.r compose [
;   botname: (mold lib/botname) #"^/"
;   room-id: (room-id) #"^/"
;   room-descriptor: (mold room-descriptor) #"^/"
;   greet-message: (mold lib/greet-message) #"^/"
; ]

lib/pause-period: 5 ; 5 seconds between each poll of the chat
lib/no-of-messages: 5 ; fetch 5 messages each time
lib/max-scan-messages: 200 ; max to fetch to scan for links by a user

; these users can remove keys - uses userids, the names are there just so that you know who they are!
lib/privileged-users: ["HostileFork" 211160 "Graham Chiu" 76852 "johnk" 1864998]

orders-cache: copy [ ]
cache-size: 6
; we have a cache of 6 orders to the bot - [ message-id [integer!] order [string!] ]
append/dup orders-cache _ cache-size * 2

lastmessage-no: 8743137
last-message-file: %lastmessage-no.r

if exists? last-message-file [
    attempt [
        lastmessage-no: load last-message-file
    ]
]

dump lastmessage-no

so-chat-url: http://chat.stackoverflow.com/
lib/profile-url: http://stackoverflow.com/users/
chat-target-url: rejoin write-chat-block: [so-chat-url 'chats "/" room-id "/" 'messages/new]
lib/referrer-url: rejoin [so-chat-url 'rooms "/" room-id "/" room-descriptor]
lib/html-url: rejoin [lib/referrer-url "?highlights=false"]
read-target-url: rejoin [so-chat-url 'chats "/" room-id "/" 'events]
read-message-target-url: rejoin [so-chat-url 'message]
delete-url: [so-chat-url 'messages "/" (lib/parent-id) "/" 'delete]

lib/id-rule: charset [#"0" - #"9"]
non-space: complement space: charset #" "

lib/unix-to-date: func [ unix [string! integer!]
    /local days d 
][
    if string? unix [ unix: to integer! unix ]
    days: unix / 24 / 60 / 60
    d: 1-Jan-1970 + days
    d/zone: 0:00
    d/second: 0
    d
]

lib/from-now: func [ d [date!]][
    case [
        d + 7 < now [ d ]
        d + 1 < now [ join-of now - d " days ago" ]
        d + 1:00 < now [ join-of  to integer! divide difference now d 1:00 " hours ago" ]
        d + 0:1:00 < now [ join-of to integer! divide difference now d 0:1:00 " minutes ago" ]
        true [ join-of to integer! divide now/time - d/time 0:0:1 " seconds ago" ] 
    ]
]

lib/unix-now: does [
    60 * 60 * divide difference now/utc 1-Jan-1970 1:00
]

lib/two-minutes-ago: does [
    subtract lib/unix-now 60 * 2
]

lib/percent-encode: func [char [char!]] [
    char: enbase/base to-binary char 16
    parse char [
        copy char some [char: 2 skip (insert char "%") skip]
    ]
    char
]

; why aren't we use the url-encode from webform?
lib/url-encode: use [ch mk] [
    ch: charset ["-." #"0" - #"9" #"A" - #"Z" #"-" #"a" - #"z" #"~"]
    func [text [any-string!]] [
        either parse text: form text [
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
    time [time! number! block! blank!]
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
        lib/to-itime any [date/time 0:00]
        str
    ]
]

lib/to-markdown-code: func [ txt /local out something ][
    quadspace: "    "
    out: copy "" ; copy quadspace
    parse txt [ 
            some [ 
                copy something to newline newline ( 
                    append out join-of quadspace something
                    append out newline 
                )
                |
                copy something to end ( 
                    append out quadspace
                    append out something 
                )
            ]
        ]
    print out
    trim/tail out
]

lib/to-dash: func [ username ][
    foreach c " ." [
        replace/all username c "-"
    ]
    username
]

lib/login2so: func [email [email!] password [string!] chat-page [url!]
	/local fkey root loginpage cookiejar result err configobj
][
	configobj: make object! [fkey: copy "" bot-cookie: copy ""]
	fkey: _
	root: https://stackoverflow.com
	; grab the first fkey from the login page
	print "reading login page"
	loginpage: to string! read https://stackoverflow.com/users/login
	print "read ..."

    if parse loginpage [thru "login-form" thru {action="} copy action to {"} thru "fkey" thru {value="} copy fkey to {"} thru {"submit-button"} thru {value="} copy login to {"} to end][
        dump action
        postdata: to-webform reduce ['fkey fkey 'email email 'password password 'submit-button login]
        if error? err: trap [
            print "posting credentials to stackoverflow"
            result: to-string write rejoin [root action] postdata
;           p: open join root action
;           write p postdata
        ][

            probe words-of err
            cookiejar: reform collect [ for-each cookie err/arg2/headers/set-cookie [ keep first split cookie " " ] ] ; trim the expires and domain parts
            parse cookiejar [to "usr=" copy cookiejar to ";"]
            result: write chat-page compose/deep [GET [cookie: (cookiejar)]]
            ; dump result
            result: to string! result
            ; result: reverse decode 'markup result
            ; now grab the new fkey for the chat pages
            ; <input id="fkey" name="fkey" type="hidden" value="c3c12ca46034c3d6bd832df991528b92" />
            fkey: _
            parse result [ thru {name="fkey"} thru {value="} copy fkey to {"} to end ]
        ]
        configobj/fkey: fkey
        configobj/bot-cookie: cookiejar
    ]
    dump configobj
    return configobj
comment {

	if parse loginpage [thru "login-form" thru {action="} copy action to {"} thru "fkey" thru {value="} copy fkey to {"} thru {"submit-button"} thru {value="} copy login to {"} to end][
		postdata: to-webform reduce ['fkey fkey 'email email 'password password 'submit-button login]
        dump postdata
		if error? err: trap [
			print "posting"
			result: to-string write join root action postdata
		][
            cookiejar: reform collect [ foreach cookie err/arg2/headers/set-cookie [ keep first split cookie " " ] ] ; trim the expires and domain parts
	        parse cookiejar [to "usr=" copy cookiejar to ";"]
			result: write chat-page compose/deep [GET [cookie: (cookiejar)]]
			result: reverse decode 'markup result
			; now grab the new fkey for the chat pages
			foreach tag result [
				if tag? tag [
					if parse tag [thru "fkey" thru "hidden" thru "value" thru {"} copy fkey to {"} to end][
						fkey: to string! fkey
						break
					]
				]
			]
		]
		configobj/fkey: fkey
		configobj/bot-cookie: cookiejar
	]
	configobj
}
]

lib/get-userid: func [ txt
    /local page userid err rule
][
    userid: err: _
    txt: copy ajoin [ {("} txt {")} ]
    rule: [ 
            thru "update_user("
            thru txt thru "chat.sidebar.loadUser(" 
            copy userid digits (
                userid: to integer! userid 
                ; avoid anti-flooding
                ; ?? userid
                wait 2
            ) 
            to end 
    ]
    if error? err: trap [
        page: to string! read html-url
        if not parse page rule [
            ; print "failed the parse"
            lib/log join-of "parse failed for " txt
        ]
    ][ lib/log mold/all err ]
    userid
]

lib/speak-private: func [message room-id] [
    bind write-chat-block 'room-id
    probe rejoin compose copy write-chat-block
    to string! write rejoin compose copy write-chat-block compose/deep copy/deep [
        POST
        [(header)]
        (rejoin ["text=" lib/url-encode message "&fkey=" auth-object/fkey])
    ]
]

lib/log: func [text][
    write/append log-file reform [ now/date now/time mold text newline ]
]

lib/speak: function [message ] [
    if error? err: trap [
        to string! write chat-target-url compose/deep copy/deep [
            POST
            [(header)]
            (rejoin ["text=" lib/url-encode message "&fkey=" auth-object/fkey])
        ]
        done: true
    ] [
        mold err
    ]
]

; mini-http is a minimalistic http implementation
mini-http: func [ url [url!] method [word! string!] cookies [string!] code [string!] timeout [integer!]
    /local url-obj http-request payload result port
][
    http-request: {$method $path HTTP/1.0
Host: $host
User-Agent: Mozilla/5.0
Accept: text/html
Content-Length: $len
Content-Type: text/plain; charset=UTF-8
Set-Cookie: $cookies
$code}

    url-obj: construct/with sys/decode-url url make object! copy [port-id: 80 path: ""] 
    if empty? url-obj/path [ url-obj/path: copy "/" ]
    payload: reword http-request reduce [
        'method method
        'path url-obj/path
        'host url-obj/host
        'cookies cookies
        'len length? code
        'code code
    ]
    probe payload
    port: make port! rejoin [tcp:// url-obj/host ":" url-obj/port-id]
    port/awake: func [event] [
        switch/default event/type [
           lookup [open event/port false ]
           connect [write event/port to binary! join-of payload newline false]
           wrote [read event/port false]
           read done [
            ; probe event/port/data
            result: to-string event/port/data true ]
       ][ true ]
    ]
    open port
    either port? wait [ port timeout ][
        result
    ][  ; timeout
        _
    ]
]

lib/read-messages: func [cnt] [
    to string! write read-target-url compose/deep copy/deep [
        POST
        [(header)]
        (rejoin ["since=0&mode=Messages&msgCount=" cnt "&fkey=" auth-object/fkey])
    ]
]

lib/read-message: func [message-id] [
    to string! read rejoin [read-message-target-url "/" message-id]
]

lib/delete-message: func [parent-id message-id /silent
    /local result mess
] [
    ; POST /messages/8034726/delete HTTP/1.1
    result: to string! write probe mess: rejoin compose copy delete-url compose/deep copy/deep [
        POST
        [(header)]
        (rejoin ["fkey=" auth-object/fkey])
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

process-dialect: func [expression
] [
    default-rule: [
        ; default .. checks for a word and sends it to the check-keys
        opt '? [set search-key word! | set search-key string!] opt ['for set recipient word!] (
            lib/done: true
            either word? recipient [
                recipient: ajoin ["@" recipient]
            ] [
                recipient: copy ""
            ]
            process-key-search trim ajoin [search-key " " recipient]
        )
    ]

    dialect-rule: collect [
        for-each command lib/commands [
            keep/only command/dialect-rule keep '|
        ]
    ]
    insert tail insert dialect-rule quote ((recipient: _)) default-rule
    lib/done: false

    if error? err: trap [

        ; traps illegal rebol values eg @Graham
        if error? err2: trap [
            to block! expression
        ] [
            if all [
                in err2 'arg1
                in err2 'arg2 
                "email" = get in err2 'arg1
            ][
                replace/all expression "@" ""
            ]
        ]
        unless parse expression: to block! expression dialect-rule [
            print "was not parsed by dialect-rule"
        ]
        unless lib/done [
            response: lib/reply lib/message-id eliza/match mold expression
            if found? find response "code: 513" [
                ; Very likely that the cookie has expired - try to log in again
                lib/log "Re-authenticating ..."
                auth-object: lib/login2so bot-config/bot-user bot-config/bot-pass bot-config/bot-room
                lib/log "Logged in"
            ]
        ]
    ] [
        ; sends error
        lib/log mold err
        ; now uses Eliza
        print "trying eliza instead of dumping not understood command "
        lib/reply lib/message-id eliza/match mold expression
    ]
]

process-key-search: func [expression
    /local understood search-key person
] [
    understood: false
    set [search-key person] parse expression _
    unless all [
        person
        parse person ["@" to end]
    ] [person: _]
    ; remove punctuation of ! and ?
    if find [#"!" #"?"] last search-key [remove back tail search-key]
    foreach [key data] lib/bot-expressions [
        if find/part probe key probe search-key length? search-key [
            understood: true
            lib/reply lib/message-id ["[" data/1 "](" data/2 ") " either found? person [person] [""]]
            break
        ]
    ]
    if not understood [
        ; lib/reply lib/message-id [ {sorry "} expression {" is not in my current repertoire.  Try /h for help} ]
        lib/reply lib/message-id eliza/match mold expression
    ]
]

bot-cmd-rule: [
    [   
        lib/botname some space
        copy key to end (print "got key")
        |
        "rebol3> " any space copy key to end ( insert head key "do " )
        |
        ">> " (print ">> rule") any space copy key to end ( either not find key newline [ insert head key "do " ][ key: copy ""] )
        |
        "rebol2> " any space copy key to end ( insert head key "do/2 " )
        ;|
        ;"red> " any space copy key to end ( insert head key "do/red " )
    ]
    ; process-key-search trim key
    (
        print "completed rules"
        replace/all key <br> newline trim key
        dump key
        if not empty? key [ 
            print "processing dialect-rule"
            process-dialect key
        ]
    )
]

message-rule: [
    <event_type> quote 1 |
    <time_stamp> set timestamp integer! |
    <content> set content string! |
    <id> integer! |
    <user_id> set person-id integer! |
    <user_name> set user-name string! |
    <room_id> integer! |
    <room_name> string! |
    <message_id> set message-id integer! |
    <parent_id> set parent-id integer! |
    <show_parent> logic! |
    tag! skip |
    end
    (
        lib/timestamp: timestamp
        lib/person-id: person-id 
        lib/user-name: user-name 
        lib/message-id: message-id 
        lib/parent-id: parent-id 
    )
]

call-command-pulse: function [] [
    for-each command lib/commands [
        if all [
            callback: find words-of command 'pulse-callback
            function? :callback 
        ] [command/pulse-callback]
    ]
]

; Initial login
auth-object: lib/login2so bot-config/bot-user bot-config/bot-pass bot-config/bot-room
print auth-object

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
    cookie: (auth-object/bot-cookie)
]

cnt: 0 ; rescan for new users every 10 iterations ( for 5 seconds, that's 50 seconds )
bot-message-cnt: 0 ; stop the bot monopolising the room

; test speak
lib/speak "Hi guys, I'm back again"

; eval loop
forever [
    ++ cnt
    if error? errmain: trap [
        result: load-json/flat lib/read-messages lib/no-of-messages
        messages: result/2
        ; now skip thru each message and see if any unread
comment {
msg: => [
    <event_type> 1
    <time_stamp> 1494756394
    <content> {<div class='full'>@RebolBot <br> print &quot;hello&quot; <br> print &quot;goodbye&quot;</div>}
    <user_id> 76852
    <user_name> "Graham Chiu"
    <room_id> 291
    <message_id> 37088369
    <parent_id> 37088353
]
}

        for-each msg messages [
            content: lib/user-name: _ lib/message-id: 0
            if not parse msg [some message-rule] [
                print "failed to parse message"
            ]
            if error? trap [
                ; temporary until altxml is correctly ported to ren-c
                content: trim decode-xml content
            ][
                content: copy ""
            ]
            if all [
                lib/timestamp < lib/two-minutes-ago 
                not exists? join-of lib/storage lib/message-id
            ][
                ; print [ "saving " lib/message-id ]
                write join-of lib/storage lib/message-id to-json msg
            ]
            ; failsafe counter
            if equal? remove copy bot-config/botname lib/user-name [ ++ bot-message-cnt ]
            if bot-message-cnt > 7 [ quit/return 42 ] ; if the last 8 messages were by the bot then die

            ; new message?
            changed: false
            if any [
                ; new directive
                lib/message-id > lastmessage-no 
                ; old directive now edited changed
                all [
                    ; we found this order before
                    something? changed: find orders-cache lib/message-id ; none | series  
                    content <> select orders-cache first changed
                ]
            ][  ; only gets here if a new order, or, if an old order that was updated
                remove/part either series? changed [changed] [orders-cache] 2
                ; save new or updated order
                repend orders-cache [lib/message-id content]
                print "New message"
                save last-message-file lastmessage-no: lib/message-id
                ; {<div class='full'>@RebolBot /x a: "Hello" <br> print a</div>}
                ; <content> {<div class='full'>@rebolbot <br> print &quot;ehll&quot;</div>}

comment {
msg: => [
    <event_type> 1
    <time_stamp> 1494756394
    <content> {<div class='full'>@RebolBot <br> print &quot;hello&quot; <br> print &quot;goodbye&quot;</div>}
    <user_id> 76852
    <user_name> "Graham Chiu"
    <room_id> 291
    <message_id> 37088369
    <parent_id> 37088353
]
}

                ; strip out all html stuff to get the content
                parse content [
                    [ <div class='full'> | <pre class='full'> ]
                    opt some space
                    copy content: to [ "</div>" | "</pre>" ]
                    (
                        if parse content [any space lib/botname [#" " <br> | "^M" ] to end] [
                            ; treat a newline after botname as a do-rule]
                            replace content <br> "do "
                            replace content "^M^/" " do "
                        ]
                        replace/all content <br> newline trim content
                    )
                ]
                either parse content bot-cmd-rule [
                    print "message for me, we should have dealt with it in the parse rule?"
                ][
                    print "working as expected"
                ]
            ]
        ] ; end of for-each loop
    ] [
        print "jumped to error handler"
        probe mold errmain
    ]
    if cnt >= 10 [
        cnt: 0
        print "calling command pulse"
        call-command-pulse
    ]
    bot-message-cnt: 0
    print "sync-commands"
    sync-commands
    attempt [ wait lib/pause-period ]
]

halt
