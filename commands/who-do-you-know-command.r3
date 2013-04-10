REBOL [
	Title:		"Who do you know? - command"
	Name:		who-do-you-know-command
	Type:		module
	Version:	1.0.0
	Needs: [bot-api 1.0.0]
	Options: [private]
]

help-string: {who do you know "returns a list of all known users"}

dialect-rule: ['who 'do 'you ['know | 'know?] (show-all-users message-id done: true)]

show-all-users: func [message-id
	/local tmp
] [
	tmp: copy []
	foreach [user address] about-users [
		append tmp user
	]
	reply message-id join "I know something of the following people: " form sort tmp
]
