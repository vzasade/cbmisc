-module(bucket_placer).

-behavior(gen_server).

-export([code_change/3,
         handle_call/3,
         handle_cast/2,
         handle_info/2,
         init/1,
         terminate/2]).

-export([get_nodes/0,
         add_node/1,
         remove_node/1,
         get_buckets/0,
         create_bucket/3,
         delete_bucket/1,
         adjust_bucket/3,
         is_balanced/1,
         rebuild_zone/1]).

-record(state, {weight_limit, zones, nodes, buckets, last_node}).

-record(node, {weight, buckets}).

-record(bucket, {weight, width}).

init(_Args) ->
    WeightLimit = 6,
    NZones = 3,
    NNodes = 3,
    io:format("Initializing bucket placer with weight limit ~p, number of "
              "zones ~p, ~p nodes per zone~n", [WeightLimit, NZones, NNodes]),

    State = #state{
               weight_limit = WeightLimit,
               last_node = 0,
               buckets = maps:new(),
               zones = maps:new(),
               nodes = maps:new()},

    NewState =
        lists:foldl(fun ({NZ, _}, S) ->
                            create_node(zone_name(NZ), S)
                    end, State, [{Z, N} || Z <- lists:seq(1, NZones),
                                           N <- lists:seq(1, NNodes)]),
    {ok, NewState}.

get_nodes() ->
    gen_server:call(?MODULE, get_nodes).

add_node(Zone) ->
    gen_server:call(?MODULE, {add_node, Zone}).

remove_node(Node) ->
    gen_server:call(?MODULE, {remove_node, Node}).

get_buckets() ->
    gen_server:call(?MODULE, get_buckets).

create_bucket(Name, Weight, Width) ->
    gen_server:call(?MODULE, {create_bucket, Name, Weight, Width}).

delete_bucket(Name) ->
    gen_server:call(?MODULE, {delete_bucket, Name}).

adjust_bucket(Name, Weight, Width) ->
    gen_server:call(?MODULE, {adjust_bucket, Name, Weight, Width}).

is_balanced(BucketName) ->
    gen_server:call(?MODULE, {is_balanced, BucketName}).

rebuild_zone(Zone) ->
    gen_server:call(?MODULE, {rebuild_zone, Zone}).

