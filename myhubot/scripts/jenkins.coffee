# Description:
#   Interact with your Jenkins CI server
#
# Dependencies:
#   None
#
# Configuration:
#   HUBOT_JENKINS_URL
#   HUBOT_JENKINS_AUTH
#
#   Auth should be in the "user:password" format.
#
# Commands:
#   hubot jenkins b <jobNumber> - builds the job specified by jobNumber. List jobs to get number.
#   hubot jenkins build <job> - builds the specified Jenkins job
#   hubot jenkins build <job>, <params> - builds the specified Jenkins job with parameters as key=value&key2=value2
#   hubot jenkins list <filter> - lists Jenkins jobs
#   hubot jenkins describe <job> - Describes the specified Jenkins job
#   hubot jenkins last <job> - Details about the last build for the specified Jenkins job
#   hubot jenkins changes list <job> - display commits in specified Jenkins jobs
#   hubot jenkins commiters list <job> - display commiters in specified Jenkins jobs

#
# Author:
#   dougcole

querystring = require 'querystring'

# Holds a list of jobs, so we can trigger them with a number
# instead of the job's name. Gets populated on when calling
# list.
jobList = []

jenkinsBuildById = (msg) ->
  # Switch the index with the job name
  job = jobList[parseInt(msg.match[1]) - 1]

  if job
    msg.match[1] = job
    jenkinsBuild(msg)
  else
    msg.reply "I couldn't find that job. Try `jenkins list` to get a list."

jenkinsBuild = (msg, buildWithEmptyParameters) ->
    url = process.env.HUBOT_JENKINS_URL
    job = querystring.escape msg.match[1]
    params = msg.match[3]
    command = if buildWithEmptyParameters then "buildWithParameters" else "build"
    path = if params then "#{url}/job/#{job}/buildWithParameters?#{params}" else "#{url}/job/#{job}/#{command}"

    req = msg.http(path)

    if process.env.HUBOT_JENKINS_AUTH
      auth = new Buffer(process.env.HUBOT_JENKINS_AUTH).toString('base64')
      req.headers Authorization: "Basic #{auth}"

    req.header('Content-Length', 0)
    req.post() (err, res, body) ->
        if err
          msg.reply "Jenkins says: #{err}"
        else if 200 <= res.statusCode < 400 # Or, not an error code.
          msg.reply "(#{res.statusCode}) Build started for #{job} #{url}/job/#{job}"
        else if 400 == res.statusCode
          jenkinsBuild(msg, true)
        else if 404 == res.statusCode
          msg.reply "Build not found, double check that it exists and is spelt correctly."
        else if 403 == res.statusCode
          msg.reply "user is not authorized."
        else
          msg.reply "Jenkins says: Status #{res.statusCode} #{body}"

jenkinsDescribe = (msg) ->
    url = process.env.HUBOT_JENKINS_URL
    job = msg.match[1]

    path = "#{url}/job/#{job}/api/json"

    req = msg.http(path)

    if process.env.HUBOT_JENKINS_AUTH
      auth = new Buffer(process.env.HUBOT_JENKINS_AUTH).toString('base64')
      req.headers Authorization: "Basic #{auth}"

    req.header('Content-Length', 0)
    req.get() (err, res, body) ->
        if err
          msg.send "Jenkins says: #{err}"
        else
          response = ""
          try
            content = JSON.parse(body)
            response += "JOB: #{content.displayName}\n"
            response += "URL: #{content.url}\n"

            if content.description
              response += "DESCRIPTION: #{content.description}\n"

            response += "ENABLED: #{content.buildable}\n"
            response += "STATUS: #{content.color}\n"

            tmpReport = ""
            if content.healthReport.length > 0
              for report in content.healthReport
                tmpReport += "\n  #{report.description}"
            else
              tmpReport = " unknown"
            response += "HEALTH: #{tmpReport}\n"

            parameters = ""
            for item in content.actions
              if item.parameterDefinitions
                for param in item.parameterDefinitions
                  tmpDescription = if param.description then " - #{param.description} " else ""
                  tmpDefault = if param.defaultParameterValue then " (default=#{param.defaultParameterValue.value})" else ""
                  parameters += "\n  #{param.name}#{tmpDescription}#{tmpDefault}"

            if parameters != ""
              response += "PARAMETERS: #{parameters}\n"

            msg.send response

            if not content.lastBuild
              return

            path = "#{url}/job/#{job}/#{content.lastBuild.number}/api/json"
            req = msg.http(path)
            if process.env.HUBOT_JENKINS_AUTH
              auth = new Buffer(process.env.HUBOT_JENKINS_AUTH).toString('base64')
              req.headers Authorization: "Basic #{auth}"

            req.header('Content-Length', 0)
            req.get() (err, res, body) ->
                if err
                  msg.send "Jenkins says: #{err}"
                else
                  response = ""
                  try
                    content = JSON.parse(body)
                    console.log(JSON.stringify(content, null, 4))
                    jobstatus = content.result || 'PENDING'
                    jobdate = new Date(content.timestamp);
                    response += "LAST JOB: #{jobstatus}, #{jobdate}\n"

                    msg.send response
                  catch error
                    msg.send error

          catch error
            msg.send error

