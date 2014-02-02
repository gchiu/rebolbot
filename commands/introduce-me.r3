REBOL [
    Title:      "Introduce me - command"
    Name:       introduce-me-command
    Type:       module
    Role:       command
    Version:    1.0.0
    Needs:      [bot-api 1.0.0]
    Options:    [private]
]

help-string: {introduce me "introduce yourself"}
dialect-rule: [
    ['introduce 'me] (introduce done: true)
]

;; The implementation in this module is specific to SO chat. When the specific chat
;; connectivity is factored out into its own module, this code should be changed to
;; delegate to the chat module being used. Note that it is conceivable that one bot
;; instance could manage multiple chat rooms/systems.

introduce: func [
    /local page username userid everyone
] [
    everyone: copy []
    attempt [ page: to string! read html-url]
    parse page [
        any [
            thru "update_user({id: " copy userid some id-rule thru {, name: ("} copy username to {")}
            (   trim/all username
                append everyone reduce [username userid]
            )
        ]
        to end
    ]
    speak ajoin [profile-url select everyone user-name "/" url-encode to-dash user-name ]
    wait 1
]
