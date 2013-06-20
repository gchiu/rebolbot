REBOL [
    Title:      "Search - command"
    Name:       search-command
    Type:       module
    Version:    1.0.0
    Needs:      [bot-api 1.0.0]
    Date:       16-June-2013
    Author:     "Graham Chiu"
    Options:    [private]
]

help-string: {search key "retrieves all messages in store that contains key"}

target: none

dialect-rule: [
    'search [set target string! | set target word!] (
        done: true
        either any [
            "red" = form target
            3 < length? form target
        ] [
            use [json out outstring cnt] [
                cnt: 0
                out: copy []
                outstring: copy "First 50 results^/"

                ?? storage                  
                foreach file read storage [
                    if cnt > 50 [
                        break
                    ]
                    if not dir? file [
                        json: load-json to string! read join storage file

                        if all [
                            in json 'content
                            find json/content form target
                        ] [
                            ++ cnt
                            repend/only out [json/time_stamp json/user_name json/message_id]
                        ]
                    ]
                ]
                either empty? out [
                    reply message-id ajoin ["sorry, " target " not found so far"]
                ] [
                    foreach result out [
                        append outstring ajoin ["On: " from-now unix-to-date result/1 " by: " result/2 " in: " result/3 newline]
                    ]
                    reply message-id outstring
                ]
            ]
        ] [
            reply message-id "Query string needs to be at least 4 characters"
        ]
    )
]
