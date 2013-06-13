REBOL [
	Title: "API"
	Name: bot-api
	Type: module
	Version: 1.0.0
	Options: []
	Exports: [
		about-users
		botname
		bot-expressions
		chat-length-limit
		commands
		done
		delete-message
		greet-message
		header
		html-url
		id-rule
		low-rep-message
		max-scan-messages
		message-id
		no-of-messages
		parent-id
		person-id
		pause-period
		percent-encode
		privileged-users
		profile-url
		read-messages
		read-message
		referrer-url
		reply
		speak
		speak-debug
		speak-private
		to-idate
		to-itime
		to-markdown-code
		url-encode
		user-name
	]
]

; The name of the bot
; Configured in bot-config.r
botname: none

; The command modules loaded by the bot
commands: []

; The message new users will be greeted with
; Configured in bot-config.r
greet-message: ""

; The message new users with a reputation lower than 20
; will be greeted with.
; Configured in bot-config.r
low-rep-message: ""

; The number of messages to fetch at a time
no-of-messages: none

; The maximum number of characters allowed by the chat system
chat-length-limit: none

; Users who have special privileges with the bot (e.g. remove keys)
; privileged-users: ["HostileFork" 211160 "Graham Chiu" 76852 "johnk" 1864998]
privileged-users: []

; Mapping of username to info-link + timezone
; about-users: [
; 	earl [https://github.com/earl 1:00]
; 	graham [https://github.com/gchiu/ 13:00]
; ]
about-users: []

; Mapping of keyword to description + URL
; bot-expressions: [
; 	"help" ["FAQ" http://rebolsource.net/go/chat-faq]
; 	"tutorial" ["Introduction to Rebol" http://www.rebol.com/rebolsteps.html]
; 	"Devcon" ["Red Video from Devcon 2013" https://www.youtube.com/watch?v=JjPKj0_HBTY]
; ]
bot-expressions: []

; Signifies that a command's dialect rule is done
done: false

; The parse rule for user IDs
id-rule: none

; The main chat URL with highlight turned off
html-url: none

; The main chat URL
referrer-url: none

to-markdown-code: func [ txt ][]

profile-url: person-id: user-name: message-id: parent-id: none

read-messages: func [cnt] []

read-message: func [message-id] []

delete-message: func [parent-id message-id /silent
	/local result mess
] []

speak-private: func [message room-id] []

speak-debug: func [message /local err] []

speak: func [message /local err] []

reply: func [message-id text [string! block!]] []

percent-encode: func [char [char!]] []

url-encode: func [text] []

to-itime: func [
	{Returns a standard internet time string (two digits for each segment)}
	time [time! number! block! none!]
] []

to-idate: func [
	"Returns a standard Internet date string."
	date [date!]
	/local str
] []
