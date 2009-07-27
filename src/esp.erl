%%
-module(esp).
-vsn("1.0").
-author('steve@simulacity.com').

-include("esp.hrl").
%% TEMP
-include("ewok.hrl").

-compile(export_all).
%% API
-export([render/4, render_page/4, parse_template/1]).
-export([add_dir/1, refresh/0, get_template/1]).

-define(ESP_REGEX, "(<%|%>)").
-define(ESP_DECOMMENT, "<%--.*--%>\n?"). %% NOTE! use dotall option for re:

%% internal use for Cache lookup
-record(template, {path, markup}).

validate(Params) ->
	esp_validator:validate(Params, [not_null]).
validate(Params, Predicates) ->
	esp_validator:validate(Params, Predicates).

%% 
render(Page) when is_record(Page, page) ->
	Spec = esp_html:page(Page#page.title, Page#page.head, Page#page.body),
	try begin
		Elements = render_elements([Spec], []),
		Markup = list_to_binary(Elements),
		Headers = [
			{content_type, ewok_http:mimetype(Page#page.doctype)},
			{content_length, size(Markup)}
		], 
		{ok, Headers, Markup}
	end catch
	_Error:Reason ->
		{internal_server_error, [], Reason}
	end.
%% 
render(Template, Module, Request, Session) when ?is_string(Template) ->
	case get_template(Template) of
	undefined -> {error, no_file};
	{error, Reason} -> {error, Reason};
	_ -> render_page(Template#template.markup, Module, Request, Session)
	end.

%
render_page(Spec, Module, Request, Session)  ->
	render_page(Spec, Module, Request, Session, true).
%
render_page(Spec, Module, Request, Session, AllowInclude)  ->
%	?TTY("SPEC:~n~p~n", [Spec]),
	F = fun (X) ->
		try begin
			case X of
			Bin when is_binary(Bin) -> 
				Bin;
			%% Grrrr strings...
			String = [H|_] when ?is_string(H) ->
				list_to_binary(String);
			Records when is_list(Records) ->
				render_elements(Records, []);
			{esp, 'include', Filename} ->
				true = AllowInclude, % intentionally throw parse error
				%have to load the file now...
				?TTY("ESP include: ~p~n", [Filename]);
				%render_page(Spec, Module, Request, Session, false);
			{page, Function, []} -> 
				Result = Module:Function(Request, Session),
				%?TTY("ESP -> ~p ~p~n", [{Module, Function}, Result]),
				render_elements(Result, []);
			{request, Function, []} ->
				esp_html:text(Request:Function());
			{session, ip, []} ->
				Session:ip();
			{session, started, []} ->
				esp_html:text(Session:started());
			{session, user, []} ->
				case Session:user() of
				User when is_record(User, user) -> User#user.name;
				_ -> <<"undefined">>
				end;
			{session, data, []} ->
				esp_html:text(Session:data());
			{M, F, []} ->
				case M:F() of
				Value when is_binary(Value) -> Value;
				Value -> esp_html:text(Value)
				end
			end
		end catch
		_:_ -> [
			<<"<tt>&lt;!ESP PARSE ERROR ">>,
			esp_html:text(X),
			<<" &gt;</tt>">> ]
		end
	end,
	case list_to_binary([F(X) || X <- Spec]) of
	Markup when is_binary(Markup) ->
		{ok, Markup};
	{error, Reason} -> 
		{error, Reason}
	end.
	
% render_elements
render_elements([H|T], Acc) when is_binary(H) ->
	render_elements(T, [H|Acc]);
%% GRRR STRINGS!
render_elements([H|T], Acc) when ?is_string(H) ->
	render_elements(T, [list_to_binary(H)|Acc]);
render_elements([H|T], Acc) when is_list(H) ->
	render_elements(T, [render_elements(H, [])|Acc]);
render_elements([H|T], Acc) when is_tuple(H) ->
	render_elements(T, [render_element(H)|Acc]);
render_elements([], Acc) ->
	lists:reverse(Acc).

% render_element/1
render_element(E) when is_tuple(E), size(E) > 1 ->
	T = transform_custom_element(E),
	{[Type, Fields], Values} = lists:split(2, tuple_to_list(T)),
	F = fun (X, Y) ->
		Value =
			if 
			X =:= body -> [];
			Y =:= undefined -> [];
			is_atom(Y) -> atom_to_list(Y);
			is_integer(Y) -> integer_to_list(Y);
			is_list(Y) -> Y;
			is_binary(Y) -> binary_to_list(Y); %% this shouldn't happen :)
			true -> []
			end,
		case Value of
		[] -> [];
		_ -> [<<$ >>, atom_to_binary(X, utf8), <<$=,$">>, list_to_binary(Value), <<$">>]
		end
	end,
	Tag = atom_to_binary(Type, utf8), %% is latin1 "safer"?
	Attrs = lists:zipwith(F, Fields, Values),
	Body = 
		%% this case is ENTIRELY to improve markup formatting
		case esp_html:element_type(Type) of
		block ->
			case Fields of 
			[] -> [<<$/, $>, $\n>>];
			_ ->
				case lists:last(Fields) of 
				body -> [<<$>, $\n>>, render_elements(lists:last(Values), []), <<$<, $/>>, Tag, <<$>, $\n>>];
				_ -> [<<$/, $>, $\n>>]
				end
			end;
		inline ->
			case Fields of 
			[] -> [<<$/, $>>>];
			_ ->
				case lists:last(Fields) of 
				body -> [<<$>>>, render_elements(lists:last(Values), []), <<$<, $/>>, Tag, <<$>>>];
				_ -> [<<$/, $>>>]
				end
			end;
		normal ->
			case Fields of 
			[] -> [<<$/, $>, $\n>>];
			_ ->
				case lists:last(Fields) of 
				body -> [<<$>>>, render_elements(lists:last(Values), []), <<$<, $/>>, Tag, <<$>, $\n>>];
				_ -> [<<$/, $>, $\n>>]
				end
			end
		end,
%	?TTY(" ~p~n", [Tag]),
	list_to_binary([<<$<>>, Tag, Attrs, Body]). 

%% first stab at this... 
%% fprof appears to be saying that is_record guards eat up processing, so...
transform_custom_element(E = #css{}) ->
	esp_html:stylesheet(E#css.path, E#css.type, E#css.media);
transform_custom_element(E = #grid{}) ->
	esp_html:grid(E);
transform_custom_element(E) ->
	E.

%%
add_dir(Path) ->
% wrong!% wrong!% wrong!% wrong!
	ewok_cache:add(template, Path).

%%
refresh() ->
	ewok_cache:clear(template).

%%
get_template(Path) ->
	case ewok_cache:lookup(template, Path) of
	T when is_record(T, template) -> 
		T;
	undefined ->
		TemplateRoot = ewok_config:get("ewok.http.template_root"),
		Markup = load_template(TemplateRoot, Path),
		T = #template{path=Path, markup=Markup},
		case ewok_config:get("ewok.runmode", production) of
		true -> ok = ewok_cache:add(T);
		_ -> ok
		end,
		T
	end.

load_template(undefined, Path) -> 
	{error, {undefined, Path}};
load_template(Dir, Path) ->
	File = filename:join([ewok_util:appdir(), Dir, Path]),
	case filelib:is_regular(File) of
	true -> 
		{ok, Bin} = file:read_file(File),
		parse_template(Bin);
	false -> 
		{error, File}
	end.
	
parse_template(Bin) ->
	Bin2 = re:split(Bin, ?ESP_DECOMMENT, [dotall]),
	parse_template(re:split(Bin2, ?ESP_REGEX), []).
parse_template([<<"<%">>, Expr, <<"%>">>|T], Acc) ->
	parse_template(T, [parse_expr(Expr)|Acc]);
parse_template([H|T], Acc) ->
	parse_template(T, [H|Acc]);
parse_template([], Acc) ->
	lists:reverse(Acc).

parse_expr(Expr) ->
	[Ms, ":", Fs, "(", Args, ")"] = re:split(ewok_util:trim(Expr), "([\:\(\)])", [{return, list}, trim]),
	[Mb, Fb, Argb] = [ewok_util:trim(X) || X <- [Ms, Fs, Args]],
	{list_to_atom(Mb), list_to_atom(Fb), Argb}.
