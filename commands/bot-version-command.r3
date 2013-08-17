REBOL [
    Title:      "Get bot version - command"
    Name:       bot-version-command
    Type:       module
    Role:       command
    Version:    1.0.0
    Needs:      [bot-api 1.0.0]
    Options:    [private]
]

help-string: {version "version of bot"}

dialect-rule: ['version (done: true reply message-id ajoin [system/script/header/version " " last system/script/header/date])]
