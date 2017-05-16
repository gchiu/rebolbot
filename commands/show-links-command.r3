REBOL [
    Title:      "Show links - command"
    Name:       show-links-command
    Type:       module
    Role:       command
    Version:    1.0.0
    Needs:      [bot-api 1.0.0]
    Options:    [private]
]

help-string: 
{show (me|all) links [ like url ] "shows saved links (like url, if provided)"
show me your youtube videos "shows saved youtube videos"}

show-urls: similar: youtube: _

dialect-rule: [
    'show any ['me | 'all]
    [
        (show-urls: similar: youtube: false)
        'links (show-urls: true) opt ['like set links url! (similar: true)] |
        'your 'youtube 'videos (youtube: true)
    ] (show-selected)
]

show-selected: does [
    done: any [similar show-urls youtube]
    case [
        similar [
            show-similar-links links
        ]
        show-urls [
            show-all-links
        ]
        youtube [
            show-similar-links https://www.youtube.com
            wait 2
            show-similar-links http://www.youtube.com
        ]
    ]

]

; SO chat has a 500 character limit for messages with active links
; so let's send in 500 ( chat-length-limit ) char chunks
; this should be a refinement of show-similar-links
show-all-links: func [/local out link used] [
    out: copy ""
    used: copy []
    foreach [key data] bot-expressions [
        if not find used data/2 [
            link: ajoin ["[" data/1 "](" data/2 "); "]
            either chat-length-limit < add length? out length? link [
                ; over chat-length-limit so send what we have
                reply message-id out
                wait 2
                out: copy link
            ] [append out link]
            append used data/2
        ]
    ]
    wait 2
    if empty? out [out: copy "nothing found"]
    reply message-id out
]

show-similar-links: func [links /local out link tot used] [
    print "in the simlar links function now"
    out: copy ""
    used: copy []
    foreach [key data] bot-expressions [
        if not find used data/2 [
            if find/part data/2 links length? links [
                link: ajoin ["[" data/1 "](" data/2 "); "]
                ; if adding a new link exceeds allowed, then send current
                either chat-length-limit < tot: add length? out length? link [
                    reply message-id out
                    wait 2
                    ; and reset out to the new link
                    out: copy link
                ] [
                    append out link
                ]
                append used data/2
            ]
        ]
    ]
    wait 2
    ;?? out
    if empty? out [out: copy "nothing found"]
    reply message-id out
]
