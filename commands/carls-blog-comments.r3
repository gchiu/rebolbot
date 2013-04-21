REBOL [
Title: "Display Carl's blog comments"
Name: carls-blog-comments
Type: module
Version: 1.0.0
Needs: [bot-api 1.0.0]
Options: [private]
]

help-string: {carls-blog last updated "when did we last check for new comments from rebol.com/blog.r"}

last-updated-file: %blog-last-updated.r3

dialect-rule: [
  'carls-blog (
    done: true
    reply message-id reform [
      "I last checked Carl's blog for new comments on"
      any [
        attempt [ load last-updated-file ]
        "... I forget. Ask me later."
      ]
    ]
  )
]

process-blog: funct [
] [
  blog-comment-data: copy []
  ;;blog-comment-data-spec: [
  ;;  article article-link [ name datetime comment name datetime comment ] article aticle-link [ name datetime comment ] 
  ;;]
  diff-to-localtime: -8:00:00
  comment-length: 140
  article: copy ""
  base-article-link: http://www.rebol.com
  article-link: copy ""
  comment-content: copy ""
  datetime: copy ""
  name: copy ""
  
  attempt [
    article-rule: [
      {<tr><td colspan=2><b><a href="} copy article-link to {">} thru {">} copy article to </a>
      (append blog-comment-data reduce [to-string article article-link copy [] ])
    ]
    name-rule: [
      {<tr><td width="10%" valign="top" nowrap bgcolor="} thru <b> copy name to </b>
      (append last blog-comment-data to-string name)
    ]
    datetime-rule: [
      {<br><font size="1" color="gray">} copy datetime to </font>
      (append last blog-comment-data to-date replace to-string datetime " " "/")
    ]
    comment-rule: [
      {</td><td width="90%" valign="top" bgcolor="} thru {">} copy comment-content to </td>
      (append last blog-comment-data to-string comment-content)
    ]
    blog: read http://www.rebol.com/cgi-bin/blog.r?cmt-week=1

    parse blog [
      any [ article-rule | name-rule | datetime-rule | comment-rule | skip ]
    ]

    last-updated: any [ attempt [ load last-updated-file ] (now + diff-to-localtime) ]
    foreach [ article article-link comments ] blog-comment-data [
      foreach [ name datetime comment-content ] comments  [
        if positive? (difference (datetime + diff-to-localtime) last-updated) [
          ;print [ article name datetime last-updated]
          remove-each tag comment-content: decode 'markup to binary! comment-content [tag? tag]
          comment-content: head clear skip reform comment-content comment-length
          comment-content: copy/part comment-content any [ find/last comment-content " " length? comment-content ]
          lib/speak reform [ name "-" article comment-content "..." join base-article-link (to string! article-link) ]
        ]
      ]
    ]
    save last-updated-file (now + diff-to-localtime)
  ]
]

pulse-callback: does [ process-blog ]
