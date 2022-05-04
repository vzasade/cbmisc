-module(bplacer).
-behavior(application).
-export([start/2, stop/1]).

start(_Type, Args) ->
    supervisor:start_link({local, bplacer_sup}, bplacer_sup, Args).

stop(_State) ->
    [].
