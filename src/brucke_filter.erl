%%%
%%%   Copyright (c) 2016-2018 Klarna Bank AB (publ)
%%%
%%%   Licensed under the Apache License, Version 2.0 (the "License");
%%%   you may not use this file except in compliance with the License.
%%%   You may obtain a copy of the License at
%%%
%%%       http://www.apache.org/licenses/LICENSE-2.0
%%%
%%%   Unless required by applicable law or agreed to in writing, software
%%%   distributed under the License is distributed on an "AS IS" BASIS,
%%%   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
%%%   See the License for the specific language governing permissions and
%%%   limitations under the License.
%%%

-module(brucke_filter).

-export([ init/3
        , init/4
        , filter/7
        , filter/8
        ]).

-export_type([ cb_state/0
             , filter_result/0
             , filter_return/0
             ]).

-include("brucke_int.hrl").

-type cb_state() :: term().
-type headers() :: kpro:headers().
-type filter_result() :: boolean()
                       | {brod:key(), brod:value()}
                       | {brod:msg_ts(), brod:key(), brod:value()}
                       | #{key => iodata(),
                           value => iodata(),
                           ts => brod:msg_ts(),
                           headers => [{binary(), binary()}]
                          }
                       | [filter_result()].
-type filter_return() :: {filter_result(), cb_state()}.

-define(DEFAULT_STATE, []).

%% Called when route worker (`brucke_subscriber') start/restart.
-callback init(UpstreamTopic :: brod:topic(),
               UpstreamPartition :: brod:partition(),
               InitArg :: term()) -> {ok, cb_state()}.

%% Called by assignment worker (`brucke_subscriber') for each message.
%% Return value implications:
%% true: No change, forward the message as-is to downstream
%% false: Discard the message
%% {NewKey, NewValue}: Produce the transformed new Key and Value to downstream.
-callback filter(Topic :: brod:topic(),
                 Partition :: brod:partition(),
                 Offset :: brod:offset(),
                 Key :: brod:key(),
                 Value :: brod:value(),
                 Headers :: headers(),
                 CbState :: cb_state()) -> filter_return().

%% @doc Call callback module's init API
-spec init(module(), brod:topic(), brod:partition(), term()) ->
        {ok, cb_state()}.
init(Module, UpstreamTopic, UpstreamPartition, InitArg) ->
  Module:init(UpstreamTopic, UpstreamPartition, InitArg).

%% @doc The default filter does not do anything special.
-spec init(brod:topic(), brod:partition(), term()) -> {ok, _}.
init(_UpstreamTopic, _UpstreamPartition, _InitArg) ->
  {ok, ?DEFAULT_STATE}.

%% @doc Filter message set.
-spec filter(module(), brod:topic(), brod:partition(), brod:offset(),
             brod:key(), brod:value(), headers(), cb_state()) -> filter_return().
filter(Module, Topic, Partition, Offset, Key, Value, Headers, CbState) ->
  Module:filter(Topic, Partition, Offset, Key, Value, Headers, CbState).

%% @doc The default filter does nothing.
-spec filter(brod:topic(), brod:partition(), brod:offset(),
             brod:key(), brod:value(), headers(), cb_state()) -> filter_return().
filter(_Topic, _Partition, _Offset, _Key, _Value, _Headers, ?DEFAULT_STATE) ->
  {true, ?DEFAULT_STATE}.

%%%_* Emacs ====================================================================
%%% Local Variables:
%%% allout-layout: t
%%% erlang-indent-level: 2
%%% End:
