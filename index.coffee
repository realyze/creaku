Heroku = require 'heroku-client'
{safeLoad} = require 'js-yaml'
{readFileSync} = require 'fs'
Q = require 'q'
keypress = require 'keypress'
_ = require 'underscore'

argv = require('minimist')(process.argv.slice(2))

if argv._.length == 0
  console.log "Please specify the YAML config file to read."
  process.exit 1

if not argv.key and not process.env.HEROKU_API_KEY
  console.log "Please specify your Heroku API key."
  process.exit 1

config = safeLoad readFileSync argv._[0], 'utf8'

console.log "This will create #{config.envs.length} heroku apps " +
  "with the following configuration: "
console.log JSON.stringify config, null, 2

defer = Q.defer()
console.log "Press enter to continue or 'q' to quit"
keypress(process.stdin)
process.stdin.setRawMode true
process.stdin.on 'keypress', (letter, key) ->
  if key and key.name == 'q'
    process.exit 0
  if key and key.name == 'enter' or key.name == 'return'
    process.stdin.pause()
    console.log "Creating Heroku apps..."
    defer.resolve()

defer.promise.then ->
  heroku = new Heroku token: (argv.key or process.env.HEROKU_API_KEY)

  createApp = (cfg, env) ->
    name = "#{cfg.name}-#{env}"
    heroku.apps().create({
      name: name
      region: cfg.region or 'us'
      stack: cfg.stack or 'cedar'
    })
    .then ->
      console.log "App #{name}-#{env} created"
    , ->
      console.log "Failed to create app #{name}, skipping. App probably already exists."
    .then ->
      console.log "Setting env vars for #{name}..."
      heroku.apps(name).configVars().update(cfg.envVars)
    .then ->
      Q.all _.map config.collaborators, (email) ->
        console.log "Adding #{email} to #{name}..."
        heroku.apps(name).collaborators().create({user: email})
    .then ->
      console.log "App #{name} done."

  for env in config.envs
    createApp(config, env).done()
