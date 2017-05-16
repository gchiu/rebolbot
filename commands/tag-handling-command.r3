REBOL [
    Title:      "Tag handling - command"
    Name:       tag-handling-command
    Type:       module
    Role:       command
    Version:    1.0.0
    Needs:      [bot-api 1.0.0]
    Options:    [private]
]

help-string: 
{save key [string! word!] description [string!] link [url!] "save key with description and link"
keys "returns known keys"
remove key "removes key (requires authorized user)"
find descript [string! word!] "shows keys with description containing descript"}

expression: findstring: _

dialect-rule: [
    ; save-key-rule
    ['save not [ 'my ] copy expression to end (done: true save-key expression)] |
    ; list keys
    ['keys (done: true show-keys)] |
     ; remove-key-rule
    [
        'remove copy expression to end (
            done: true
            remove-key form expression
        )
    ] |
    ; find-string-rule
    [
        'find [set findstring string! | set findstring word!] (
            done: true
            find-in-links form findstring
        )
    ]
]

;; The file to which expressions are persisted across bot startup/shutdown
expressions: %bot-expressions.r

; save expressions bot-expressions

if exists? expressions [
    bot-expressions: load expressions
]

save-key: func [content [string! block!] /local exp err] [
    if error? err: try [
        exp: to block! content
        ?? exp
        either all [
            any [string? exp/1 word? exp/1]
            exp/1: trim to string! exp/1
            3 <= length? exp/1 ; no keywords of 1 2 characters
            string? exp/2
            url? exp/3
        ] [
            print "okay to add"
            either not find bot-expressions exp/1 [
                print "adding"
                append bot-expressions exp/1
                repend/only bot-expressions [exp/2 exp/3]
                save expressions bot-expressions
                reply message-id ["added key: " exp/1]
            ] [
                reply message-id [exp/1 " is already a key"]
            ]
        ] [
            reply message-id [content " can not be saved as key"]
        ]
    ] [
        probe mold err
        reply message-id mold err
    ]
]

show-keys: func [/local tmp out] [
    tmp: copy [] out: copy ""
    foreach [key data] bot-expressions [
        repend tmp [key data/1]
    ]
    sort/skip tmp 2
    foreach [key description] tmp [
        repend out ajoin [key { "} description {"^/}]
    ]
    reply message-id compose ["I know the following keys: ^/" (out)]
]

remove-key: func [content
    /local rec
] [
    either find privileged-users person-id [
        ; privileged user
        either rec: find bot-expressions content [
            remove/part rec 2
            save expressions bot-expressions
            reply message-id ["removed " content]
        ] [
            reply message-id [content " not found in my keys"]
        ]
    ] [
        reply message-id ["Sorry, " user-name " you don't have the privileges yet to remove the key " content]
    ]
]

find-in-links: func [findstring
    /local out used link
] [
    either 3 > length? findstring [
        reply message-id "Find string needs to be at least 3 characters"
    ] [
        out: copy ""
        used: copy []
        foreach [key data] bot-expressions [
            if all [
                not find used data/2
                find data/1 findstring
            ] [
                link: ajoin ["[" data/1 "](" data/2 "); "]
                either chat-length-limit < add length? out length? link [
                    reply message-id out
                    wait 2
                    out: copy link
                ] [
                    append out link
                ]
                append used data/2
            ]
        ]
        if empty? out [out: copy "nothing found"]
        reply message-id out
    ]
]
