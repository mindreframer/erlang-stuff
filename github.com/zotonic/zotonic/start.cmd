set erl=erl
rem set erl="C:\Program Files\erl5.7.4\bin\erl.exe"

set ebin=./ebin ./modules/mod_oauth/deps/erlang-oauth/ebin ./deps/mochiweb/ebin ./deps/webzmachine/ebin ./deps/lager/ebin
%erl% +P 10000000 -pa %ebin% -boot start_sasl -sasl errlog_type error -s zotonic
