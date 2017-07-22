Rebol [
    title: "Speak on stackoverflow"
    author: "Graham"
    file: %so-speak.reb
    date: 23-July-2017
    needs: [
        <webform>
    ]
    settings: [
        email: -bot-email-address@here.com
        password: "bot-password"
        chat-page: https://chat.stackoverflow.com/rooms/291/rebol
    ]
    notes: {takes advantage of a new http write dialect word of 'no-redirect
        Still needs a generic cookie handling solution
    }
]

net-trace off
room-id: 291
room-descriptor: "rebol*"

so-chat-url: https://chat.stackoverflow.com/
chat-target-url: rejoin write-chat-block: [so-chat-url 'chats "/" room-id "/" 'messages/new]
referrer-url: rejoin [so-chat-url 'rooms "/" room-id "/" room-descriptor]

cookie-jar: make map! []

find-all-cookies: function [
    {given a cookie string or block, all cookies are returned}
    cookie-string [string! block!]
][
    cookies: copy []
    if string? cookie-string [
        tmp: copy []
        append tmp cookie-string
        cookie-string: tmp
    ]
    exes: ["path=" "MAX-AGE=" "uauth=true" "domain=.stackoverflow.com" "expires=" ".ASPXBrowserOverride="]
    exclusions?: function [e][
        for-each element exes [
            if find e element [
                return false
            ]
        ]
        true
    ]

    for-each cookie cookie-string [
        for-each element split cookie ";" [
            trim/head/tail element
            if all [
                find element "=" 
                exclusions? element
            ][
                append cookies element
            ]
        ]
    ]
    cookies
]

update-cookie-jar: procedure [
    {adds cookies to cookie-jar or updates if present}
    headers [object!] site [block!]
][
    if all [
        find headers 'set-cookie 
        cookies: find-all-cookies headers/set-cookie
        not empty? cookies
    ][
        either find cookie-jar site/host [
            repend cookie-jar [lock site/host cookies]
        ][
            lock site/host
            cookie-jar/(site/host): cookies
        ]
    ]
]        

search-cookie-jar: function [
    {returns any cookies that match the domain}
    cookie-jar [map!] domain [string!] 
][
    result: collect [
        for-each [key value] cookie-jar [
            if find key domain [
                keep value 
            ]
        ]
    ]
    delimit result "; "
]

login2so: function [
    {login to stackoverflow and return an authentication object}
    email [email!] password [string!] chat-page [url!]
][
    configobj: make object! [fkey: copy "" bot-cookie: copy ""]
    fkey: _
    root: https://stackoverflow.com
    loginpage: to string! read loginurl: https://stackoverflow.com/users/login
    print "read ..."
    if parse loginpage [thru "login-form" thru {action="} copy action to {"} thru "fkey" thru {value="} copy fkey to {"} thru {"submit-button"} thru {value="} copy login to {"} to end][
        ; dump action
        postdata: to-webform reduce ['fkey fkey 'email email 'password password 'submit-button login]
        print "posting login data"
        result: trap [
            write post-url: to url! unspaced [root action] compose/deep 
            [headers no-redirect POST [Content-Type: "application/x-www-form-urlencoded; charset=utf-8"] (postdata)]
        ]
        ; grab the headers and update the cookie-jar after successful authentication
        update-cookie-jar headers: result/spec/debug/headers site: sys/decode-url post-url

        ; now grab the SO cookies - we are asked to redirect there but we don't need to as we only need the cookies
        site: sys/decode-url url: to url! headers/location
        cookie: search-cookie-jar cookie-jar site/host

        ; now grab the chatroom cookie, "chatusr" but it doesn't seem to be used??
        result: trap [
            write chat-page compose/deep [headers no-redirect GET [cookie: (cookie)]]
        ]

        update-cookie-jar headers: result/spec/debug/headers site: sys/decode-url chat-page 
        if not parse to string! result/data [ thru {name="fkey"} thru {value="} copy fkey to {"} to end ][
            fail  "No Fkey so can not login"
        ]
        configobj/fkey: fkey
        ; there's a chat.stackoverflow.com coookie but it wants the stackoverflow.com cookie!
        ; configobj/bot-cookie: delimit cookie-jar/("stackoverflow.com") "; "
        configobj/bot-cookie: search-cookie-jar cookie-jar "stackoverflow.com"
    ]
   configobj
]

auth-object: login2so system/script/header/settings/email system/script/header/settings/password  system/script/header/settings/chat-page

dump auth-object

header: compose [
    Host: "chat.stackoverflow.com"
    Origin: "http://chat.stackoverflow.com"
    Accept: "application/json, text/javascript, */*; q=0.01"
    X-Requested-With: "XMLHttpRequest"
    Referer: (referrer-url)
    Accept-Encoding: "gzip,deflate"
    Accept-Language: "en-US"
    Accept-Charset: "ISO-8859-1,utf-8;q=0.7,*;q=0.3"
    Content-Type: "application/x-www-form-urlencoded"
    cookie: (auth-object/bot-cookie)
]

speak: func [message /local err] [
    if error? err: trap [
        write chat-target-url compose/deep copy/deep [
            headers no-redirect POST
            [(header)]
            (rejoin ["text=" url-encode message "&fkey=" auth-object/fkey])
        ]
    ][
        probe err
    ]
]

halt
speak "Final test of new so-chat utility"
