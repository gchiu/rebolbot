REBOL [
	Title:		"Source for a Rebol or Bot function - command"
	Name:		source-command
	Type:		module
	Version:	1.0.0
	Needs: [bot-api 1.0.0]
	Date:	13-June-2013
	Author:	"Graham Chiu & Andreas"
	Options: [private]
]

help-string: {source name  "provides Rebol source for named function"}

target: err: none

dialect-rule: [
	'source set target word! (
		done: true
		either target = 'bot-config [
			reply message-id "You need to use your own config file!"
		][
		if error? set/any 'err try [
			speak to-markdown-code rejoin [target ": " mold get bind target lib]
		][
			if error? try [
				speak to-markdown-code rejoin [target ": " mold get bind target self]
			][
				reply message-id ajoin [ "Sorry, " target " is not in my vocab!" ]
			]
		]
		]
	)
]

