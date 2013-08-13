REBOL [
    Title:      "What is the meaning of life - command"
    Name:       meaning-of-life-command
    Type:       module
    Role:       command
    Version:    1.0.0
    Needs:      [bot-api 1.0.0]
    Options:    [private]
]

help-string: {what is the (meaning|purpose) of life? "answers the biggest question of all"}

dialect-rule: ['what 'is 'the ['meaning | 'purpose] 'of ['life | 'life?] (done: true reply message-id "42")]
