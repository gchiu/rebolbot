REBOL [
	Title:		"Who is online? - command"
	Name:		who-is-online-command
	Type:		module
	Version:	1.0.0
	Needs: [bot-api 1.0.0]
	Options: [private]
]

help-string: {present[?] "prints users currently online"}

dialect-rule: [['present | 'present?] (done: true who-is-online message-id)]

;; The implementation in this module is specific to SO chat. When the specific chat 
;; connectivity is factored out into its own module, this code should be changed to
;; delegate to the chat module being used. Note that it is conceivable that one bot 
;; instance could manage multiple chat rooms/systems.

;; Where to save the chat visitors
visitors-file: %visitors.r
visitors: copy []

;; Compile a list of known people
either not exists? visitors-file [
	visitors: copy []
	foreach [user data] about-users [
		append visitors form user
	]
	save visitors-file visitors
] [
	visitors: load visitors-file
]

;; Scan the html page, check to see who is here, and send a greet message to new users
who-is-online: func [message-id
	/silent ; silent is used by the forever loop to update the users online
	/local out page username userid len newbies addressees
] [
	addressees: copy ""
	len: length? visitors
	out: copy []
	newbies: copy []
	page: to string! read html-url
	parse page [
		some [
			thru "chat.sidebar.loadUser(" copy userid some id-rule thru {("} copy username to {")}
			(trim/all username
				username: decode-xml username
				append out username
				if not find visitors username [
					append visitors username
					append newbies username
				]
			)
		]
		to end
	]
	either empty? out [
		reply message-id "can not parse the page for users"
	] [
		either not silent [
			reply message-id form out
		] [
			; silent scan has detected new users - so let's greet them
			if not empty? newbies [
				foreach person newbies [
					append addressees ajoin ["@" person " "]
				]
				speak ajoin [addressees " " greet-message]
			]
		]
		if len < length? visitors [
			save visitors-file visitors
		]
	]
]

pulse-callback: does [who-is-online/silent 0]