REBOL [
    Title:      "Curecode - command"
    Name:       cc-command
    Type:       module
    Role:       command
    Version:    1.0.0
    Needs:      [bot-api 1.0.0]
    Date:       16-June-2013
    Author:     "Graham Chiu"
    Options:    [private]
]

help-string: {cc id "retrieves curecode data"}

target: none

    
    dialect-rule: [
        'cc set target integer! (
            done: true
            use [ result ][
                attempt [
                    result: load join http://curecode.org/rebol3/api.rsp?type=ticket&show=all&id= target
                    if parse result [ 'ok set result block! ][
                        reply message-id mold result
                    ]
                ]
            ]
        )
    ]
