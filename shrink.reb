REBOL [
    Title: "Simple Virtual Shrink"
    Date: 10-Jun-1999
    File: %shrink.reb
    Author: "Martin Johannesson"
    Purpose: {
        This script is a virtual shrink "chatter bot".
        It was obviously inspired by the original shrink bot
        called Eliza. When the program gets a sentence in
        English, it tries to find a matching rule in its    
        rule database and if it understands the sentence
        it tries to give a reasonable reply.
        (Type "quit" to quit)
    }
    Notes: {14-May-2017 modded to work with ren-c - Graham}
    Email: %d95-mjo--nada--kth--se
    library: [
        level: 'advanced 
        platform: _ 
        type: _ 
        domain: 'game 
        tested-under: _ 
        support: _ 
        license: _ 
        see-also: _
    ]
]

chat-bot: make object! [

    rules: copy []
    substitutions: [
        "are"      [substitute-verb "I" "am" "you" tokens]
        "am"       [substitute-verb "you" "are" "I" tokens]
        "were"     [substitute-verb "I" "was" "you" tokens]
        "was"      [substitute-verb "you" "were" "I" tokens]
        "weren't"  [substitute-verb "I" "wasn't" "you" tokens]
        "wasn't"   [substitute-verb "you" "weren't" "I" tokens]
        "my"       ["your"]
        "mine"     ["yours"]
        "me"       ["you"]
        "I"        ["you"]
        "I'm"      ["you're"]
        "I'd"      ["you'd"]
        "I'll"     ["you'll"]
        "you"      [substitute-you tokens]
        "you're"   ["I'm"]
        "you'd"    ["I'd"]
        "you'll"   ["I'll"]
        "your"     ["my"]
        "yours"    ["mine"]
    ]
    
    prepositions: [
        "on" "from" "to" "at" "in" "through" "by" "for"
        "without" "with" "around" "behind" "before" "of"
        "beside" "under" "over" "between" "after" "about"
    ]

    substitute-you: func [tokens] [
        either any [
            (find prepositions (pick tokens -1))
            (find prepositions (pick tokens 2))
            ]["me"]["I"]
        ]
    
    substitute-verb: func [prev-word new-word next-word tokens] [
        either any [
            ((pick tokens -1) = prev-word)
            ((pick tokens 2) = next-word)
            ][new-word][first tokens]
    ]

    sentence-chars: charset [#" " #"?" #"!" #"." #","]

    substitute: func [sentence /local subst-word] [
        tokens: split sentence sentence-chars ;" ?!.,"
        while [not tail? tokens] [
            subst-word: do select substitutions first tokens
            if any [subst-word] [
                change tokens subst-word
            ]
            tokens: next tokens
        ]
        return head tokens
    ]
    
    make-parse-rule: func [match-rule /local parse-rule token] [
        parse-rule: copy []
        while [not tail? match-rule] [
            token: first match-rule
            parse-rule: join-of parse-rule either word? token [[
                    'copy token 
                    'to either tail? next match-rule ['end][
                        second match-rule
                    ]
                ]
            ][token]
            match-rule: next match-rule
        ]
        return parse-rule
    ]


    match: func [sentence /local reply token] [
        foreach [p-symbol phrases r-symbol replies] rules [
            foreach phrase phrases [
                if parse sentence make-parse-rule phrase [
                    reply: pick replies random (length? replies)
                    foreach token reply [
                        if word? token [
                            set :token substitute get token
                        ]
                    ]
                    return rejoin head reply
                ]
            ]
        ]
    ]

    input-eval-loop: func [] [
        while [true] [
            sentence: ask "chatbot> "
            if sentence = "quit" [break]
            print match sentence
        ]
    ]
]

