![The all-seeing eye of the RebolBot! Well, maybe it's just a Rebol block.][1]

##Screenshot / Code Snippet

    @Rebolbot help
    @GrahamChiu I respond to these commands:
    delete [ silent ] "in reply to a bot message will delete if in time"
    do expression "evaluates Rebol expression in a sandboxed interpreter (/x)"
    help "this help (/? and /h)"
    keys "returns known keys (/k)"
    remove key "removes key (authorized user) (/rm)"
    save my details url! "saves your details with url"
    save key [string! word!] description [string!] link [url!] "save key with description and link (/s)"
    show [all ][ recent ] links by user "shows links posted in messages by user"
    show links [ like url ] "shows saved links"
    show me your youtube videos "shows saved youtube videos"
    who is user "returns user details and page"
    whom do you know "returns a list of all known users"
    ? key [ for user | @user ] "Returns link and description"
    version "version of bot (/v)"


##About

RebolBot is a chat bot written in Rebol. It specifically targets the StackOverflow chat rooms, but could be modified with only a little effort to work with any chat system that provides an API for accessing and posting messages or with those providing nothing more than a web form (of course its functionality would depend on how much of the chat activity is accessible either through the API or by scraping). You might think that this is what you could do in any language, but wait until you've seen Rebol - it makes text (and binary) parsing and data munging child's play. 

A running instance of the bot hangs out in the [Rebol and RED][2] room where it answers questions, executes Rebol code in a sandboxed environment for teaching purposes, and does all sorts of other useful things.  It has a natural English language dialected interface, and aims to be on call 24/7.  It runs under its own account.  Help is available in the [Rebol and RED][2] room.

The bot runs as a console process and can interact with a chat systems in various ways with ease. As implemented it is using the REST API that is visible, but not documented, when you use *chat.stackoverflow.com*.

If you'd like to use this bot to evaluate code in an arbitrary programming language, you should have access to a remote service that can accept a string to be evaluated. To see what the RebolBot does with the HTML that is returned from the remote service it is currently using, take a look at the `evaluate-expression` function. In fact the remote service doesn't have to be a service in a formal sense - any of the many REPLs out there could serve as an evaluation target since Rebol makes it very easy to post to and parse results from any site. Make sure you have the OK of the site owner though, before you go and send more traffic his way than s/he's expecting.


Keep in mind that this bot is very young (only about a week now) so you can still expect some rough edges to show themselves here and there. Again, you are welcome to drop by the Rebol chat room and discuss the script in general, or have us try to help with customizing it for your needs. 

[Rebol][5] (and [Red][6]) - keepin' it simple!

###Installation
- Clone this repo and get yourself a Rebol binary (just one file) for your platform of choice. 
- Put the executable in the same directory as rebolbot.r3 and make sure it can run as an application (`chmod +x`) on Linux. 
- Rename bot-config-sample.r to bot-config.r. Edit this file to specify the chat room to be monitored as well as the fkey and cookies needed for the bot to appeared as the desired StackOverflow user.
- Decide which commands you wish to run and move the rest out of the commands directory. This can be done before the bot is run or at runtime, with the bot still running. The bot monitors this directory and will reconfigure itself based on what commands are found there.
- invoke the rebolbot.r3 script with the Rebol binary you downloaded. To do this, drag-and-drop the script on the executable if there's a GUI or follow the steps at [http://rebol.com](http://www.rebol.com/r3/docs/guide/basics-run.html) showing how to run from the command-line (CLI). 

- More detailed screencasts and instructions are coming soon. These will show how to set up the bot as well as how to create commands.

###License

[Apache License, Version 2.0][3]

[Rebol Binaries][4] - So tiny! Yes, that's all you'll need. No install.

###Platform

The script can be run on any platform supported by Rebol (Linux, OS X, Windows, Android)   

##Contact

[Graham Chiu on SO chat][7]

[Adrian Sampaleanu on SO chat][8]

##Code

RebolBot is currently under 400 lines of Rebol for the main bot (not including command modules which can be included or not, as desired). Commands vary from a couple of lines to around 130 for the most complex. If you want to hack on code, feel free to fork the repo and submit pull requests for changes you feel are generally useful, new commands, as well as for bug fixes.

##The Goal

[Rebol][5] and [Red][6] are fighting software complexity...

Software systems have become too complex, layers upon layers of complexity, each more brittle and vulnerable to failure. In the end software becomes the problem, not the solution. We rebel against such complexity, fighting back with the most powerful tool available: language itself.


  [1]: http://i.stack.imgur.com/ygAOt.jpg
  [2]: http://chat.stackoverflow.com/rooms/291/rebol-and-red
  [3]: http://www.apache.org/licenses/LICENSE-2.0.html
  [4]: http://www.rebolsource.net
  [5]: http://www.rebol.com
  [6]: http://www.red-lang.org
  [7]: http://chat.stackoverflow.com/users/76852/graham-chiu
  [8]: http://chat.stackoverflow.com/users/1792095/adrian
