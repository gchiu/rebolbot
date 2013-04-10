REBOL [
	Title:		"Show links by user - command"
	Name:		show-links-by-user-command
	Type:		module
	Version:	1.0.0
	Needs: [bot-api 1.0.0]
	Options: [private]
]

help-string: {show [all ][ recent ] links by user "shows links posted in messages by user"}

username: none

dialect-rule: [
	opt 'show opt 'me opt 'recent 'links ['by | 'from] [set username word! | set username string!] (
		done: true
		find-links-by message-id max-scan-messages username
	)
]

read-messages-by: func [n username
	/local result messages wanted content user
] [
	wanted: copy []
	username: form username
	result: load-json/flat read-messages n
	messages: result/2
	foreach msg messages [
		if parse msg [some [thru <content> copy content string! | thru <user_name> copy user string! to end]] [
			if user/1 = username [
				; found a message we want
				append wanted content
			]
		]
	]
	wanted
]

find-links-by: func [message-id n username
	/local result links link ilink text payload
] [
	links: copy []
	result: read-messages-by n username
	; now have a block of messages by username
	; {this is a link <a href="http://www.rebol.com" rel="nofollow">rebol tech</a> that I want to see}
	;["this is a link " <a href="http://www.rebol.com" rel="nofollow"> "rebol tech" </a> " that I want to see"]
	;{<a href="http://www.rebol.com">text</a>}
	;  [<a href="http://www.rebol.com"> "text" </a>]
	foreach content result [
		; grab all links from the message
		parse decode 'markup to binary! decode-xml content [
			some [
				opt string!
				set link tag!
				set text string!
				</a> (
					if parse form link [thru {a href="} copy ilink to {"} to end] [
						repend links [text ilink]
					]
				)
				opt string!
			]
		]
	]

	; we have all the links
	either empty? links [
		reply message-id ["No links found in the last " n " messages."]
	] [
		payload: rejoin [username " in the last " n " messages wrote the following links: "]
		foreach [text link] links [
			link: rejoin ["[" text "](" link "); "]
			either chat-length-limit < add length? payload length? link [
				reply message-id payload
				wait 2
				payload: copy link
			] [
				append payload link
			]
		]
		reply message-id payload
	]
]
