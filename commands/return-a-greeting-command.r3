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

dialect-rule: [copy greeting [ 'hello | 'hi | 'goodbye | 'bye | any [ 'good ] [ 'night | 'morning | 'afternoon | 'evening ] ] (reply message-id [greeting " to you too"] done: true)]
