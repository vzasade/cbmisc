#!/usr/bin/env escript
%% -*- erlang -*-
%%! -smp enable -sname factorial -mnesia debug verbose

main([]) ->
    Path = "/Users/artem/Work/cert/chain.pem",
    {ok, CAChain} = file:read_file(Path),
    PemEntries = public_key:pem_decode(CAChain),
    [io:fwrite("~p~n", [public_key:pem_entry_decode(P)]) ||
                       P <- PemEntries].
