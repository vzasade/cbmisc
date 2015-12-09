#!/usr/bin/env escript
%% -*- erlang -*-
%%! -smp enable -sname factorial -mnesia debug verbose

-include_lib("public_key/include/public_key.hrl").

print_chain(Chain) ->
    [print_entry(DerCert) || {'Certificate', DerCert, not_encrypted} <- Chain].

print_entry(DerCert) ->
    Decoded = public_key:pkix_decode_cert(DerCert, otp),
    %%io:fwrite("~p~n", [Decoded]),
    TBSCert = Decoded#'OTPCertificate'.tbsCertificate,
    %%Data = pubkey_cert:verify_data(Cert),
    %%io:fwrite("~p~n", [Data]).
    Subject = format_name(TBSCert#'OTPTBSCertificate'.subject),
    Issuer = format_name(TBSCert#'OTPTBSCertificate'.issuer),

    Validity = TBSCert#'OTPTBSCertificate'.validity,
    NotBefore = convert_date(Validity#'Validity'.notBefore),
    NotAfter = convert_date(Validity#'Validity'.notAfter),
    io:fwrite("Subject: ~p~nIssuer: ~p~nValidity: ~p~n********~n",
              [Subject, Issuer, {NotBefore, NotAfter}]).

%%{'Validity',{utcTime,"151005003156Z"},{utcTime,"201004003156Z"}},

%%print_name(TBSCert#'OTPTBSCertificate'.subject).

convert_date(Year, [M1, M2, D1, D2, H1, H2, MM1, MM2, S1, S2, $Z]) ->
    Month = list_to_integer([M1, M2]),
    Day = list_to_integer([D1, D2]),
    Hour = list_to_integer([H1, H2]),
    Min = list_to_integer([MM1, MM2]),
    Sec=list_to_integer([S1, S2]),
    {{Year, Month, Day}, {Hour, Min, Sec}}.

convert_date({utcTime, [Y1, Y2 | Rest]}) ->
    Year = list_to_integer([Y1, Y2]) + 2000,
    convert_date(Year, Rest);
convert_date({generalTime, [Y1, Y2, Y3, Y4 | Rest]}) ->
    Year = list_to_integer([Y1, Y2, Y3, Y4]),
    convert_date(Year, Rest).

format_attribute([#'AttributeTypeAndValue'{type = Type,
                                           value = Value}], Acc) ->
    case attribute_string(Type) of
        undefined ->
            Acc;
        Str ->
            [lists:flatten([Str, "=", format_value(Value)]) | Acc]
    end.

format_name(Name) ->
    %%Normalized = public_key:pkix_normalize_name(Name),
    {rdnSequence, STVList} = Name,
    Attributes = lists:foldl(fun (V, Acc) ->
                                     format_attribute(V, Acc)
                             end, [], STVList),
    lists:flatten(string:join(lists:reverse(Attributes), ", ")).

attribute_string(?'id-at-countryName') ->
    "C";
attribute_string(?'id-at-stateOrProvinceName') ->
    "ST";
attribute_string(?'id-at-localityName') ->
    "L";
attribute_string(?'id-at-organizationName') ->
    "O";
attribute_string(?'id-at-commonName') ->
    "CN";
attribute_string(_) ->
    undefined.

format_value({printableString, Value}) when is_list(Value) ->
    Value;
format_value(Value) when is_list(Value) ->
    Value;
format_value(Value) ->
    io_lib:format("~p", [Value]).

print_entry_1(Cert) ->
    TBSCert = Cert#'OTPCertificate'.tbsCertificate,
    io:fwrite("~p~n", [TBSCert]).

print_entry_2(Cert) ->
    io:fwrite("~p~n", [Cert]).

do_cert(CertPath) ->
    {ok, CAChain} = file:read_file(CertPath),
    PemEntries = public_key:pem_decode(CAChain),
    io:fwrite("~p~n", [length(PemEntries)]),
    [print_entry(public_key:pem_entry_decode(P)) || P <- PemEntries].



validate({'Certificate', RootCertDer, not_encrypted}, Chain) ->
    DerChain = [Der || {'Certificate', Der, not_encrypted} <- Chain],

    VerifyVun = fun(OtpCert, Event, State) ->
                        TBSCert = OtpCert#'OTPCertificate'.tbsCertificate,
                        Subject = format_name(TBSCert#'OTPTBSCertificate'.subject),
                        io:fwrite("<<<<<<<<<<<<<~n~p~n", [{Subject, Event, State}]),
                        case Event of
                            {extension, E} ->
                                {unknown, State};
                            _ ->
                                {valid, []}
                        end
                end,

    public_key:pkix_path_validation(RootCertDer, DerChain, [{verify_fun, {VerifyVun, []}}]).

print_chain_from_file(Name, Path) ->
    io:fwrite("~s:~n", [Name]),
    {ok, Raw} = file:read_file(Path),
    PemEntries = public_key:pem_decode(Raw),
    print_chain(PemEntries).

main([]) ->
    %%application:start(crypto),
    %%application:start(asn1),
    %%application:start(public_key),
    %%application:start(ssl),

    ChainPath = "/Users/artem/Work/cert/node_chain_with_root.pem",
    CAPath  = "/Users/artem/Work/cert/myroot-ca.crt",
    KeyPath  = "/Users/artem/Work/cert/server.key",
    MemChainPath = "/Users/artem/Work/watson/ns_server/data/n_0/config/memcached-cert.pem",

    {ok, RawChain} = file:read_file(ChainPath),
    ChainPemEntries = lists:reverse(public_key:pem_decode(RawChain)),

    {ok, RawCA} = file:read_file(CAPath),
    %%io:fwrite("~p~n", [RawCert]),
    [CAPemEntry] = public_key:pem_decode(RawCA),

    io:fwrite("CA:~n"),
    print_chain([CAPemEntry]),
    io:fwrite("CHAIN:~n"),
    print_chain(ChainPemEntries),

    io:fwrite("BIN: ~p~n", [public_key:pem_encode(ChainPemEntries)]),

    RV = validate(CAPemEntry, ChainPemEntries),

    io:fwrite("~p~n+++++++++++++++++++++++++++++~n", [RV]),

    print_chain_from_file("MEMCACHED CHAIN", "/Users/artem/Work/watson/ns_server/data/n_0/config/memcached-cert.pem"),
    print_chain_from_file("GENERATED LOCAL", "/Users/artem/Work/watson/ns_server/data/n_0/config/local-ssl-cert.pem").
