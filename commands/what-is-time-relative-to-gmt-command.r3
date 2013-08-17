REBOL [
    Title:      "What is current time relative to GMT? - command"
    Name:       what-is-time-relative-to-gmt-command
    Type:       module
    Role:       command
    Version:    1.0.0
    Needs:      [bot-api 1.0.0]
    Options:    [private]
]

help-string: {what is the time?}

dialect-rule: ['what 'is 'the ['time | 'time?] opt ['now? | 'now | 'in 'GMT] (done: true reply-time)]

reply-time: func [] [reply message-id to-idate now]
