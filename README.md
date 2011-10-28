## Laink

Laink is a standalone game server designed to let game AIs written in any language to compete against each other. Communication takes place as length-prefixed JSON over TCP Sockets.

Laink also provides a reference implementation for generic player AIs and game engine implementation.

## TODO

1. Separate game engines out of the server process, instead communicating over sockets.
  * Allows game engines to be written in any language, too.
  * _TBD: Should the server be a broker for messages, or just connect clients directly to the game engine after it's booted up? The former is more overhead, but allows the server to track all interactions and generate stats._
   
1. Allow clients to request a game with a number of players less than the minimum
1. Asynchronous queue for 'high priority' player requests before their turn _(e.g. "What's the score?", "I Quit!", "Tell Harold he's going down!" )_
