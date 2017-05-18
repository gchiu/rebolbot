#!/sbin/rebol -cs
REBOL [
    title: "Rebol safe evaluation service"
    file: %evalr2.r
    author: "Graham Chiu"
    date: 18-May-2017
    version: 0.0.1
    notes: {
        attempt to provide a partially safe environment for rebol evaluation
        though will not survive a determined rebol hacker
    }
]

secure [net allow file throw]

print rejoin [
    "Content-type: text/plain" crlf
    crlf
    <!doctype text/plain>
]

cgi: system/options/cgi

; check coming from chat
;if cgi/REMOTE-ADDR <> read dns://rebol.info [
;    ; print <rebol> | dump remote-client | fail "Execution only allowed from rebolbot's server </rebol>"
;]

if cgi/REQUEST-METHOD = "GET" [
    if parse cgi/QUERY-STRING ["eval=" copy doable to end][
        print <rebol>
        doable: dehex doable
        ?? doable
        if error? set/any 'err try [
            do doable
        ][
            probe disarm get/any 'err
        ]
        print </rebol>
    ]
]

if cgi/REQUEST-METHOD = "POST" [
    cgidata: make string! 1020
    buffer: make string! 16380
    while [positive? read-io system/ports/input buffer 16380][
        append cgidata buffer
        clear buffer
    ]
    print <rebol>
    if error? set/any 'err try [
        do cgidata
    ][
        print disarm get/any 'err
    ]
    print </rebol>
]
