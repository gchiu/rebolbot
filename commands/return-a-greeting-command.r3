REBOL [
	Title:		"Return a greeting - command"
	Name:		return-greeting-command
	Type:		module
	Version:	1.0.0
	Needs: [bot-api 1.0.0]
	Options: [private]
]

help-string: {(hello|goodbye|morning) some-text "returns a greeting to the user who greeted bot"}

greeting: none

dialect-rule: [copy greeting ['hello | 'goodbye | 'morning] (reply message-id [greeting " to you too"] done: true)]
