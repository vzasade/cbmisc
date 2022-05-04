-module(bplacer_sup).
-behavior(supervisor).
-export([init/1]).

init(_Args) ->
    SupFlags = #{},
    Args = [{local, bucket_placer}, bucket_placer, [], []],
    ChildSpecs = [
        #{id => bucket_placer, start => {gen_server, start_link, Args}}
    ],
    {ok, {SupFlags, ChildSpecs}}.
