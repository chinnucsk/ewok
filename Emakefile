% -*- mode: erlang -*-

%% Build third party source
{"src/extern/*", [{i, "include"}, {outdir, "ebin"}, debug_info, strict_record_tests]}.
{"src/extern/*/*", [{i, "include"}, {outdir, "ebin"}, debug_info, strict_record_tests]}.

%% Compile behaviour definitions first
{"src/ewok_service.erl", [{i, "include"}, {outdir, "ebin"}, debug_info, strict_record_tests]}.
{"src/ewok_inet.erl", [{i, "include"}, {outdir, "ebin"}, debug_info, strict_record_tests]}.
{"src/ewok_codec.erl", [{i, "include"}, {outdir, "ebin"}, debug_info, strict_record_tests]}.
{"src/db/ewok_datasource.erl", [{i, "include"}, {outdir, "ebin"}, debug_info, strict_record_tests]}.
{"src/http/ewok_http_resource.erl", [{i, "include"}, {outdir, "ebin"}, debug_info, strict_record_tests]}.
%{"src/http/ewok_web_application.erl", [{i, "include"}, {outdir, "ebin"}, debug_info, strict_record_tests]}.
{"src/usp/usp_service.erl", [{i, "include"}, {outdir, "ebin"}, debug_info, strict_record_tests]}.

%% Then everything else 
{"src/*", [{i, "include"}, {outdir, "ebin"}, debug_info, strict_record_tests]}.
{"src/*/*", [{i, "include"}, {outdir, "ebin"}, debug_info, strict_record_tests]}.
{"src/*/*/*", [{i, "include"}, {outdir, "ebin"}, debug_info, strict_record_tests]}.

%% Then built-in applications
%{"priv/apps/*/src/*", [{i, "include"}, {i, "priv/apps/*/include"}, {outdir, "priv/apps/*/ebin"}, debug_info, strict_record_tests]}.
{"priv/apps/admin/src/*", [{i, "include"}, {outdir, "priv/apps/admin/ebin"}, debug_info, strict_record_tests]}.
{"priv/apps/tutorial/src/*", [{i, "include"}, {outdir, "priv/apps/tutorial/ebin"}, debug_info, strict_record_tests]}.
{"priv/apps/redoc/src/*", [{i, "include"}, {outdir, "priv/apps/redoc/ebin"}, debug_info, strict_record_tests]}.
{"priv/apps/wiki-1.0.0/src/*", [{i, "include"}, {outdir, "priv/apps/wiki-1.0.0/ebin"}, debug_info, strict_record_tests]}.
