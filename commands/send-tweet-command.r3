REBOL [
    Title:      "Twitter command"
    Name:       twitter-send
    Type:       module
    Version:    1.0.0
    Needs:      [bot-api 1.0.0]
    Options:    [private]
]

help-string: {tweet [message 12345678 | "string"] "Sends tweet of message number or string as @rebolbot"}

text: existing-message-id: none

dialect-rule: [
    'tweet [
        set existing-message-id number! (
            reply message-id join "Sending a tweet of message: " existing-message-id
            twitter/as "rebolbot"
            twitter/update read-message existing-message-id
            done: true
        ) |
        set text string! (
            reply message-id join "Sending this as a tweet: " text
            twitter/as "rebolbot"
            twitter/update text
            done: true
        )
    ]
]

