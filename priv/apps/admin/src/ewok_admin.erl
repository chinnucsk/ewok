%%
-module(ewok_admin).

-include_lib("ewok/src/ewok.hrl").
-include_lib("ewok/src/esp.hrl").

-compile(export_all).

%
page(Spec, _Request, Session) ->
	Title = proplists:get_value(title, Spec, <<"Ewok AS">>),
	Head = [
		#css{path="/default.css"},
		#link{rel="icon", href="/favicon.png", type="image/png"},
		proplists:get_value(head, Spec, [])
	],
	Body = [
		#'div'{id="top", body=[
			#img{id="logo", src="/images/ewok-logo.png"},
			#'div'{id="dock", body=dock(Session)}
		]},
		#'div'{id="page", body=[
			#'div'{id="nav", body=proplists:get_value(menu, Spec, [])},
			#'div'{id="content", body=proplists:get_value(content, Spec, [])}
		]},
		#br{clear="all"},
		#'div'{id="footer", body=[
			#hr{},
			#p{body=[<<"Copyright &copy; 2009 Simulacity.com. All Rights Reserved.">>]}
		]}
	],
	%
	esp:render(#page{title=Title, head=Head, body=Body}).

%
dock(Session) ->
	Username = 
		case Session:user() of
		undefined -> <<"Guest">>;
		U = #user{} -> 
			{_, Name} = U#user.name,
			list_to_binary(Name)
		end,
	[#span{class="label", body=[
		Username, 
		<<" | ">>,
		#a{href="/admin", body=[<<"Dashboard">>]},
		<<" | ">>,
		#a{href="/", body=[<<"News">>]},
		<<" | ">>,
		#a{href="/doc", body=[<<"Documentation">>]},
		<<" | ">>,
		#a{href="/", body=[<<"About">>]}
	]}].
