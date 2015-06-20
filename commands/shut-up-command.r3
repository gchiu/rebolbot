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

help-string: {shut up "Allows room users to kill the bot"}

dialect-rule: [
  'shut 'up (
    quit/return 42
  )
]
