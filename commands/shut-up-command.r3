REBOL [
  Title: "Shut up"
  Name: shut-up
  Type: module
  Role: command
  Version: 1.0.0
  Needs: [
    bot-api 1.0.0
  ]
  Options: [private]
]

help-string:
{shut up "Allows room administrators to kill the bot"}

user-id: user-string: text: existing-message-id: none
room-admins: []
attempt [
  parse read http://chat.stackoverflow.com/rooms/info/291/rebol-and-red?tab=access [
    thru <div class="access-list">
    some [
      thru "access-user-" copy user-id to {"} (append room-admins to-integer to-string user-id)
      thru {title="} copy user-string to {"} (append room-admins to-string user-string)
    ]
    to end
  ]
]

dialect-rule: [
  'shut 'up (
    either find room-admins person-id [
      ; privileged user
      quit/return 1
    ] [
      reply message-id ["Sorry, " user-name " you don't have access to kill me"]
    ]
  ) done: true
]
