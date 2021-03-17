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


rpc(Q) ->
    processo ! {self(), Q},
    receive
    {processo, Reply} ->
        Reply
    end.

loop() ->  
    receive
    {From, {init}} ->  
        From ! {processo, trabalho1:init()},
        loop();
        
    {From, {start}} -> 
        From ! {processo, trabalho1:start()},
        loop();
    {From, {reset}} ->
        From ! {processo, trabalho1:reset_tables()},
        loop();
    {From, {atum}} ->
        From ! {processo, trabalho1:atum()},
        loop();
    {From, {empr,Livro}} ->
        From ! {processo, trabalho1:emprestimos(Livro)},
        loop();
    {From, {req,Codigo}} ->
        From ! {processo, trabalho1:requesitado(Codigo)},
        loop();
    {From, {book,CC}} ->
        From ! {processo, trabalho1:livros(CC)},
        loop();
    {From, {code,Livro}} ->
        From ! {processo, trabalho1:codigos(Livro)},
        loop();
    {From, {nReq,CC}} ->
        From ! {processo, trabalho1:nRequisicoes(CC)},
        loop();
    {From, {add,CC,Codigo}} ->
        From ! {processo, trabalho1:add_req(CC,Codigo)},
        %io:format("Não existe!~n"),
        loop()



        
        
    end.

%% Abrir uma nova máquina virtual:
%% erl -name gandalf
%% Enviar mensagens entre máquinas diferentes:
%% erl -name bilbo
%% rpc:call('gandalf@MacBook.local',tabela1,store,[ana,porto]).
%%true
%% rpc:call('gandalf@MacBook.local',tabela1,lookup,[ana]).
%% {ok,porto}
