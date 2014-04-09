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

deep = (obj, path, val) ->
  parts = path.split('.')
  tmp = _.reduce _.initial(parts), ((memo, part) -> memo[part]), obj
  if not val?
    return tmp[_.last(parts)]
  else
    tmp[_.last(parts)] = val

listPaths = (obj) ->

  _listPaths = (obj, paths, currentPath) ->
    if not _.isObject(obj)
      paths.push currentPath
      return

    for key, val of obj
      path = null
      if not currentPath
        path = key
      else
        path = "#{currentPath}.#{key}"
      _listPaths val, paths, path

  paths = []
  _listPaths obj, paths
  return paths

preprocessCfg = (cfg) ->
  firstSubRegExp = /(.*?){{(.+?)}}(.*)/
  paths = listPaths(cfg)

  for path in paths
    val = deep(cfg, path)
    count = 0
    while val.match(/.*{{.+}}.*/) and count++ < 10
      pointsTo = val.replace firstSubRegExp, '$2'
      console.log 'pt', pointsTo
      val = val.replace(firstSubRegExp, "$1#{deep(cfg, pointsTo)}$3")
      deep(cfg, path, val)

    if count == 10
      console.log('Circular substitution detected, aborting...')
      process.exit(1)

  return cfg

defer.promise.then ->
  heroku = new Heroku token: (argv.key or process.env.HEROKU_API_KEY)

  createApp = (cfg, env) ->
    cfg = _.extend {}, cfg, env: env
    cfg = preprocessCfg cfg
    if not cfg?
      console.log("Could not process config (circular substitution)")
      process.exit(1)
    name = "#{cfg.name}-#{cfg.env}"

    heroku.apps().create({
      name: name
      region: cfg.region or 'us'
      stack: cfg.stack or 'cedar'
    })
    .then ->
      console.log "App #{name} created"
    , ->
      console.log "Failed to create app #{name}, skipping. " +
        "App probably already exists."
    .then ->
      console.log "Setting env vars for #{name}..."
      heroku.apps(name).configVars().update(cfg.envVars)
    .then ->
      Q.all _.map config.collaborators, (email) ->
        console.log "Adding #{email} to #{name}..."
        heroku.apps(name).collaborators().create({user: email})
      .fail ->
        console.log "Adding collaborator to #{name} failed. Skipping"
    .then ->
      if cfg.domain
        console.log "setting domain for #{name}: #{cfg.domain}"
        heroku.apps(name).domains().create(hostname: cfg.domain)
    .then ->
      console.log "App #{name} done."

  for env in config.envs
    createApp(config, env).done()

.done()
