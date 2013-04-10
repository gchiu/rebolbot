REBOL [
	Title:		"What is current time relative to GMT? - command"
	Name:		what-is-time-relative-to-gmt-command
	Type:		module
	Version:	1.0.0
	Needs: [bot-api 1.0.0]
	Options: [private]
]

help-string: {what is the time?}

dialect-rule: ['what 'is 'the ['time | 'time?] opt ['now? | 'now | 'in 'GMT] (done: true reply-time message-id)]

reply-time: func [message-id] [reply message-id to-idate now]