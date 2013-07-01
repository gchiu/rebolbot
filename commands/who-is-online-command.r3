REBOL [
    Title: 		"Who is online? - command"
    Name: 		who-is-online-command
    Type: 		module
    Version: 	1.0.1
    Needs: 		[bot-api 1.0.0]
    Options: 	[private]
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
    visitors: copy []
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
    /local out page username userid len newbies addressees reputation rpage hi-rep-message err json-name
] [
    addressees: copy ""
    len: length? visitors
    out: copy []
    newbies: copy []
    page: to string! read html-url
    parse page [
        some [
            thru "chat.sidebar.loadUser(" copy userid some id-rule thru "(" copy username [{"} thru {"}] ")"
            (trim/all username
                json-name: copy username
                username: load-json username
                append out username
                if not find visitors username [
                    append visitors username
                    repend/only newbies [trim/with json-name {"} username userid]
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
                    reputation: 0
                    hi-rep-message: copy greet-message
                    if error? set/any 'err try [
                        ; attempt to read the rep page
                        attempt [
                            rpage: to string! read rejoin [profile-url person/3 "/" url-encode to-dash person/2] 
                        ]
                        if parse rpage [thru <span class="reputation-score"> copy reputation to </span> to end] [
                            either 20 > to integer! replace/all reputation "," "" [
                                speak ajoin [profile-url person/3 "/" url-encode to-dash person/2]
                                append hi-rep-message lib/low-rep-message
                            ] [
                                append hi-rep-message ajoin [" Cool, you have a reputation score of " reputation " so chat away!"]
                            ]
                        ]
                    ] [
                        speak-debug mold err
                    ]
                    speak ajoin ["@" person/2 " " hi-rep-message]
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
