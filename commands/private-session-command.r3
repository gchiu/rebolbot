REBOL [
	Title:		"Private session with bot - command"
	Name:		private-session-command
	Type:		module
	Version:	1.0.0
	Needs: [bot-api 1.0.0]
	Options: [private]
]

help-string: {private session [ in ] room-number "Starts a private session with the bot in another room."}

private-room: none

dialect-rule: [
	'private 'session opt 'in set private-room integer! (
		done: true
		attempt [
			reply message-id "OK, coming"
			wait 2
			speak-private "hello" private-room
		]
	)
]
