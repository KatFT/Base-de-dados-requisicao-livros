-module(servidor).
-compile(export_all).

%iniciar servidor
starter() -> register(processo, spawn(fun() -> loop() end)).

%iniciar as tabelas no cliente
inicia() -> rpc({init}).

start() -> rpc({start}).

reset() -> rpc({reset}).

atum() -> rpc({atum}).

%--------------------------------
%lookup

empr(Livro) -> rpc({empr,Livro}).

req(Codigo) -> rpc({req,Codigo}).

book(CC) -> rpc({book,CC}).

code(Livro) -> rpc({code,Livro}).

nReq(CC) -> rpc({nReq,CC}).
%------------------------------
%update

add(CC,Codigo) -> rpc({add,CC,Codigo}).

ret(CC,Codigo) -> rpc({ret,CC,Codigo}).

%------------------------------
%stop(processo) -> processo ! {stop,self(),0},ok.
stop() -> rpc({stop}),ok.
rpc(Q) ->
    Ref=make_ref(),
    processo ! {self(),Ref, Q},
    receive
    {processo, Ref, Reply} ->
        Reply
    end.

loop() ->  
    receive
    {From,Ref, {init}} ->  
        From ! {processo,Ref, trabalho1:init()},
        loop();
        
    {From,Ref, {start}} -> 
        From ! {processo, Ref,trabalho1:start()},
        loop();
    {From,Ref, {reset}} ->
        From ! {processo,Ref, trabalho1:reset_tables()},
        loop();
    {From, Ref,{atum}} ->
        From ! {processo, Ref,trabalho1:atum()},
        loop();
    {From,Ref, {empr,Livro}} ->
        From ! {processo, Ref,trabalho1:emprestimos(Livro)},
        loop();
    {From,Ref, {req,Codigo}} ->
        From ! {processo,Ref, trabalho1:requesitado(Codigo)},
        loop();
    {From, Ref,{book,CC}} ->
        From ! {processo,Ref, trabalho1:livros(CC)},
        loop();
    {From, Ref,{code,Livro}} ->
        From ! {processo, Ref,trabalho1:codigos(Livro)},
        loop();
    {From,Ref, {nReq,CC}} ->
        From ! {processo,Ref, trabalho1:nRequisicoes(CC)},
        loop();
    {From,Ref, {add,CC,Codigo}} ->
        From ! {processo, Ref,trabalho1:add_req(CC,Codigo)},
        %io:format("Não existe!~n"),
        loop();
    {From,Ref, {ret,CC,Codigo}} ->
        From ! {processo,Ref, trabalho1:retorno(CC,Codigo)},
        loop();
    %{stop,From,Ref} ->
    {From,Ref, {stop}} ->
        From ! {processo,Ref,ok},
        io:format("SERVIDOR FOI FECHADO!~n"),
        ok
    end.

%% Abrir uma nova máquina virtual:
%% erl -name gandalf
%% Enviar mensagens entre máquinas diferentes:
%% erl -name bilbo
%% rpc:call('gandalf@MacBook.local',tabela1,store,[ana,porto]).
%%true
%% rpc:call('gandalf@MacBook.local',tabela1,lookup,[ana]).
%% {ok,porto}
