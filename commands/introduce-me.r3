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

introduce: func [
    /local page username-from-page userid-from-page everyone
] [
    everyone: copy []
    attempt [ page: to string! read html-url]
    parse page [
        thru "initPresent(["
        any [
            thru "{id: " copy userid-from-page some id-rule thru {, name: ("} copy username-from-page to {")}
            (   trim/all username-from-page
                append everyone reduce [username-from-page userid-from-page]
            )
        ]
        to end
    ] probe everyone
    speak ajoin [profile-url select everyone user-name "/" url-encode to-dash user-name ]
    wait 1
]
