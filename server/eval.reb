#!/sbin/r3 -cs
REBOL [
    title: "Rebol safe evaluation service"
    file: %eval.reb
    author: "Graham Chiu"
    date: 14-May-2017
    version: 0.0.1
    notes: {
        attempt to provide a partially safe environment for rebol evaluation
        though will not survive a determined rebol hacker
    }
]

print ajoin [
    "Content-type: text/plain" crlf
    crlf
    <!doctype text/plain>
]

cgi: construct [] [ ; CGI environment variables
    SERVER_SOFTWARE:
    SERVER_NAME:
    SERVER_ADDR:
    SERVER_PORT:
    REMOTE_ADDR:
    DOCUMENT_ROOT:
    REQUEST_SCHEME:
    CONTEXT_PREFIX:
    CONTEXT_DOCUMENT_ROOT:
    SERVER_ADMIN:
    SCRIPT_FILENAME:
    REMOTE_PORT:
    GATEWAY_INTERFACE:
    SERVER_PROTOCOL:
    REQUEST_METHOD:
    QUERY_STRING:
    REQUEST_URI:
    CONTENT_LENGTH:
    SCRIPT_NAME: _
;   path-info:
;   path-translated:
;   remote-host:
;   auth-type:
;   remote-user:
;   remote-ident:
;   Content-Type:           ; cap'd for email header
;   content-length: _
   other-headers: []
]

;for-each w words-of cgi [
;    print/eval [form w "=" get-env w]
;]

; set the CGI object from the linux environment
env: collect [
    for-each w words-of cgi [
        keep get-env w 
    ]
]
set words-of cgi env

; disable read outside current directory
old-read: copy :read
hijack 'read adapt 'old-read [
    if file? :source [
        source: clean-path source
        if not find source what-dir [
            fail "Not allowed to read outside the jail!"
        ]
    ]
]

; disable disk writes
old-write: copy :write
hijack 'write adapt 'old-write [
    if file? :destination [
        fail "Not allowed to write to file when in jail!"
    ]
]

for-each w paranoid: [
    old-write
    old-read
    call
    cd change-dir
    ls list-dir 
    rm delete
    make-routine ; FFI
][ unset w]

; check coming from chat
if "stackoverflow.com" <> remote-client: read join-of dns:// cgi/REMOTE_ADDR [
    dump remote-client
    fail "Execution only allowed from stackoverflow chat"
]

print <rebol>

if cgi/REQUEST_METHOD = "GET" [
    if parse cgi/QUERY_STRING ["eval=" copy doable: to end][
        doable: dehex doable
        dump doable
        if error? error: trap [
            do doable
        ][
            probe error
        ]
    ]
]
print </rebol>
