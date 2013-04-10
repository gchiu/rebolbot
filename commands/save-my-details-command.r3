REBOL [
	Title:		"Save my details - command"
	Name:		save-my-details-command
	Type:		module
	Version:	1.0.0
	Needs: [bot-api 1.0.0]
	Options: [private]
]

help-string: {save my details url! [ timezone [time!]] "saves your details with url +/- timezone"}

user-url: user-timezone: none

dialect-rule: [
	(print "save rule"
		trim/all lib/user-name
	)
	'save 'my 'details set user-url url! (
		?? user-url
		add-user-details message-id lib/user-name user-url none
		done: true
	) set user-timezone time! (
		add-user-details message-id lib/user-name user-url user-timezone
	)
]

notable-persons-file: %known-users.r

was-about-users: [
]

either exists? notable-persons-file [
	about-users: load notable-persons-file
	; check for old style file
	if url! = type? about-users/2 [
		use [tmp tz rec] [
			tmp: copy about-users
			clear head about-users
			foreach [user url] tmp [
				append about-users user
				tz: either rec: select was-about-users user [
					rec/2
				] [none]
				repend/only about-users [url tz]
			]
			save notable-persons-file about-users
		]
	]
] [
	about-users: copy was-about-users
]

add-user-details: func [message-id person user-url timezone [time! none!]
	/local rec
] [
	attempt [
		person: to word! person
		if rec: find about-users person [
			remove/part rec 2
		]
		repend about-users person
		repend/only about-users [user-url timezone]
		save notable-persons-file about-users
		reply message-id ajoin ["Added " person "'s details"]
	]
]
