request = require 'request'
module.exports = (robot) ->

#  robot.on 'message', (msg) ->
#    robot.adapter.customMessage payload

  robot.hear /do unfreeze (.*)/i, (msg) ->
    robot.brain.set 'freezeStatus', 'UnFreeze'
    robot.brain.set 'freezeColor', '#00ff00'
    robot.brain.set 'reason', msg.match[1]

    robot.adapter.customMessage getMsg(msg.envelope.room)

  robot.hear /do freeze (.*)/i, (msg) ->

    robot.brain.set 'freezeStatus', 'Freeze'
    robot.brain.set 'freezeColor', '#ff0000'
    robot.brain.set 'reason', msg.match[1]

    channel = msg.envelope.room

    username = msg.message.user.name
    user_id = msg.message.user.id


    #robot.emit "slack-attachment", payload

    robot.adapter.customMessage getMsg(msg.envelope.room)
    robot.logger.info 'Freezing'


  robot.hear /freeze status/i, (msg) ->
    msg.reply 'We are in *' + robot.brain.get('freezeStatus') + '* '+':loudspeaker:'


  getMsg = (channel) ->
    message:
      room: "#{channel}"
    content:
      fallback: 'we are in ' + robot.brain.get('freezeStatus')
      color: robot.brain.get('freezeColor')
      title: robot.brain.get('freezeStatus')
      title_link: "http://mydtbld0101.hpeswlab.net:8888/jenkins/view/%20%20MQM-master/view/01-CI/job/MQM-Root-quick-master/"
      fields: [
        title: "Reason"
        value: robot.brain.get('reason')
        short: false
      ]



  callback = ->
    robot.adapter.customMessage getMsg('general')

  setInterval callback, 300000




