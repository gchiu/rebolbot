REBOL [
	Title:		"Bot Help - command"
	Name:		bot-help-command
	Type:		module
	Version:	1.0.0
	Needs: [bot-api 1.0.0]
	Options: [private]
]

help-string: {help "this help"}

dialect-rule: ['help (done: true provide-help message-id)]

provide-help: func [message-id] [
	reply message-id rejoin [{I respond to these commands:} newline
		sort/skip collect [foreach command commands [keep command/help-string keep newline]] 2
		{? key [ for user | @user ] "Returns link and description"}
	]
]