jenkinsLast = (msg) ->
    url = process.env.HUBOT_JENKINS_URL
    job = msg.match[1]

    path = "#{url}/job/#{job}/lastBuild/api/json"

    req = msg.http(path)

    if process.env.HUBOT_JENKINS_AUTH
      auth = new Buffer(process.env.HUBOT_JENKINS_AUTH).toString('base64')
      req.headers Authorization: "Basic #{auth}"

    req.header('Content-Length', 0)
    req.get() (err, res, body) ->
        if err
          msg.send "Jenkins says: #{err}"
        else
          response = ""
          try
            content = JSON.parse(body)
            response += "NAME: #{content.fullDisplayName}\n"
            response += "URL: #{content.url}\n"

            if content.description
              response += "DESCRIPTION: #{content.description}\n"

            response += "BUILDING: #{content.building}\n"

            msg.send response

getMsg = (channel,job) ->
  message:
    room: "#{channel}"
  content:
    fallback: job.name + " "+job.color
    author_name: 'Jenkins'
    author_icon: "https://a.slack-edge.com/205a/img/services/jenkins-ci_36.png"
    color: if job.color == "red"
      '#FF0000'
    else if job.color == "aborted"
      '#CCCCCC'
    else if job.color == "aborted_anime"
      '#FFCC00'
    else if job.color == "red_anime"
      '#FFCC00'
    else if job.color == "blue_anime"
      '#FFCC00'
    else '#00FF00'
    title: job.name
    title_link: job.url
    fields: [
      title: if job.color == "red"
        "Fail"
      else if job.color == "aborted"
        "Aborted"
      else if job.color == "aborted_anime"
        "Currently running"
      else if job.color == "red_anime"
        "Currently running"
      else if job.color == "blue_anime"
        "Currently running"
      else "Pass"
    ]


jenkinsList = (msg) ->
    url = process.env.HUBOT_JENKINS_URL
    filter = new RegExp(msg.match[2], 'i')
    req = msg.http("#{url}/api/json")

    if process.env.HUBOT_JENKINS_AUTH
      auth = new Buffer(process.env.HUBOT_JENKINS_AUTH).toString('base64')
      req.headers Authorization: "Basic #{auth}"

    req.get() (err, res, body) ->
        response = ""
        if err
          msg.send "Jenkins says: #{err}"
        else
          try
            content = JSON.parse(body)
            for job in content.jobs
              #msg.robot.logger.info "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!  room :    #{msg.envelope.room}         !!!!!!!!!!!!!!!!!!!!!!!!!"

             # Add the job to the jobList
              index = jobList.indexOf(job.name)
              if index == -1
                jobList.push(job.name)
                index = jobList.indexOf(job.name)

              state = if job.color == "red"
                        "FAIL"
                      else if job.color == "aborted"
                        "ABORTED"
                      else if job.color == "aborted_anime"
                        "CURRENTLY RUNNING"
                      else if job.color == "red_anime"
                        "CURRENTLY RUNNING"
                      else if job.color == "blue_anime"
                        "CURRENTLY RUNNING"
                      else "PASS"

              if (filter.test job.name) or (filter.test state)
                msg.robot.adapter.customMessage getMsg(msg.envelope.room,job)
                #response += "[#{index + 1}] #{state} #{job.name}\n"
            msg.send response
          catch error
            msg.send error

getChange = (channel,file,author,date) ->
  message:
    room: "#{channel}"
  content:
    fallback: 'change row'
    author_name: author
    fields: [
      title: date
      value: file
    ]

jenkinsChangesList = (msg) ->
  url = process.env.HUBOT_JENKINS_URL
  jobName = msg.match[2]
# buildNumber = msg.robot.brain.get(jobName+'buildNumber')
#  if (jobName)
#    buildNumber = msg.robot.brain.get(jobName+'buildNumber')
#  else

#  msg.robot.logger.info '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!--->'+a+' ; '+b+' ; '+c+' ; '+d+' ; '+e+' ; '+'<----!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'

#  msg.robot.logger.info '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!--->'+jobName+'<----!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'

  if(!jobName)
    jobName = "MQM-Root-quick-master"
  buildNumber = msg.robot.brain.get(jobName+'buildNumber')-1
  path = "#{url}/job/#{jobName}/#{buildNumber}/api/json"
  msg.robot.logger.info '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!--->'+path+'<----!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'

  response = ""
#  msg.robot.logger.info '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
#  msg.robot.logger.info msg.robot.brain.get(jobName+'buildNumber')
#  msg.robot.logger.info path
#  msg.robot.logger.info '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
  req = msg.http(path)
  req.get() (err, res, body) ->
    if err
      msg.send {room: channel} , "Jenkins says: #{err}"
    else
      try
        content = JSON.parse(body)
        msg.send 'build '+jobName+' '+content.displayName
        for item in content.changeSet.items
          response = ""
          for filea in item.paths
#            msg.robot.logger.info '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
#            msg.robot.logger.info item
#            msg.robot.logger.info filea
#            msg.robot.logger.info '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
            response += "#{filea.file}\n"
