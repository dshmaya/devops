# hubot-admin

A hubot script for ChatOps Administration integration

## Installation

In hubot project repo, run:

`npm install hubot-admin --save`

Then add **hubot-admin** to your `external-scripts.json`:

```json
[
  "hubot-admin"
]
```

## configuration
Run with environment variable `SLACK_APP_TOKEN` to enable slack Web API integration

## Commands support

Supported commands:

1. archive old: archiving all channels older than specified time
  * `admin archive older 3<h/m/s>`
2. archive specific: archiving specific channel
  * `admin archive channel #channelName`
