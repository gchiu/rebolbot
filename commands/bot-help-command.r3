REBOL [
    Title:      "Bot Help - command"
    Name:       bot-help-command
    Type:       module
    Role:       command
    Version:    1.0.0
    Needs:      [bot-api 1.0.0]
    Options:    [private]
]

help-string: {help "this help"}

dialect-rule: ['help (done: true provide-help)]

provide-help: func [] [
    reply message-id rejoin [{I respond to these commands
        Note: [] means optional input or shows expected datatype, (|) means choice:} newline
        sort/skip collect [foreach command commands [keep command/help-string keep newline]] 2
        {? key [ for user | @user ] "Returns link and description"}
    ]
]
