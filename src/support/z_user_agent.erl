%% @author Marc Worrell <marc@worrell.nl>
%% @copyright 2012 Marc Worrell
%% @doc User agent classifications

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

-module(z_user_agent).
-author("Marc Worrell <marc@worrell.nl>").

-export([
    set_class/1,
    set_class/2,
    get_class/1,
    get_props/1,
    ua_probe/2,
    ua_select/2,
    to_ua_class/1,
    filename_split_class/1,
    order_class/2,
    classes/0,
    classes_fallback/1
]).

-include_lib("zotonic.hrl").

-define(UA_COOKIE, ?SESSION_UA_CLASS_Q).
-define(UA_COOKIE_MAX_AGE, 3600*24*3650).

-type ua_template_class() :: ua_classifier:device_type() | generic.


%% @doc Set the class in a context, useful for testing.
%%      Doesn't change the reqdata or the session settings.
-spec set_class(ua_classifier:device_type(), #context{}) -> #context{}.
set_class(UAClass, Context) ->
    Context#context{ua_class = UAClass}.


%% @doc Classify the user agent in the wm_reqdata.
-spec set_class(#wm_reqdata{}) -> {ok, #wm_reqdata{}}.
set_class(#wm_reqdata{} = ReqData) ->
    {UAClass, UAProps, IsUserSelect} = derive_class_from_reqdata(ReqData),
    {ok, RD1} = webmachine_request:set_metadata(
                    ua_class,
                    UAClass,
                    ReqData),
    webmachine_request:set_metadata(
            ua_props,
            [
                {is_user_select, IsUserSelect},
                {has_pointer, has_pointer_device(UAClass, UAProps)}
                | UAProps
            ],
            RD1).

    %% @doc Try to find the user agent class from the ua classifier and the ua cookie.
    derive_class_from_reqdata(ReqData) ->   
        {UAClass, UAProps} = get_ua_req_data(ReqData),
        case get_cookie(ReqData) of
            {UAClassCookie, UAPropsCookie, IsUserDefined} ->
                % Cookie with result of previous tests, merge with classifier props
                {UAClassCookie, 
                 lists:foldl(fun({K,V}, Acc) ->
                                lists:keyreplace(K, 1, Acc, {K,V})
                             end,
                             UAProps,
                             UAPropsCookie),
                 IsUserDefined};
            undefined ->
                {UAClass, UAProps, false}
        end.

    %% @doc Fetch the ua classification from a cookie, if present.
    get_cookie(ReqData) ->
        case webmachine_request:get_cookie_value(?UA_COOKIE, ReqData) of
            undefined ->
                undefined;
            Cookie ->
                Qs = mochiweb_util:parse_qs(mochiweb_util:unquote(Cookie)),
                case to_ua_class(proplists:get_value("c", Qs)) of
                    undefined ->
                        undefined;
                    U ->
                        try
                            IsUserDefined = z_convert:to_bool(proplists:get_value("u", Qs)),
                            Props = lists:foldl(fun({"h",V}, Acc) -> [{displayHeight, list_to_integer(V)} | Acc];
                                                   ({"w",V}, Acc) -> [{displayWidth, list_to_integer(V)} | Acc];
                                                   ({"t",V}, Acc) -> [{has_pointer, z_convert:to_bool(V)} | Acc];
                                                   (_,Acc) -> Acc
                                                 end,
                                                 [],
                                                 Qs),
                            {U, Props, IsUserDefined}
                        catch
                            _:_ ->
                                undefined
                        end
                end
        end.
        

%% @doc Let the ua-classifier do its work on the user-agent request header or qs parameter.
get_ua_req_data(ReqData) -> 
    % Try to get the ua class from a qs. This is a workarond for a problem in
    % Chrome and Safari which do not include the user-agent header in the 
    % websocket request.
    case get_ua_class_qs(ReqData) of
        undefined -> 
            case wrq:get_req_header_lc("user-agent", ReqData) of
                undefined ->
                    {desktop, []};
                UserAgent ->
                    ua_classify(UserAgent)
            end;
        Class ->
            {Class, []}
    end.
 
get_ua_class_qs(ReqData) ->
    to_ua_class(wrq:get_qs_value(?SESSION_UA_CLASS_Q, ReqData)).


%% @doc classify the UserAgent string. 
ua_classify(UserAgent) ->
    case ua_classifier:classify(UserAgent) of
        {ok, Props} ->
            {ua_classifier:device_type(Props), Props};
        {error, ua_classifier_nif_not_loaded} ->
            %% Ignore ua_classifier_nif_not_loaded error. It is a configuration error 
            %% and handled during startup.
            %% Note: Do not call z_config:get(use_ua_classifier) here. Otherwise 
            %% every request will call z_config gen_server making it a potential 
            %% bottleneck. 
            {desktop, []};    
        {error, Reason} ->
            error_logger:warning_msg("z_user_agent: ua_classifier returned error. [UA: ~p] [Reason: ~p]~n", [UserAgent, Reason]),
            {desktop, []}
    end.
        

to_ua_class("desktop") -> desktop;
to_ua_class("tablet") -> tablet;
to_ua_class("phone") -> phone;
to_ua_class("text") -> text;
to_ua_class(_) -> undefined.

%% @doc Get the user agent class
-spec get_class( #context{} | #wm_reqdata{} | undefined ) -> ua_classifier:device_type().
get_class(undefined) ->
    desktop;
get_class(#context{} = Context) ->
    get_class(z_context:get_reqdata(Context));
get_class(#wm_reqdata{} = ReqData) ->
    case webmachine_request:get_metadata(ua_class, ReqData) of
        undefined -> desktop;
        UAClass -> UAClass
    end.

%% @doc Get the user agent class
-spec get_props( #context{} | #wm_reqdata{} | undefined ) -> [ {atom(), term()} ].
get_props(undefined) ->
    [{id, <<"desktop">>}];
get_props(#context{} = Context) ->
    get_props(z_context:get_reqdata(Context));
get_props(#wm_reqdata{} = ReqData) ->
    case webmachine_request:get_metadata(ua_props, ReqData) of
        undefined -> [{id, <<"desktop">>}];
        Props -> Props
    end.

%% @doc The user selects an user agent by hand. Update cookie and session.
-spec ua_select(ua_classifier:device_type() | automatic, #context{}) -> #context{}.
ua_select(automatic, Context) ->
    {UAClass, UAProps} = get_ua_req_data(z_context:get_reqdata(Context)),
    CurrWidth = proplists:get_value(displayWidth, UAProps, 800),
    CurrHeight = proplists:get_value(displayHeight, UAProps, 600),
    CurrHasPointer = has_pointer_device(UAClass, UAProps),
    set_cookie(UAClass,
               false,
               CurrHasPointer,
               CurrWidth,
               CurrHeight,
               Context);    
ua_select(UAClass, Context) ->
    case get_class(Context) of
        UAClass ->
            Context;
        _Other ->
            CurrPs = get_props(Context),
            CurrWidth = proplists:get_value(displayWidth, CurrPs, 800),
            CurrHeight = proplists:get_value(displayHeight, CurrPs, 600),
            CurrHasPointer = has_pointer_device(UAClass, CurrPs),
            set_cookie(UAClass,
                       true,
                       CurrHasPointer,
                       CurrWidth,
                       CurrHeight,
                       Context)
    end.

%% @doc Handle the return value of the user-agent probe.
%%      When it comes back we know the user-agent has javascript, so we might want to upgrade
%%      from text to phone.
ua_probe(ProbePs, Context) ->
    ua_probe(false, ProbePs, Context).

ua_probe(SetManual, ProbePs, Context) ->
    CurrPs = get_props(Context),
    CurrClass = get_class(Context),

    CurrIsUser = not SetManual orelse proplists:get_value(is_user_select, CurrPs, false),
    CurrWidth = proplists:get_value(displayWidth, CurrPs, 800),
    CurrHeight = proplists:get_value(displayHeight, CurrPs, 600),
    CurrHasPointer = has_pointer_device(CurrClass, CurrPs),

    ProbeWidth = proplists:get_value(width, ProbePs),
    ProbeHeight = proplists:get_value(height, ProbePs),
    % Only set ProbeIsTouch when it positively identifies an unexpected touch screen.
    ProbeHasPointer = proplists:get_value(is_touch, ProbePs, false) orelse CurrHasPointer,

    IsChanged = CurrWidth =/= ProbeWidth
            orelse CurrHeight =/= ProbeHeight
            orelse CurrHasPointer =/= ProbeHasPointer,
            
    case CurrIsUser of
        false ->
            % As we got a probe back we know JS is working.
            % Upgrade the 'text' classification to 'phone'
            NewClass = class_from_size(CurrClass, ProbeWidth, ProbeHeight, ProbeHasPointer),
            case NewClass =/= CurrClass of
                false ->
                    case IsChanged of
                        true ->
                            {ok, set_cookie(CurrClass,
                                            false,
                                            ProbeHasPointer,
                                            ProbeWidth,
                                            ProbeHeight,
                                            Context)};
                        false ->
                            ok
                    end;
                true ->
                    {reload, set_cookie(NewClass,
                                        false,
                                        ProbeHasPointer,
                                        ProbeWidth,
                                        ProbeHeight,
                                        Context)}
            end;
        true ->
            % User defined: don't change the user agent class
            case IsChanged of
                true ->
                    {ok, set_cookie(CurrClass,
                                    true,
                                    ProbeHasPointer,
                                    ProbeWidth,
                                    ProbeHeight,
                                    Context)};
                false ->
                    ok
            end
    end.

    % Set the cookie, update the session with the new ua props
    set_cookie(Class, IsUser, HasPointer, W, H, Context) ->
        % Keep this sorted on key
        Props = [
            {displayHeight, H},
            {displayWidth, W},
            {has_pointer, HasPointer},
            {is_user_select, IsUser}
        ],
        z_session:set(ua_class, Class, Context),
        z_session:set(ua_props, lists:keymerge(1, Props, lists:keysort(1, get_props(Context))), Context),
        V = mochiweb_util:urlencode([
                            {"c", Class},
                            {"u", case IsUser of true -> 1; false -> 0 end},
                            {"t", case HasPointer of true -> 1; false -> 0 end},
                            {"w", W},
                            {"h", H}
                        ]),
        Options = [
            {max_age, ?UA_COOKIE_MAX_AGE}, 
            {path, "/"},
            {http_only, false}
        ],
        z_context:set_cookie(?UA_COOKIE, mochiweb_util:quote_plus(V), Options, Context).


    % Get the class from the user agent screen size and pointer device.
    % The px sizes are from http://twitter.github.com/bootstrap/scaffolding.html#responsive
    class_from_size(_, W, _H, false) when W >= 768 -> desktop;
    class_from_size(_, W, H, true) when W > 480, H > 480 -> tablet; % larger display, pointer
    class_from_size(_, W, H, false) when W =< 480; H =< 480 -> text; % small display, no pointer
    class_from_size(_, W, H, true) when W =< 480; H =< 480 -> phone; % portrait or landscape phone
    class_from_size(C, _, _, _) -> C.


%% @doc A device is easily navigatable when it has a pointer device.
has_pointer_device(desktop, _Ps) -> true;
has_pointer_device(text, _Ps) -> false;
has_pointer_device(_, Ps) -> ua_classifier:has_pointer_device(Ps).


%% @doc Split a filename (with subdir) to a device class and a relative path.
-spec filename_split_class(file:filename()) -> { ua_template_class(), file:filename() }.
filename_split_class(F) ->
    case filename:split(F) of
        ["desktop"|T] -> {desktop, string:join(T, "/")};
        ["tablet"|T] -> {tablet, string:join(T, "/")};
        ["phone"|T] -> {phone, string:join(T, "/")};
        ["text"|T] -> {text, string:join(T, "/")};
        Parts -> {generic, string:join(Parts, "/")}
    end.


%% @doc Ordering function for lists:sort/2. Orders by genericity. Most specific first.
-spec order_class( ua_classifier:device_type(), ua_classifier:device_type() ) -> boolean().
order_class(A,A) -> true;
order_class(_, generic) -> false;
order_class(generic, _) -> true;
order_class(desktop, _) -> true;
order_class(phone, text) -> true;
order_class(tablet, text) -> true;
order_class(tablet, phone) -> true;
order_class(_, _) -> false.


%% @doc Return all possible UA classes
-spec classes() -> [ ua_classifier:device_type() ].
classes() ->
    [ text, phone, tablet, desktop ].

%% @doc Return all possible UA classes for a fallback from another class, including the given class.
%%      The returned list is ordered from the specific to less specific.
-spec classes_fallback(ua_classifier:device_type()) -> [ ua_classifier:device_type() ].
classes_fallback(UAClass) ->
    lists:dropwhile(fun(X) -> X =/= UAClass end, lists:reverse(classes())).
