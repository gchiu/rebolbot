REBOL [
	Title:		"Delete the last bot message - command"
	Name:		delete-last-message
	Type:		module
	Version:	1.0.0
	Needs: [bot-api 1.0.0]
	Options: [private]
]

help-string: {delete [ silent ] "in reply to a bot message will delete if in time"}

silent: false

dialect-rule: [
	'delete (done: true)
	opt [copy silent word!] (
		either all [block? silent silent/1 = 'silent] [
			delete-message/silent parent-id message-id
		] [
			print "not calling silent"
			delete-message parent-id message-id
		]
	)
]
