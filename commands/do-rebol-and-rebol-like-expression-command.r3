REBOL [
    Title:      "Evaluate a Rebol expression - command"
    Name:       do-rebol-and-rebol-like-expression-command
    Type:       module
    Role:       command
    Version:    1.0.0
    Needs:      [bot-api 1.0.0]
    Options:    [private]
]

help-string: {(do|do/2|do/red|do/boron|do/echo) expression "evaluates Rebol/Rebol-like expression in a sandboxed interpreter. echo repeats exact command sent to r3"}

expression: target: none

dialect-rule: [
    [ ; do-rule
        ["/x" | 'do] copy expression to end
        (done: true
            attempt [
                evaluate-expression mold/only/all expression
            ]
        )
    ] |
    [ ; echo-rule
        'do/echo copy expression to end
        (done: true
            attempt [
                evaluate-expression/echo mold/only/all expression
            ]
        )
    ] |
    [ ; do2-rule
        ['do/2 | 'do/rebol2] copy expression to end
        (done: true
            attempt [
                evaluate-expression/r2 mold/only expression
            ]
        )
    ] |
    [ ; do-boron-rule
        'do/boron copy expression to end
        (done: true
            attempt [
                evaluate-expression/boron mold/only expression
            ]
        )
    ] |
    [ ; do-red-rule
        'do/red copy expression to end
        (done: true
            attempt [
                evaluate-expression/red mold/only expression
            ]
        )
    ] |
    [ ; read-raw-rule
        'read 'raw set target url! (
            done: true
            raw-read target
        )
    ]
]


;- configuration urls
remote-execution-url: [
    rebol3 http://tryrebol.esperconsultancy.nl/do/REBOL
    rebol2 http://tryrebol.esperconsultancy.nl/do/REBOL-2
    boron http://tryrebol.esperconsultancy.nl/do/Boron
    red http://tryrebol.esperconsultancy.nl/do/Red
]

; mini-http is a minimalistic http implementation
mini-http: func [ url [url!] method [word! string!] code [string!] timeout [integer!]
    /local url-obj http-request payload result port
][
    http-request: {$method $path HTTP/1.0
Host: $host
User-Agent: Mozilla/5.0
Accept: text/html
Referer: http://$host
Content-Length: $len
Content-Type: text/plain; charset=UTF-8

$code}

    url-obj: construct/with sys/decode-url url make object! copy [port-id: 80 path: ""] 
    if empty? url-obj/path [ url-obj/path: copy "/" ]
    payload: reword http-request reduce [
        'method method
        'path url-obj/path
        'host url-obj/host
        'len length? code
        'code code
    ]
    
    port: make port! rejoin [tcp:// url-obj/host ":" url-obj/port-id]
    port/awake: func [event] [
        switch/default event/type [
           lookup [open event/port false ]
           connect [write event/port to binary! join payload newline false]
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
        none
    ]
]

raw-read: func [target [url!]
    /local result err
][
    if error? set/any 'err try [
    either result: mini-http target 'GET "" 60 [
        reply message-id result
    ][
        reply message-id "HTTP timeout"
    ]
    ][
        reply message-id mold err
    ]
]

extract-http-response: func [http-text [string!]
    /local result code bodytext server-code
][
    digit: charset [ #"0" - #"9" ]
    either parse http-text [ thru "HTTP/1." [ "0" | "1" ] some space copy code 3 digit some space copy server-code to newline
    thru "^/^/" copy bodytext to end ][
        trim/head/tail bodytext
    ][
        make object! compose [ error: (server-code) code: (code) ]
    ]
]

evaluate-expression: func [expression
    /r2 "rebol2"
    /boron "boron"
    /red "RED"
    /echo "echo"
    /local output html error-url exp execute-url
] [
    output: html: error-url: none
    execute-url: select remote-execution-url
    case [
        r2 ['rebol2]
        boron ['boron]
        red ['red]
        echo ['rebol3]
        true ['rebol3]
    ]

    print ["attempting evaluation at: " execute-url]
    html: to string! write execute-url compose [ POST (expression) ]
;; -- this begins the change from using native http
    ; if none? html: mini-http execute-url 'POST form expression 60 [
    ;   speak "tryrebol server timed out"
    ;   return
    ; ]
    ; ; speak form type? html
    ; if object? html: extract-http-response html [
    ;   print "html is object!"
    ;   speak mold html
    ;   return
    ; ]
;; --- and ends the change from using native http scheme    
    parse html [thru <span> thru <pre> copy output to </pre>]
    output: decode-xml output
    ; if an error, remove part of the error string and parse out the help page
    if find output "*** ERROR" [
        replace output "try do either either either -apply-" ""
        parse html [thru {<a href="} copy error-url to {"}]
    ]
    ; indent 4 spaces ... needed for markup to be code
    replace/all output "^/" "^/    "
    speak ajoin [
        "    ; Brought to you by: " http://tryrebol.esperconsultancy.nl newline
        either found? error-url [
            ajoin ["    ; " error-url newline "    "]
        ] [""]
        either echo [ ajoin [ "    >> " trim expression newline ] ] [ "" ]
        "    " output
    ]
    ?? expression
]
