creaku
======

Heroku app creator.

# Installation
Run `npm install -g creaku`.

# Usage
```
> creaku <my\_conf.cfg> --key <MY\_HEROKU\_API\_KEY>
```
or
```
> export HEROKU_API_KEY=<MY\_HEROKU\_API\_KEY>
> creaku <my\_conf.cfg>
```

### Configuration file
...is in YAML format. Example:
```YAML
# Base name of the Heroku app. Will create an app for each combination of `${name}-#{envs}`.
name: creaku-test
# env vars to set for the app.
envVars:
  foo: 42
  bar: "oh yeah"
# App environments (appended to `name` when creating the app).
envs:
 - foo
 - bar
```
