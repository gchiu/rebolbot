REBOL [
    Title:		"Return a greeting - command"
	Name:		return-greeting-command
	Type:		module
	Version:	1.0.0
	Needs: [bot-api 1.0.0]
	Options: [private]
]

help-string: {(hi|hello|goodbye|bye|[good][night|morning|afternoon|evening]) some-text "returns a greeting to the user who greeted bot"}

greeting: none

greeting-phrases: [ "Good to see you again" "Welcome back" "Welcome :-)" ]
parting-phrases: [ "See you around" "Come back and visit soon" "It was nice talking with you" "All the best" "Take care now" "Don't be a stranger" ]

dialect-rule: [
    copy greeting [
         [ 'hello | 'hi | 'hey | any 'good [ 'morning | 'afternoon | 'evening ] ] (extra-phrase: greeting-phrases) |
         [ 'goodbye | 'bye | 'later | 'see 'you 'later | any 'good 'night] (extra-phrase: parting-phrases)
    ]
    (reply message-id rejoin [ to-string greeting ". " first random extra-phrase ] done: true)
]
