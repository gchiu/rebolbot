REBOL [
    Title: "Twitter Client for REBOL"
    Date: 10-Jun-2013
    Author: "Christopher Ross-Gill/John Kenyon"
    Version: 0.3.6
    type: module
    name: twitter
    exports: [ twitter ]
    Rights: http://creativecommons.org/licenses/by-nc-sa/2.0/
    File: %twitter.r3
    Needs: [
        ; http://reb4.me/r3/altwebform
        ; %altwebform.reb
        ; https://raw.githubusercontent.com/r3n/renclib/master/modules/json.reb
        ; http://reb4.me/r3/altjson
    ]
    Purpose: {
        REBOL script to access and use the Twitter OAuth API.
        Warning: Currently configured to use HTTP only
        New user registration must be done using rebol 2 version
        This function will be updated when https is available (for Linux)
    }
]

import <webform>
import <json>

; Local words
authorized-users: twitter-config: twitter-url: settings: users: _

twitter: context bind [
    as: func [
        [catch]
        "Set current user"
        user [string!] "Twitter user name"
    ][
        either user: select users user [
            persona: make persona user
            persona/name
        ][
            either not error? user: try [register][
                repend users [
                    user/name
                    new-line/skip/all body-of user true 2
                ]
                persona/name
            ][throw :user]
        ]
    ]

    save-users: func [
        "Saves authorized users"
        /to location [file! url!] "Alternate Storage Location"
    ][
        location: any [location settings/user-store]
        unless any [file? location url? location][
            make error! "No Storage Location Provided"
        ]
        save/header location new-line/skip/all users true 2 context [
            Title: "Twitter Authorized Users"
            Date: now/date
        ]
    ]

    authorized-users: func ["Lists authorized users"][extract users 2] 

    find: func [
        "Tweets by Search" [catch]
        query [string! issue! email!] "Search String"
        /size count [integer!] /page offset [integer!]
    ][ 
        case [
            issue? query [query: mold query]
            email? query [query: join-of "@" query/host]
        ]
        set params reduce [query offset count]
        either attempt [
            result: to string! read join-of http://search.twitter.com/search.json? to-webform params
        ] load-result error/connection
    ]

    timeline: func [
        "Retrieve a User Timeline" [catch]
        /for user [string!] /size count [integer!] /page offset [integer!]
    ][
        unless persona/name error/credentials

        set options reduce [
            any [user persona/name]
            all [count min 200 abs count]
            offset
        ]

        either attempt [
            result: send/with 'get %1.1/statuses/user_timeline.json options
        ] load-result error/connection
    ]

    home: friends: func [
        "Retrieve status messages from friends" [catch]
        /size count [integer!] /page offset [integer!]
    ][
        unless persona/name error/credentials

        set options reduce [
            _
            all [count min 200 abs count]
            offset
        ]

        either attempt [
            result: send/with 'get %1.1/statuses/home_timeline.json options
        ] load-result error/connection
    ]

    update: func [
        "Send Twitter status update" [catch]
        status [string!] "Status message"
        /reply "As reply to" id [issue!] "Reply reference" /override
    ][
        override: either override [200][140]
        unless persona/name error/credentials
        unless all [0 < length? status override > length? status] error/invalid
        set message reduce [status id]
        ;either attempt [
            result: send/with 'post %1.1/statuses/update.json message
        ;] load-result error/connection
    ]

] context [ ; internals
    either exists? %twitter-config.r3 [
        twitter-config: object load %twitter-config.r3
        twitter-url: twitter-config/twitter
        settings: make context [
            consumer-key: consumer-secret: users: _
        ] [ 
            consumer-key: twitter-config/consumer-key
            consumer-secret: twitter-config/consumer-secret
        ]
        users: twitter-config/users
    ] [
        print "No configuration file"
        halt
    ]

    options: context [screen_name: count: page: _]
    params: context [q: page: rpp: _]
    message: context [status: in_reply_to_status_id: _]

    result: _
    load-result: [load-json result]

    error: [
        credentials [throw make error! "User must be authorized to use this application"]
        connection [throw make error! "Unable to connect to Twitter"]
        invalid [throw make error! "Status length should be between between 1 and 140"]
    ]

    persona: context [
        id: name: _
        token: secret: _
    ]

    oauth!: context [
        oauth_callback: _
        oauth_consumer_key: settings/consumer-key
        oauth_token: oauth_nonce: _
        oauth_signature_method: "HMAC-SHA1"
        oauth_timestamp: _
        oauth_version: 1.0
        oauth_verifier: oauth_signature: _
    ]

    send: use [make-nonce timestamp sign][
        make-nonce: does [
            enbase/base checksum/secure to binary! join-of now/precise settings/consumer-key 64
        ]

        timestamp: func [/for date [date!]][
            date: any [date now]
            date: form any [
                attempt [to integer! difference date 1-Jan-1970/0:0:0]
                date - 1-Jan-1970/0:0:0 * 86400.0
            ]
            clear find/last date "."
            date
        ]

        sign: func [
            method [word!]
            lookup [url!]
            oauth [object! block! blank!]
            params [object! block! blank!]
            /local out
        ][
            out: copy ""

            oauth: any [oauth make oauth! []]
            oauth/oauth_nonce: make-nonce
            oauth/oauth_timestamp: timestamp
            oauth/oauth_token: persona/token

            params: make oauth any [params []]
            params: sort/skip body-of params 2

            forskip params 2 [params/1: to word! params/1 if issue? params/2 [ params/2: to string! to word! params/2 ] ]
            oauth/oauth_signature: enbase/base checksum/secure/key to binary! rejoin [
                uppercase form method "&" replace/all url-encode form lookup "%5f" "_" "&"
                replace/all replace/all url-encode replace/all to-webform params "+" "%20" "%5f" "_" "%255F" "_"
            ] rejoin [
                settings/consumer-secret "&" any [persona/secret ""]
            ] 64

            foreach [header value] body-of oauth [
                if value [
                    repend out [", " form to string! to word! header {="} url-encode form value {"}]
                ]
            ]

            join-of "OAuth" next out
        ]

        send: func [
            [catch]
            method [word!] lookup [file!]
            /auth oauth [object!]
            /with params [object!]
        ][
            lookup: twitter-url/:lookup
            oauth: make oauth! any [oauth []]
            if object? params [params: body-of params ]

            switch method [
                put delete [
                    params: compose [method: (uppercase form method) (any [params []])]
                    method: 'post
                ]
            ]

            switch method [
                get [
                    method: compose/deep [
                        get [ Authorization: (sign 'get lookup oauth params) ]
                    ] 
                    if params [
                        params: context sort/skip params 2
                        append lookup to-webform/prefix params
                    ]
                ]
                post put delete [
                    method: compose/deep [
                        (method) [
                            Authorization: (sign method lookup oauth params)
                            Content-Type: "application/x-www-form-urlencoded"
                        ]
                        (either params [to-webform params][""]) 
                    ]
                ]
            ]
            lookup: to string! write lookup method
        ]
    ]

    register: use [request-broker access-broker verification-page][
        request-broker: %oauth/request_token
        verification-page: %oauth/authorize?oauth_token=
        access-broker: %oauth/access_token

        func [
            /requester request [function!]
            /local response verifier
        ][
            request: any [:request :ask]
            set persona _

            response: load-webform send/auth 'post request-broker make oauth! [
                oauth_callback: "oob"
            ]

            persona/token: response/oauth_token
            persona/secret: response/oauth_token_secret

            browse join-of twitter-url/:verification-page response/oauth_token 
            unless verifier: request "Enter your PIN from Twitter: " [
                make error! "Not a valid PIN"
            ]

            response: load-webform send/auth 'post access-broker make oauth! [
                oauth_verifier: trim/all verifier
            ]

            persona/id: to-issue response/user_id
            persona/name: response/screen_name
            persona/token: response/oauth_token
            persona/secret: response/oauth_token_secret

            persona
        ]
    ]
]
