%% @author Marc Worrell <marc@worrell.nl>
%% @copyright 2012 Marc Worrell
%% @doc Calculate a quadtile code from a lat/long location.

%% Copyright 2012 Marc Worrell
%%
%% Licensed under the Apache License, Version 2.0 (the "License");
%% you may not use this file except in compliance with the License.
%% You may obtain a copy of the License at
%% 
%%     http://www.apache.org/licenses/LICENSE-2.0
%% 
%% Unless required by applicable law or agreed to in writing, software
%% distributed under the License is distributed on an "AS IS" BASIS,
%% WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%% See the License for the specific language governing permissions and
%% limitations under the License.

-module(mod_geomap).
-author("Marc Worrell <marc@worrell.nl>").

-mod_title("GeoMap services").
-mod_description("Maps, mapping, geocoding and geo calculations..").
-mod_prio(1200).
-mod_depends([mod_l10n]).

-export([
    event/2,
    
    observe_rsc_get/3,
    observe_pivot_update/3,
    observe_pivot_fields/3,

    find_geocode/3,
    find_geocode_api/3
]).

-include_lib("zotonic.hrl").

%% @doc Handle an address lookup from the admin.
%% @todo Maybe add check if the user is allowed to use the admin.
event(#postback_notify{message="address_lookup"}, Context) ->
    {ok, Type, Q} = q([
            {address_street_1, z_context:get_q("street", Context)},
            {address_city, z_context:get_q("city", Context)},
            {address_state, z_context:get_q("state", Context)},
            {address_postcode, z_context:get_q("postcode", Context)},
            {address_country, z_context:get_q("country", Context)}
        ], Context),
    case find_geocode(Q, Type, Context) of
        {error, _} ->
            z_script:add_script("map_mark_location_error();", Context);
        {ok, {Lat, Long}} ->
            z_script:add_script(io_lib:format("map_mark_location(~p,~p);", [Long, Lat]), Context)
    end.


%% @doc Append computed latitude and longitude values to the resource.
observe_rsc_get(#rsc_get{}, Props, _Context) ->
    case proplists:get_value(pivot_geocode, Props) of
        undefined -> 
            Props;
        Quadtile ->
            {Lat, Long} = geomap_quadtile:decode(Quadtile),
            [
                {computed_location_lat, Lat},
                {computed_location_lng, Long}
                | Props
            ]
    end.


%% @doc Check if the latitude/longitude are set, if so the pivot the pivot_geocode.
%%      If not then try to derive the lat/long from the rsc's address data.
observe_pivot_update(#pivot_update{}, KVs, _Context) ->
    case {catch z_convert:to_float(proplists:get_value(location_lat, KVs)),
          catch z_convert:to_float(proplists:get_value(location_lng, KVs))}
    of
        {Lat, Long} when is_float(Lat), is_float(Long) ->
            [ 
                {pivot_geocode, geomap_quadtile:encode(Lat, Long)},
                {pivot_geocode_qhash, undefined}
                | KVs
            ];
        _ -> 
            KVs
    end.


%% @doc Check if the latitude/longitude are set, if so the pivot the pivot_geocode.
%%      If not then try to derive the lat/long from the rsc's address data.
observe_pivot_fields(#pivot_fields{rsc=R}, KVs, Context) ->
    case {catch z_convert:to_float(proplists:get_value(location_lat, R)),
          catch z_convert:to_float(proplists:get_value(location_lng, R))}
    of
        {Lat, Long} when is_float(Lat), is_float(Long) ->
            [ 
                {pivot_geocode, geomap_quadtile:encode(Lat, Long)},
                {pivot_geocode_qhash, undefined} 
                | KVs
            ];
        _ ->
            % Optionally geocode the address in the resource.
            % When successful this will spawn a new geocode pivot.
            case optional_geocode(R, Context) of
                reset -> 
                    [ 
                        {pivot_geocode, undefined},
                        {pivot_geocode_qhash, undefined} 
                        | KVs
                    ];
                {ok, Lat, Long, QHash} ->
                    [ 
                        {pivot_geocode, geomap_quadtile:encode(Lat, Long)},
                        {pivot_geocode_qhash, QHash} 
                        | KVs
                    ];
                ok -> 
                    KVs
            end
    end.



%% @doc Check if we should lookup the location belonging to the resource.
%%      If so we store the quadtile code into the resource without a re-pivot.
optional_geocode(R, Context) ->
    Lat = proplists:get_value(location_lat, R),
    Long = proplists:get_value(location_long, R),
    case z_utils:is_empty(Lat) andalso z_utils:is_empty(Long) of
        false ->
            reset;
        true ->
            case q(R, Context) of
                {ok, _, <<>>} ->
                    reset;
                {ok, Type, Q} ->
                    LocHash = crypto:md5(Q),
                    case proplists:get_value(pivot_geocode_qhash, R) of
                        LocHash ->
                            % Not changed since last lookup 
                            ok;
                        _ ->
                            % Changed, and we are doing automatic lookups
                            case find_geocode(Q, Type, Context) of
                                {error, _} ->
                                    reset;
                                {ok, {NewLat,NewLong}} ->
                                    {ok, NewLat, NewLong, LocHash}
                            end
                    end
            end
    end.


find_geocode(Q, Type, Context) ->
    case geomap_precoded:find_geocode(Q, Type) of
        {ok, {_, _}} = OK ->
            OK;
        {error, notfound} ->
            find_geocode_api(Q, Type, Context) 
    end.

%% @doc Check with Google and OpenStreetMap if they know the address
find_geocode_api(Q, country, _Context) ->
    Qq = mochiweb_util:quote_plus(Q),
    openstreetmap(Qq);
find_geocode_api(Q, _Type, Context) ->
    Qq = mochiweb_util:quote_plus(Q),
    case googlemaps_check(Qq, Context) of
        {error, _} ->
            openstreetmap(Qq);
        {ok, {_Lat, _Long}} = Ok->
            Ok
    end.

        
openstreetmap(Q) ->
    Url = "http://nominatim.openstreetmap.org/search?format=json&limit=1&addressdetails=0&q="++Q,
    case get_json(Url) of
        {ok, [{struct, Props}|_]} ->
            case {z_convert:to_float(proplists:get_value(<<"lat">>, Props)),
                  z_convert:to_float(proplists:get_value(<<"lon">>, Props))}
            of
                {Lat, Long} when is_float(Lat), is_float(Long) ->
                    {ok, {Lat, Long}};
                _ ->
                    {error, not_found}
            end;
        {ok, []} ->
            lager:debug("OpenStreetMap empty return for ~p", [Q]),
            {error, not_found};
        {ok, JSON} ->
            lager:error("OpenStreetMap unknown JSON ~p on ~p", [JSON, Q]),
            {error, unexpected_result};
        {error, Reason} = Error ->
            lager:warning("OpenStreetMap returns ~p for ~p", [Reason, Q]),
            Error
    end.

googlemaps_check(Q, Context) ->
    case z_depcache:get(googlemaps_error, Context) of
        undefined ->
            case googlemaps(Q) of
                {error, query_limit} = Error ->
                    lager:warning("Geomap: Google reached query limit, disabling for 1800 sec"),
                    z_depcache:set(googlemaps_error, Error, 1800, Context),
                    Error;
                Result ->
                    Result
            end;
        {ok, Error} -> 
            lager:debug("Geomap: skipping Google lookup due to ~p", [Error]),
            Error
    end.

googlemaps(Q) ->
    Url = "http://maps.googleapis.com/maps/api/geocode/json?sensor=false&address="++Q,
    case get_json(Url) of
        {ok, []} ->
            lager:debug("Google maps empty return for ~p", [Q]),
            {error, not_found};
        {ok, {struct, Props}} ->
            case proplists:get_value(<<"status">>, Props) of
                <<"OK">> ->
                    [{struct, Result}|_] = proplists:get_value(<<"results">>, Props),
                    case proplists:get_value(<<"geometry">>, Result) of
                        undefined ->
                            lager:info("Google maps result without geometry: ~p", [Props]),
                            {error, no_result};
                        {struct, GPs} ->
                            case proplists:get_value(<<"location">>, GPs) of
                                {struct, Ls} ->
                                    case {z_convert:to_float(proplists:get_value(<<"lat">>, Ls)),
                                          z_convert:to_float(proplists:get_value(<<"lng">>, Ls))}
                                    of
                                        {Lat, Long} when is_float(Lat), is_float(Long) ->
                                            {ok, {Lat, Long}};
                                        _ ->
                                            {error, not_found}
                                    end;
                                undefined ->
                                    lager:info("Google maps geometry without location: ~p", [Props]),
                                    {error, no_result}
                            end
                    end;
                <<"ZERO_RESULTS">> ->
                    {error, not_found};
                <<"OVER_QUERY_LIMIT">> ->
                    {error, query_limit};
                Status ->
                    lager:warning("Google maps status ~p on ~p", [Status, Q]),
                    {error, unexpected_result}
            end;
        {ok, JSON} ->
            lager:error("Google maps unknown JSON ~p on ~p", [JSON, Q]),
            {error, unexpected_result};
        {error, Reason} = Error ->
            lager:warning("Google maps returns ~p on ~p", [Reason, Q]),
            Error
    end.



get_json(Url) ->
    lager:debug("Geo lookup: ~p", [Url]),
    case httpc:request(get, {Url, []}, [{autoredirect, true}, {relaxed, true}, {timeout, 10000}], []) of
        {ok, {
            {_HTTP, 200, _OK},
            Headers,
            Body
        }} ->
            case proplists:get_value("content-type", Headers) of
                "application/json" ++ _ ->
                    {ok, mochijson2:decode(Body)};
                CT ->
                    {error, {unexpected_content_type, CT}}
            end;
        {error, _Reason} = Err ->
            Err;
        {ok, {{_, 503, _}, _, _}} ->
            {error, no_service};
        {ok, {{_, 404, _}, _, _}} ->
            {error, not_found};
        {ok, _Other} ->
            {error, unexpected_result}
    end.


q(R, Context) ->
    Fs = iolist_to_binary([
        p(address_street1, $,, R),
        p(address_city, $,, R),
        p(address_state, $,, R),
        p(address_postcode, $,, R)
    ]),
    case Fs of
        <<>> ->
            {ok, country, iolist_to_binary(p(address_country, <<>>, R))};
        _ -> 
            Country = iolist_to_binary(country_name(proplists:get_value(address_country, R), Context)),
            {ok, full, <<Fs/binary, Country/binary>>}
    end.

p(F, Sep, R) ->
    case proplists:get_value(F, R) of
        <<>> -> <<>>;
        [] -> <<>>;
        undefined -> <<>>;
        V -> [V, Sep]
    end.


country_name([], _Context) -> <<>>;
country_name(<<>>, _Context) -> <<>>;
country_name(undefined, _Context) -> <<>>;
country_name(<<"gb-nir">>, _Context) -> <<"Northern Ireland">>;
country_name(Iso, Context) ->
    m_l10n:country_name(Iso, en, Context).

