REBOL [
    Title:      "Search - command"
    Name:       search-command
    Type:       module
    Role:       command
    Version:    1.0.0
    Needs:      [bot-api 1.0.0]
    Date:       [ 16-June-2013 21-July-2013 ]
    Author:     "Graham Chiu"
    Options:    [private]
]

help-string: {search key "retrieves all messages in store that contains key"}

target: none

message-template: {<div class="monologue user-$user_id">
    <div class="signature"><div class="tiny-signature">
        <div class="username"><a href="/users/$user_id/$user_name" title="$user_name">$user_name</a></div>
    </div></div>
    <div class="messages">
             <div class="timestamp">$time_stamp</div>
            <div class="message" id="message-$message_id">
                <a name="$message_id" href="/transcript/291?m=$message_id#$message_id"><span style="display:inline-block;" class="action-link"><span class="img"> </span></span></a>
                <div class="content">
                    $content
                </div>
                <span class="flash">
                </span>
            </div>
    </div>
    <div class="clear-both" style="height:0">&nbsp;</div> 
</div>}

dialect-rule: [
    'search [set target string! | set target word!] (
        done: true
        either any [
            "red" = form target
            3 < length? form target
        ] [
            use [json out outstring cnt html filename filepath webroot html-template] [
				webroot: %/var/www/bot-site/html/
                cnt: 0
                out: copy []
				html: make string! 1000
                outstring: copy "First 50 results^/"

                ?? storage                  
                foreach file sort/reverse read storage [
                    if cnt > 50 [
                        break
                    ]
                    if not dir? file [
                        json: load-json to string! read join storage file

                        if all [
                            in json 'content
                            find json/content form target
                        ] [
                            ++ cnt
                            repend/only out [json/time_stamp json/user_name json/message_id json/user_id json/content]
                        ]
                    ]
                ]
                either empty? out [
                    reply message-id ajoin ["sorry, " target " not found so far"]
                ] [
					; now have all the messages so now construct the content for the html
					foreach result out [
						append html reword message-template reduce [
							'time_stamp from-now unix-to-date result/1
							'user_name result/2
							'message_id result/3
							'user_id result/4
							'content result/5
						]
					]
					; and now create the html - this needs some config
					html-template: to string! read join webroot %chat-search.html
					outstring: reword html-template reduce [
						'content html
						'number length? out
					]
					filepath: rejoin [ webroot filename: join checksum to binary! outstring %.html ]
					write filepath outstring
				
                    reply message-id ajoin [ {[Query results for } target {](http://www.rebol.info/} filename {)} ]
                ]
            ]
        ] [
            reply message-id "Query string needs to be at least 4 characters"
        ]
    )
]