rules: [
    
    phrases [
        ["hello" x]
        ["hi" x]
    ]
    replies [
        ["Hey, please state your problem."]
        ["Hi, please state your problem."]
        ["Hello, please state your problem."]
    ]
    
    phrases [["what's up" x]]
    replies [
        ["Nothing"]
        ["Not much"]
    ]
    
    phrases [[z "sorry" y]]
    replies [
        ["Please don't applogize."]
        ["Appologies are not necessary."]
        ["What feelings do you have when you apologize?"]
    ]

    phrases [[z "I remember " y]]
    replies [
        ["Do you often think of " y "?"]
        ["Does thinking of " y " bring anything else to mind?"]
        ["What else do you remember?"]
        ["Why do you remember " y " just now?"]
        ["What in the present situation reminds you of " y "?"]
        ["What is the connection between me and " y "?"]
    ]

    phrases [[z "do you remember " y]]
    replies [
        ["Did you think I would forget " y "?"]
        ["Why do you think I should recall " y " now?"]
        ["What about " y "?"]
        ["No, I don't"]
    ]

    phrases [["how are you" x]]
    replies [
        ["Fine, thanks"]
        ["I'm doing ok"]
        ["Fine, thanks. How are you?"]
    ]       
    
    phrases [[z "I dreamt" y]]
    replies [
        ["Really?"]
        ["Have you ever fantasised " y " while you were awake?"]
        ["Have you ever dreamt " y " before?"]
        ["What does that dream suggest to you?"]
        ["Do you dream often?"]
        ["What persons appear in your dreams?"]
        ["Do you believe that dreaming has something to do with your problem?"]
    
    ]

    phrases [[z "dream" y]]
    replies [
        ["What does that dream suggest to you?"]
        ["Do you dream often?"]
        ["What persons appear in your dreams?"]
        ["Do you believe that dreaming has something to do with your problem?"]
    ]

    phrases [[z "perhaps" y]]
    replies [
        ["You do not seem quite certain."]
        ["Why the uncertain tone?"]
        ["Can you not be more positive?"]
        ["You are not sure?"]
        ["Do you not know?"]
    ]

    phrases [["what is your name" y]]
    replies [
        ["None of your business."]
        ["Bond. James Bond"]
        ["I'd rather not say."]
    ]

    phrases [[z "name" y]]
    replies [
        ["I am not interested in names."]
        ["Please continue."]
    ]

    phrases [
        [z "computer" y]
        [z "amiga" y]
        [z "macintosh" y]
        [z "pc" y]
        [z "machine" y]
    ]
    replies [
        ["Do computers worry you?"]
        ["Why do you mention computers?"]
        ["What do you think machines have to do with your problem?"]
        ["Do you not think computers can help people?"]
        ["What about machines worries you?"]
        ["What do you think about machines?"]
    ]

    phrases [[z "am I " y]]
    replies [
        ["Do you believe you are " y "?"]
        ["Would you want to be " y "?"]
        ["You wish I would tell you you are " y "?"]
        ["What would it mean if you were " y "?"]
    ]

    phrases [[z "are you " y]]
    replies [
        ["What makes you think I'm " y "?"]
        ["Why are you interested in whether I am " y " or not?"]
        ["Would you prefer if I were not " y "?"]
        ["Perhaps I am " y " in your fantasies."]
        ["Do you sometimes think I am " y "?"]
    ]
    
    phrases [[z "your " y]]
    replies [
        ["Why are you concerned over my " y "?"]
        ["What about your own " y "?"]
        ["Are you worried about someone elses " y "?"]
        ["Really, my " y "?"]
    ]

    phrases [[z "was I " y]]
    replies [
        ["What if you were " y "?"]
        ["Do you think you were " y "?"]
        ["Were you " y "?"]
        ["What would it mean to you if you were " y "?"]
        ["Perhaps I already knew that you were " y "?"]
    ]

    phrases [[z "I was " y]]
    replies [
        ["Were you really?"]
        ["Why do you tell me you were " y " just now?"]
        ["Perhaps I already knew you were " y "."]      
    ]

    phrases [[z "were you " y]]
    replies [
        ["Would you like to believe I was " y "?"]
        ["What suggests that I was " y "?"]
        ["What do you think?"]
        ["Perhaps I was " y "."]
        ["What if I had been " y "?"]       
    ]

    phrases [[z "I don't " y]]
    replies [
        ["Do you not really " y "?"]
        ["Why do you not " y "?"]
        ["Do you wish to be ablt to " y "?"]
        ["Does that trouble you?"]
    ]

    phrases [[z "I feel " y]]
    replies [
        ["Tell me more about such feelings."]
        ["Do you often feel " y "?"]
        ["Do you enjoy feeling " y "?"]
        ["Of what does feeling " y " remind you?"]
    ]

    phrases [[z "I can't " y]]
    replies [
        ["How do you know you can not " y "?"]
        ["Have you tried?"]
        ["Perhaps you could " y " now?"]
        ["Do you really want to be able to " y "?"]
    ]

    phrases [
        [z "I want " y]
        [z "I need " y]
    ]
    replies [
        ["What would it mean to you if you got " y "?"]
        ["Why do you want " y "?"]
        ["Suppose you got " y " soon?"]
        ["What if you never got " y "?"]
        ["What would getting " y " mean to you?"]
        ["What does wanting " y " have to do with this discussion?"]
    ]

    phrases [
        [z "I feel " x "I " y]
        [z "I think " x "I " y]
        [z "I believe " x "I " y]
        [z "I wish " x "I " y]
    ]
    replies [
        ["Do you really think so?"]
        ["But are you sure you " y "?"]
        ["Do you really doubt you " y "?"]
    ]

    phrases [
        [z "I'm " y]
        [z "I am " y]
    ]
    replies [
        ["I am sorry to hear that."]
        ["Do you think coming here will help you?"]
        ["I am sure it is not pleasant to be " y]
        ["Why is that?"]
        ["Do you believe it's normal to be " y "?"]
        ["How long have you been " y "?"]
        ["Do you enjoy being " y "?"]
        ["Can you elaborate on that?"]
    ]

    phrases [[z "I " x " you" y]]
    replies [
        ["Perhaps in your fantasy we " x " each other?"]
        ["Do you wish to " x " me?"]
        ["You seem to need to " x " me."]
        ["Do you " x " anyone else?"]
    ]

    phrases [[z "I hate " y]]
    replies [
        ["Why do you hate " y "?"]
    ]

    phrases [[z "you remind me of " y]]
    replies [
        ["What resemblance do you see?"]
    ]

    phrases [[z "you are " y]]
    replies [
        ["What makes you think I am " y "?"]
        ["Does it please you to believe I am " y "?"]
        ["Do you sometimes wish you were " y "?"]
        ["Perhapes you would like to be " y "?"]
    ]

    phrases [[z "you " x "me" y]]
    replies [
        ["Why do you think I " x " you?"]
        ["You like to think I " x " you, don't you?"]
        ["What makes you think I " x " you?"]
        ["Really, I " x " you."]
        ["Do you wish to believe I " x " you?"]
        ["Suppose I did " x " you, what would it mean to you?"]
        ["Does someone else believe I " x "you?"]
    ]

    phrases [[z "you " y]]
    replies [
        ["We were discussing you, not me."]
        ["Oh, I " y "."]
        ["What are your feelings now?"]
    ]

    phrases [["yes" y]]
    replies [
        ["You seem quite positive."]
        ["Are you sure?"]
        ["I see."]
        ["I understand"]
    ]

    phrases [["no" y]]
    replies [
        ["Are you saying that just to be negative?"]
        ["You are being a bit negative."]
        ["Why not?"]
        ["Why no?"]
    ]

    phrases [["why don't you " y]]
    replies [
        ["Do you believe I do not " y "?"]
        ["Perhaps I will " y " in good time."]
        ["Should you " y " yourself?"]
        ["You want me to " y "?"]
    ]

    phrases [["why can't I " y]]
    replies [
        ["Do you think you should be able to " y "?"]
        ["Do you want to be able to " y "?"]
        ["Do you believe this will help you to " y "?"]
        ["Have you any idea why you can not " y "?"]
    ]

    phrases [
        ["what " y]
        ["why " y]
    ]
    replies [
        ["Why do you ask?"]
        ["Does that question interest you?"]
        ["What is it you really want to know?"]
        ["Are such questions on your mind?"]
        ["What answer would please you the most?"]
        ["What do you think?"]
        ["What comes to your mind when you ask that?"]
    ]

    phrases [["because " y]]
    replies [
        ["Is that the real reason?"]
        ["Do any other reasons not come to mind?"]
        ["Does that reason seem to explain anything else?"]
        ["What other reasons might there be?"]
    ]

    phrases [[z "always" y]]
    replies [
        ["Can you think of a specific example?"]
        ["When?"]
        ["What incident are you thinking of?"]
        ["Really, always?"]
    ]
    

    phrases [[x]]
    replies [
        ["What are you trying to say?"]
        ["I'm not sure I understand..."]
        ["What?"]
        ["Please continue."]
        ["What do you mean?"]
        ["That's very interesting."]
        ["Can you elaborate on that?"]
        ["Can you be a little more specific?"]
    ]
]

chat-bot/rules: rules
chat-bot/input-eval-loop
