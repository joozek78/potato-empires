# Potato Empires #

Potato Empires is an turn-based strategy game.

## Installation ##

### The Client ###
The client is served by the server

### The Server ###
* Get the latest Haskell Platform (2014.02 at the time of writing)
* Navigate to the `potato-server` directory and run:
    * (optionally) `cabal sandbox init`
    * `cabal install --dependencies-only`
    * `cabal configure`
    * `cabal run`

Configuration:
* You can set the port to listen on by setting env var 'PORT' (default is 3000)
* You can set the directory that will be served by setting env var 'POTATO_CLIENT_DIR' (default is '../potato-client')

Sorry for the inconvenience caused, but `cabal install` doesn't work right now for whatever reason.

## Running tests ##
* `cabal install --dependencies-only --enable-tests`
* `cabal test`
 
## Deploying to Heroku ##
* set following config vars:
   * BUILDPACK_URL=https://github.com/begriffs/heroku-buildpack-ghc
   * PRE_SCRIPT=heroku-pre.sh
