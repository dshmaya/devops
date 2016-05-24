# Description:
#   Homer Simpson quotes.
#
# Dependencies:
#   None
#
# Configuration:
#   None
#
# Commands:
#   beer - replies with random beer quote
#   <food> - replies with "Mmmm... <food>"
#   internet - replies with random internet quote
#   try - replies with random try quote
#
# Author:
#   bhankus

beerQuotes = [
  "Beer... Now there's a temporary solutionddd."  
]

tryQuotes = [
  "Kids, you tried your best and you failed miserably. The lesson is, never try.",
  "Trying is the first step towards failure."
]

internetQuotes = [
  "Oh, so they have internet on computers now!",
  "The Internet? Is that thing still around?"
]

module.exports = (robot) ->
  robot.hear /beer/i, (msg) ->
    msg.send msg.random beerQuotes
  robot.hear /bacon|bagel|barbecue|burger|candy|chocolate|donut|sandwich|breakfast|lunch|dinner|food|grub/i, (msg) ->
    msg.send "Mmmm... " + msg.match[0]
  robot.hear /try/i, (msg) ->
    msg.send msg.random tryQuotes
  robot.hear /internet/i, (msg) ->  
    msg.send msg.random internetQuotes