REBOL [
    Title:      "Who is online? - command"
    Name:       who-is-online-command
    Type:       module
    Version:    1.0.1
    Needs:      [bot-api 1.0.0]
    Options:    [private]
]

help-string: {present[?] "prints users currently online"}
dialect-rule: [['present | 'present?] (done: true who-is-online)]

;; The implementation in this module is specific to SO chat. When the specific chat
;; connectivity is factored out into its own module, this code should be changed to
;; delegate to the chat module being used. Note that it is conceivable that one bot
;; instance could manage multiple chat rooms/systems.

;; Where to save the chat visitors
visitors-file: %visitors.r
visitors: copy []

;; Compile a list of known people
either not exists? visitors-file [
    foreach [user data] about-users [
        append visitors form user
    ]
    save visitors-file visitors
] [
    visitors: load visitors-file
]

;; Scan the html page, check to see who is here, and send a greet message to new users
who-is-online: func [
    /silent
    /local out page username userid len newbies addressees reputation full-greet-message err json-name
] [
    addressees: copy ""
    len: length? visitors
    out: copy []
    newbies: copy []
    reputation: copy ""
    page: to string! read html-url
    parse page [
        any [
            thru "update_user({id: " copy userid some id-rule thru {, name: (} copy username to {)}
            thru "reputation: " copy reputation to "," thru "});"
            (trim/all username
                print [ "rep: " reputation userid username]
                json-name: copy username
                username: load-json username
                append out copy username
                if not find visitors username [
                    append visitors username
                    repend/only newbies [trim/with json-name {"} username userid to-integer reputation]
                ]
            )
        ]
        to end
    ]
    either empty? out [
        ; this floods the room with can not parse the page messages!
        ; reply message-id "can not parse the page for users"
    ] [
        either not silent [
            reply message-id form out
        ] [
            ; silent scan has detected new users - so let's greet them
            if not empty? newbies [
                foreach person newbies [
                    ;;append addressees ajoin [ "@" person " " ]
                    full-greet-message: copy greet-message
                    if error? set/any 'err try [
                        either 20 > person/4 [
                            append full-greet-message low-rep-message
                        ] [
                            speak ajoin [profile-url person/3 "/" url-encode to-dash person/2]
                            append full-greet-message ajoin [" Cool, you have a reputation score of " person/4 " so chat away!"]
                        ]
                    ] [
                        log mold err
                    ]
                    speak ajoin ["@" person/2 " " full-greet-message]
                    wait 1
                ]
            ]
        ]
        if len < length? visitors [
            save visitors-file visitors
        ]
    ]
]

pulse-callback: does [who-is-online/silent 0]
