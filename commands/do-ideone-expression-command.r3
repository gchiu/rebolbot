REBOL [
    Title:      "Evaluate an expression against an ideone supported language interpreter - command"
    Name:       do-ideone-expression-command
    Type:       module
    Version:    1.0.0
    Needs:      [bot-api 1.0.0]
    Options:    [private]
]

help-string: {do/ideone which-lang [word! string! integer!] expression "evaluates a source expression for the specified language"}

language: expression: none

dialect-rule: [
    'do/ideone [set language word! | set language string! | set language integer!] copy expression to end
    (done: true
        attempt [
            probe mold/only expression
            evaluate-by-ideone ideone-user ideone-pass mold/only expression language ""
        ]
    )
]

soap-execute-template: {<?xml version="1.0" encoding="UTF-8" standalone="no"?><SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tns="http://ideone.com:80/api/1/service" xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ><SOAP-ENV:Body><mns:createSubmission xmlns:mns="http://ideone.com:80/api/1/service" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><user xsi:type="xsd:string">$a</user><pass xsi:type="xsd:string">$b</pass><sourceCode xsi:type="xsd:string">$c</sourceCode><language xsi:type="xsd:int">$d</language><input xsi:type="xsd:string">$e</input><run xsi:type="xsd:boolean">$f</run><private xsi:type="xsd:boolean">$g</private></mns:createSubmission></SOAP-ENV:Body></SOAP-ENV:Envelope>}

soap-response-template: {<?xml version="1.0" encoding="UTF-8" standalone="no"?><SOAP-ENV:Envelope xmlns:SOAP-ENV="http://schemas.xmlsoap.org/soap/envelope/" xmlns:tns="http://ideone.com:80/api/1/service" xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" xmlns:soap-enc="http://schemas.xmlsoap.org/soap/encoding/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" ><SOAP-ENV:Body><mns:getSubmissionDetails xmlns:mns="http://ideone.com:80/api/1/service" SOAP-ENV:encodingStyle="http://schemas.xmlsoap.org/soap/encoding/"><user xsi:type="xsd:string">$user</user><pass xsi:type="xsd:string">$pass</pass><link xsi:type="xsd:string">$link</link><withSource xsi:type="xsd:boolean">1</withSource><withInput xsi:type="xsd:boolean">1</withInput><withOutput xsi:type="xsd:boolean">1</withOutput><withStderr xsi:type="xsd:boolean">1</withStderr><withCmpinfo xsi:type="xsd:boolean">1</withCmpinfo></mns:getSubmissionDetails></SOAP-ENV:Body></SOAP-ENV:Envelope>}

evaluate-by-ideone: func [user pass source [string!] language [word! string! integer!] inpt [string!]
    /local result result2 error status link inputs output
] [
    error: status: link: none
    ;print "in eval ideone"

    ;?? source
    source: head remove source head remove back tail source
    ;?? source

    if not integer? language [
        language: select [
            "forth" 107
            "ruby" 17
            "javascript" 35
            "scheme" 33
            "python" 4
            "perl" 3
        ] to string! language
    ]
    if none? language [
        reply message-id "Unsupported language"
        return
    ]
    ;?? user ?? pass ?? source ?? language ?? inpt
    print reword soap-execute-template reduce [
        'a user
        'b pass
        'c source
        'd language
        'e inpt
        'f "1"
        'g "1"
    ]
    result: write ideone-url reduce ['SOAP (
            reword soap-execute-template reduce [
                'a user
                'b pass
                'c source
                'd language
                'e inpt
                'f "1"
                'g "1"
            ]
        )
    ]
    ; should get an error code
    probe decode 'markup result
    if parse decode 'markup result [
        thru <item> <key xsi:type="xsd:string"> copy error to </key>
        thru <value xsi:type="xsd:string"> copy status to </value>
        thru <item> <key xsi:type="xsd:string"> "link" </key>
        <value xsi:type="xsd:string"> copy link to </value>
        to end] [
        if all [
            error/1 = "error"
            status/1 = "OK"
        ] [
            ; we have a link value to get the result
            probe reword soap-response-template reduce [
                'user user
                'password pass
                'link link/1
            ]
            ; wait before picking up the result
            wait 5

            result2: write ideone-url reduce ['SOAP (
                    reword soap-response-template reduce [
                        'user user
                        'pass pass
                        'link link/1
                    ]
                )
            ]
            if result2 [
                if parse decode 'markup result2 [
                    thru "source" </key>
                    thru <value xsi:type="xsd:string"> copy inputs to </value>
                    thru "output" </key>
                    thru <value xsi:type="xsd:string"> copy output to </value> to end
                ] [
                    reply message-id rejoin [
                        "    RebolBot uses http://ideone.com (c) http://sphere-research.com" newline
                        "    " decode-xml inputs/1 newline
                        "    " decode-xml output/1
                    ]
                ]
            ]
        ]
    ]
]


