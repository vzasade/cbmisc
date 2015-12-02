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
            case Acc of
                [] ->
                    [Str, "=", format_value(Value)];
                _ ->
                    [[", ", Str, "=", format_value(Value)] | Acc]
            end
    end.

format_name(Name) ->
    %%Normalized = public_key:pkix_normalize_name(Name),
    {rdnSequence, STVList} = Name,
    Bumpy = lists:foldl(fun (V, Acc) ->
                                format_attribute(V, Acc)
                        end, [], STVList),
    lists:flatten(lists:reverse(Bumpy)).

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
                        {valid, []}
                end,

    public_key:pkix_path_validation(RootCertDer, DerChain, [{verify_fun, {VerifyVun, []}}]).

main([]) ->
    %%application:start(crypto),
    %%application:start(asn1),
    %%application:start(public_key),
    %%application:start(ssl),

    ChainPath = "/Users/artem/Work/cert/chain.pem",
    CertPath  = "/Users/artem/Work/cert/server_correct.crt",
    KeyPath  = "/Users/artem/Work/cert/server.key",

    {ok, RawCAChain} = file:read_file(ChainPath),
    CAChainPemEntries = lists:reverse(public_key:pem_decode(RawCAChain)),

    {ok, RawCert} = file:read_file(CertPath),
    io:fwrite("~p~n", [RawCert]),
    [RawCertPemEntry] = public_key:pem_decode(RawCert),

    [RawRootCertPemEntry | RestOfTheChain] = CAChainPemEntries,
    CertChain = RestOfTheChain ++ [RawCertPemEntry],

    ToShowInUI = public_key:pem_encode([RawRootCertPemEntry]),

    io:fwrite("ORIG:~n"),
    print_chain(CAChainPemEntries),
    io:fwrite("CA:~n"),
    print_chain([RawRootCertPemEntry]),
    io:fwrite("CHAIN:~n"),
    print_chain(CertChain),

    RV = validate(RawRootCertPemEntry, CertChain),

    io:fwrite("~p~n+++++++++++++++++++++++++++++~n", [RV]),
    io:fwrite("~p~n=============~p~n---------------------~n~p~n", [RawCAChain, RawRootCertPemEntry, CertChain]).
