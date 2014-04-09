creaku
======

![creaku](http://uploadingit.com/file/yll6yonmcmgg4cca/creaku)

Heroku app creator. Useful when you want to create an app and clone it to create multiple environments.

# Installation
Run `npm install -g creaku`.

# Usage
```
> creaku <my_conf.cfg> --key <MY_HEROKU_API_KEY>
```
or
```
> export HEROKU_API_KEY=<MY_HEROKU_API_KEY>
> creaku <my_conf.cfg>
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
# Add collaborators.
collaborators:
 - john.doe@sev.en
 - david.mills@sev.en
```
