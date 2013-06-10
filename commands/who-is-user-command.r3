REBOL [
	Title:		"Who is user? - command"
	Name:		who-is-user-command
	Type:		module
	Version:	1.0.0
	Needs: [bot-api 1.0.0]
	Options: [private]
]

help-string: {who is user "returns user details and page"}

user: none

dialect-rule: [
	[some ['who 'is | 'whois | 'who 'the 'dickens 'is] copy user to end
	] (if found? user [show-user-page user/1 lib/user-name] done: true)
]

; person is the one asking the question
show-user-page: func [user person /local data known timezone gmt err] [
	gmt: now
	gmt/zone: 0:00
	gmt: gmt - now/zone
	known: false
	user: to string! user
	attempt [trim/all person known: find ?? about-users to word! person]
	if #"?" = last user [remove back tail user]
	if error? set/any 'err try [
		either data: select about-users to word! user [
			reply message-id ajoin [
				"I know this about [" user "](" data/1 ") and their local time is "
				either time? timezone: data/2 [gmt + timezone] [
					"unknown."
				]
			]
		] [
			reply message-id ["Sorry, I don't know anything about " user " yet."]
		]
		if not known [
			reply message-id ["I'd like to know about you!  Use the 'save my details' command"]
		]
	] [
		probe err
	]
]