#            msg.robot.logger.info '!-------!!!!!!!!!!!!-----------!!!!!!!!!!!!!!----------!!!!!!!!!!!!!!!!!!!!!!!!'+response
          msg.robot.adapter.customMessage getChange(msg.envelope.room,response,item.author.fullName,item.date)
#          msg.send response
      catch error
        msg.send {room: channel} , "Jenkins says: #{error}"

jenkinsCommitersList = (msg) ->
  commitersList = []
  url = process.env.HUBOT_JENKINS_URL
  jobName = msg.match[2]
  # buildNumber = msg.robot.brain.get(jobName+'buildNumber')
  #  if (jobName)
  #    buildNumber = msg.robot.brain.get(jobName+'buildNumber')
  #  else


  msg.robot.logger.info '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!--->'+jobName+'<----!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'

  if(!jobName)
    jobName = "MQM-Root-quick-master"
  buildNumber = msg.robot.brain.get(jobName+'buildNumber')-1
  path = "#{url}/job/#{jobName}/#{buildNumber}/api/json"
  msg.robot.logger.info '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!--->'+path+'<----!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'

  response = ""
  req = msg.http(path)
  req.get() (err, res, body) ->
    if err
      msg.send {room: msg.envelope.room} , "Jenkins says: #{err}"
    else
      try
        content = JSON.parse(body)
        msg.send 'build '+jobName+' '+content.displayName
        for item in content.changeSet.items
          index = commitersList.indexOf(item.author.fullName)
          if index == -1
            commitersList.push(item.author.fullName)
            index = commitersList.indexOf(item.author.fullName)
            response += "#{item.author.fullName}\n"
        msg.send response
#        msg.robot.adapter.customMessage jenkinsMsg(msg.envelope.room,'build '+jobName+' '+content.displayName,response)
      catch error
        msg.send {room: msg.envelope.room} , "Jenkins says: #{error}"


module.exports = (robot) ->
  robot.brain.set 'buildNumber', 0
  robot.respond /j(?:enkins)? build ([\w\.\-_ ]+)(, (.+))?/i, (msg) ->
    jenkinsBuild(msg, false)

  robot.respond /j(?:enkins)? b (\d+)/i, (msg) ->
    jenkinsBuildById(msg)

  robot.respond /j(?:enkins)? list( (.+))?/i, (msg) ->
    jenkinsList(msg)

  robot.respond /j(?:enkins)? describe (.*)/i, (msg) ->
    jenkinsDescribe(msg)

  robot.respond /j(?:enkins)? last (.*)/i, (msg) ->
    jenkinsLast(msg)

  robot.respond /j(?:enkins)? changes list( (.+))?/i, (msg) ->
    jenkinsChangesList(msg)

  robot.respond /j(?:enkins)? commiters list( (.+))?/i, (msg) ->
    jenkinsCommitersList(msg)

  robot.jenkins = {
    list: jenkinsList,
    build: jenkinsBuild,
    describe: jenkinsDescribe,
    last: jenkinsLast,
    changesList:jenkinsChangesList,
    commitersList:jenkinsCommitersList
  }




  getMsg2 = (channel,job) ->
    message:
      room: "#{channel}"
    content:
      fallback: job.fullDisplayName
      color: if job.result == "FAILURE"
        '#FF0000'
      else if job.result == "ABORTED"
        '#CCCCCC'
      else if job.result == "UNSTABLE"
        '#FFCC00'
      else if job.result == "SUCCESS"
        '#00FF00'
      else '#FFCC00'
      author_icon: "https://a.slack-edge.com/205a/img/services/jenkins-ci_72.png"
      author_name: "Jenkins"
      title: job.fullDisplayName
      title_link: job.url
      fields: [
        title: job.result
      ]


  callback = (channel,jobName) ->
    url = process.env.HUBOT_JENKINS_URL
    path = "#{url}/job/#{jobName}/lastBuild/api/json"
    req = robot.http(path)
    #robot.send {room: 'general'} , path

    req.get() (err, res, body) ->
      if err
        robot.send {room: channel} , "Jenkins says: #{err}"
      else
        try
          content = JSON.parse(body)
#          robot.logger.info content.number
#          robot.logger.info '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
#          robot.logger.info content.
#          robot.logger.info '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
          if robot.brain.get(jobName+'buildNumber')!= content.number
            buildNumber = content.number-1
            path = "#{url}/job/#{jobName}/#{buildNumber}/api/json"
            robot.brain.set jobName+'buildNumber' , content.number
            req2 = robot.http(path)
            req2.get() (err, res, body) ->
              if err
                robot.send {room: channel} , "Jenkins says: #{err}"
              else
                try
                  content = JSON.parse(body)
                  robot.logger.info '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                  robot.logger.info content
                  robot.logger.info '!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
                  robot.adapter.customMessage getMsg2(channel,content)
                catch error
                  robot.send {room: channel} , "Jenkins says: #{error}"
        catch error
          robot.send {room: channel} , "Jenkins says: #{error}"

  setInterval callback('general','MQM-Root-full-master'), 10000
  setInterval callback('general','MQM-Root-quick-master'), 10000


