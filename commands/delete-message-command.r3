REBOL [
    Title:      "Delete the last bot message - command"
    Name:       delete-last-message
    Type:       module
    Version:    1.0.1
    Needs:      [bot-api 1.0.0]
    Options:    [private]
]

help-string: {delete [ loud ] "in reply to a bot message will delete if in time"}

loud: false

dialect-rule: [
    'delete (done: true loud: false )
    opt [ copy loud word! ] (
        either all [ block? loud loud/1 = 'loud][
            delete-message parent-id message-id             
        ][
            print "not calling loud"
            delete-message/silent parent-id message-id 
        ]
    )
]
