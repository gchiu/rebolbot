Rebol [
    Title: "Twitter command"
    Name: twitter-send
    Type: module
    Role: command
    Version: 1.0.0
    Needs: [
        %../bot-api.r3 1.0.0
    ]
    Options: [private]
]

help-string:
{tweet [12345678 | "string"] "Sends tweet of message number or string as @rebolbot"}

user-id: user-string: text: existing-message-id: _
twitter-user: "rebolbot"

room-admins: collect [
    attempt [
        parse to string! read http://chat.stackoverflow.com/rooms/info/291/rebol-and-red?tab=access [
            thru <div class="access-list">
            some [
                thru {<a class="username " href="/users/}
                copy user-id to "/" skip copy user-name to {">} 2 skip copy user-string to </a>
                (keep reduce [to integer! user-id user-name user-string])
            ]
            to end
        ]
    ]
]

dialect-rule: [
    [
        'tweet [
            set existing-message-id number! (
                either find room-admins person-id [
                    ; privileged user
                    reply message-id join-of "Sending a tweet of message: " existing-message-id
                    twitter/as twitter-user
                    twitter/update/override lib/read-message existing-message-id
                ] [
                    reply message-id ["Sorry, " user-name " you don't have access to send a tweet"]
                ]
                done: true
            )
            |
            set text string! (
                either find room-admins person-id [
                             ; privileged user
                    reply message-id join-of "Sending this as a tweet: " text
                    twitter/as twitter-user
                    twitter/update/override text
                ] [
                    reply message-id ["Sorry, " user-name " you don't have access to send a tweet"]
                ]
                done: true
            )
        ]
    ]
]