handle_call(get_nodes, _From, State = #state{zones = Zones}) ->
    Reply =
        lists:map(
          fun ({Zone, NodeNames}) ->
                  {Zone, lists:sort(
                           [print_node(NodeName, State)
                            || NodeName <- NodeNames])}
          end, maps:to_list(Zones)),
    {reply, Reply, State};
handle_call(get_buckets, _From, State = #state{buckets = Buckets}) ->
    {reply, [{Name, Width, Weight, get_servers(Name, State)} ||
                {Name, #bucket{weight = Weight, width = Width}}
                    <- maps:to_list(Buckets)], State};
handle_call({add_node, Zone}, _From, State = #state{zones = Zones}) ->
    case maps:is_key(Zone, Zones) of
        true ->
            {reply, ok, create_node(Zone, State)};
        false ->
            {reply, {error, not_found}, State}
    end;
handle_call({create_bucket, Name, Weight, Width}, _From,
            State = #state{buckets = Buckets}) ->
    case maps:is_key(Name, Buckets) of
        true ->
            {reply, already_exist, State};
        false ->
            Bucket = #bucket{weight = Weight, width = Width},
            StateWithBucket =
                State#state{buckets = maps:put(Name, Bucket, Buckets)},
            case ensure_bucket_placement(Name, Weight, 0, Width,
                                         StateWithBucket) of
                {ok, NewState} ->
                    {reply, ok, NewState};
                {error, E} ->
                    {reply, E, State}
            end
    end;
handle_call({delete_bucket, Name}, _From, State = #state{buckets = Buckets,
                                                         nodes = Nodes}) ->
    case maps:take(Name, Buckets) of
        error ->
            {reply, not_found, State};
        {#bucket{weight = Weight}, NewBuckets}  ->
            NewNodes =
                maps:map(
                  fun (_, N) ->
                          maybe_remove_bucket_from_node(Name, Weight, N)
                  end, Nodes),
            {reply, ok, State#state{buckets = NewBuckets, nodes = NewNodes}}
    end;
handle_call({adjust_bucket, Name, Weight, Width}, _From,
            State = #state{buckets = Buckets}) ->
    case maps:get(Name, Buckets, undefined) of
        undefined ->
            {reply, not_found, State};
        B = #bucket{weight = OldWeight} ->
            Bucket = B#bucket{weight = Weight, width = Width},
            StateWithBucket =
                State#state{buckets = maps:put(Name, Bucket, Buckets)},
            case ensure_bucket_placement(Name, Weight, OldWeight, Width,
                                         StateWithBucket) of
                {ok, NewState} ->
                    {reply, ok, NewState};
                {error, E} ->
                    {reply, E, State}
            end
    end;
handle_call({is_balanced, BucketName}, _From,
            State = #state{buckets = Buckets}) ->
    {reply,
     case maps:get(BucketName, Buckets, undefined) of
         undefined ->
             not_found;
         B ->
             is_balanced(BucketName, B, State)
     end, State};
handle_call({remove_node, Name}, _From, State = #state{nodes = Nodes,
                                                       zones = Zones}) ->
    case maps:take(Name, Nodes) of
        error ->
            {reply, not_found, State};
        {_, NewNodes} ->
            NewZones =
                maps:map(fun (_, ZoneNodes) -> ZoneNodes -- [Name] end,
                         Zones),
            {reply, ok, State#state{nodes = NewNodes, zones = NewZones}}
    end;
handle_call({rebuild_zone, Zone}, _From, State = #state{zones = ZonesMap}) ->
    case maps:get(Zone, ZonesMap, undefined) of
        undefined ->
            {reply, not_found, State};
        ZoneNodes ->
            case rebuild_zone(ZoneNodes, State) of
                {error, Error} ->
                    {reply, Error, State};
                NewState ->
                    {reply, ok, NewState}
            end
    end.

handle_cast(_Request, State) ->
    {noreply, State}.

handle_info(_Info, State) ->
    {noreply, State}.

code_change(_OldVsn, _State, _Extra) ->
    {error, oopsie}.

terminate(_Reason, _State) ->
    [].

zone_name(N) ->
    list_to_atom(lists:flatten(io_lib:format("az~p", [N]))).

node_name(N) ->
    list_to_atom(lists:flatten(io_lib:format("n~4.4.0w", [N]))).

create_node(Zone, State = #state{last_node = LastNode,
                                 nodes = Nodes,
                                 zones = Zones}) ->
    N = LastNode + 1,
    NodeName = node_name(N),
    State#state{
      nodes = maps:put(NodeName, #node{weight = 0, buckets = []}, Nodes),
      last_node = N,
      zones = maps:update_with(
                Zone, fun (ZoneNodes) -> [NodeName | ZoneNodes] end,
                [NodeName], Zones)}.

print_node(NodeName, #state{nodes = Nodes,
                            buckets = BucketsMap}) ->
    #node{buckets = Buckets} = maps:get(NodeName, Nodes),
    Spaces = lists:flatmap(
               fun (BucketName) ->
                       #bucket{weight = W} = maps:get(BucketName, BucketsMap),
                       [BucketName || _ <- lists:seq(1, W)]
               end, lists:sort(Buckets)),
    {NodeName, Spaces}.

on_zones(F, State = #state{zones = Zones}) ->
    {Results, NewState} =
        lists:mapfoldl(
          fun ({Zone, Nodes}, S) ->
                  case F(Nodes, S) of
                      error ->
                          {{error, Zone}, S};
                      NewS ->
                          {ok, NewS}
                  end
          end, State, maps:to_list(Zones)),

    case [Z || {error, Z} <- Results] of
        [] ->
            {ok, NewState};
        Bad ->
            {error, Bad}
    end.

allocate_bucket(AllNodes, Name, Weight, Width,
                State = #state{weight_limit = Limit}) ->
    Nodes = lists:sublist(AllNodes, Width),
    case length(Nodes) < Width of
        true ->
            error;
        false ->
            case lists:all(fun ({W, _}) -> Limit - W >= Weight end, Nodes) of
                true ->
                    allocate_bucket_on_nodes(
                      [N || {_, N} <- Nodes], Name, Weight, State);
                false ->
                    error
            end
    end.

allocate_bucket_on_nodes(Nodes, Name, Weight,
                         State = #state{nodes = NodesMap}) ->
    NewNodesMap =
        lists:foldl(
          fun (N, NodesAcc) ->
                  maps:update_with(
                    N, fun (Node = #node{weight = W, buckets = B}) ->
                               Node#node{weight = W + Weight,
                                         buckets = [Name | B]}
                       end, NodesAcc)
          end, NodesMap, Nodes),
    State#state{nodes = NewNodesMap}.

get_servers(Bucket, #state{nodes = NodesMap}) ->
    maps:keys(
      maps:filter(
        fun (_, #node{buckets = Buckets}) ->
                lists:member(Bucket, Buckets)
        end, NodesMap)).

maybe_remove_bucket_from_node(BucketName, Weight,
                              N = #node{weight = W, buckets = B}) ->
    case B -- [BucketName] of
        B ->
            N;
        NewB ->
            N#node{weight = W - Weight, buckets = NewB}
    end.

maybe_remove_bucket_from_node(BucketName, Weight, NodeName, NodesMap) ->
    maps:update_with(
      NodeName,
      fun (N) -> maybe_remove_bucket_from_node(BucketName, Weight, N) end,
      NodesMap).

nodes_for_bucket_placement(Nodes, BucketName, #state{nodes = NodesMap}) ->
    {NodesWithBucket, NodesWithoutBucket} =
        lists:foldl(
          fun (NodeName, {WithAcc, WithoutAcc}) ->
                  #node{buckets = Buckets,
                        weight = Weight} = maps:get(NodeName, NodesMap),
                  NodeTuple = {Weight, NodeName},
                  case lists:member(BucketName, Buckets) of
                      true ->
                          {[NodeTuple | WithAcc], WithoutAcc};
                      false ->
                          {WithAcc, [NodeTuple | WithoutAcc]}
                  end
          end, {[], []}, Nodes),
    {lists:sort(NodesWithBucket), lists:sort(NodesWithoutBucket)}.

adjust_weight(Nodes, Diff, WeightLimit, NodesMap) ->
    lists:foldl(
      fun ({NodeWeight, NodeName}, {NM, NoSpaceNodes}) ->
              case NodeWeight + Diff of
                  NewWeight when NewWeight > WeightLimit ->
                      {NM, [NodeName | NoSpaceNodes]};
                  NewWeight ->
                      {maps:update_with(
                         NodeName,
                         fun (N) -> N#node{weight = NewWeight} end, NM),
                       NoSpaceNodes}
              end
      end, {NodesMap, []}, Nodes).

remove_bucket_from_nodes(BucketName, Weight, Nodes, NodesMap) ->
    lists:foldl(
      fun (NodeName, NM) ->
              maybe_remove_bucket_from_node(
                BucketName, Weight, NodeName, NM)
      end, NodesMap, Nodes).

ensure_bucket_placement(BucketName, Weight, OldWeight, Width, State) ->
    RV = on_zones(
           fun (Nodes, S) ->
                   ensure_bucket_placement(Nodes, BucketName, Weight, OldWeight,
                                           Width, S)
           end, State),
    case RV of
        {error, Bad} ->
            {error, {need_more_space, Bad}};
        Other ->
            Other
    end.

ensure_bucket_placement(Nodes, BucketName, Weight, OldWeight, Width,
                        State = #state{nodes = NodesMap,
                                       weight_limit = WeightLimit}) ->
    {NodesWithBucket, NodesWithoutBucket} =
        nodes_for_bucket_placement(Nodes, BucketName, State),

    {ToAdjustWeight, ToRemoveBucket1} =
        lists:split(min(length(NodesWithBucket), Width), NodesWithBucket),

    {NodesMap1, ToRemoveBucket2} =
        adjust_weight(ToAdjustWeight, Weight - OldWeight, WeightLimit,
                      NodesMap),

    NodesMap2 =
        remove_bucket_from_nodes(
          BucketName, OldWeight, [N || {_, N} <- ToRemoveBucket1] ++
              ToRemoveBucket2, NodesMap1),

    NewState = State#state{nodes = NodesMap2},

    case Width - length(ToAdjustWeight) of
        0 ->
            NewState;
        MoreWidth ->
            allocate_bucket(NodesWithoutBucket, BucketName, Weight, MoreWidth,
                            NewState)
    end.

is_balanced(BucketName, #bucket{width = Width}, State) ->
    RV = on_zones(
           fun (Nodes, S = #state{nodes = NodesMap}) ->
                   BucketNodes =
                       lists:filter(
                         fun (NodeName) ->
                                 #node{buckets = Buckets} =
                                     maps:get(NodeName, NodesMap),
                                 lists:member(BucketName, Buckets)
                         end, Nodes),
                   case length(BucketNodes) =:= Width of
                       true ->
                           S;
                       false ->
                           error
                   end
           end, State),
    case RV of
        {error, Bad} ->
            {error, {needs_rebalance, Bad}};
        _ ->
            ok
    end.

place_buckets_back([], _, State) ->
    State;
place_buckets_back(
  [{BucketName, #bucket{weight = Weight, width = Width}} | Rest],
  ZoneNodes, State) ->
    case ensure_bucket_placement(ZoneNodes, BucketName, Weight, 0, Width,
                                 State) of
        error ->
            {error, need_more_space};
        NewState ->
            place_buckets_back(Rest, ZoneNodes, NewState)
    end.

rebuild_zone(ZoneNodes, State = #state{buckets = BucketsMap,
                                       nodes = NodesMap}) ->
    CleanedNodesMap =
        maps:map(
          fun (NodeName, N) ->
                  case lists:member(NodeName, ZoneNodes) of
                      true ->
                          N#node{weight = 0, buckets = []};
                      false ->
                          N
                  end
          end, NodesMap),
    SortedBuckets =
        lists:sort(fun ({_, #bucket{weight = W1}}, {_, #bucket{weight = W2}}) ->
                           W1 >= W2
                   end, maps:to_list(BucketsMap)),
    place_buckets_back(SortedBuckets, ZoneNodes,
                       State#state{nodes = CleanedNodesMap}).
