-module(servidor).
-compile(export_all).

%iniciar servidor
starter() -> register(processo, spawn(fun() -> loop() end)).
%--------------------------------
%iniciar as tabelas no cliente

inicia() -> rpc({inicia}).

start() -> rpc({start}).

reset() -> rpc({reset}).



%--------------------------------
% Mensagens de lookup

empr(Livro) -> rpc({empr,Livro}).

req(Codigo) -> rpc({req,Codigo}).

book(CC) -> rpc({book,CC}).

code(Livro) -> rpc({code,Livro}).

nReq(CC) -> rpc({nReq,CC}).
%------------------------------
% Mensagens de update

add(CC,Codigo) -> rpc({add,CC,Codigo}).

ret(CC,Codigo) -> rpc({ret,CC,Codigo}).

%---------------------------------
%FUNCOES EXTRA

tabela() -> rpc({tabela}).

treq() -> rpc({treq}).

tpess() -> rpc({tpess}).

tlivro() -> rpc({tlivro}).

addp(CC,Nome,Morada,Telefone) -> rpc({addp,CC,Nome,Morada,Telefone}).

addl(Codigo, Livro, Autor) -> rpc({addl,Codigo,Livro,Autor}).

%------------------------------

stop() -> rpc({stop}),ok.

rpc(Q) ->
    Ref=make_ref(),
    processo ! {self(), Ref, Q},
    receive
    {processo, Ref, Reply} ->
        Reply
    end.

loop() ->  
    receive
    {From,Ref, {inicia}} ->  
        From ! {processo, Ref, baseDados:init()},
        loop();
    {From,Ref, {start}} -> 
        From ! {processo, Ref, baseDados:start()},
        loop();
    {From,Ref, {reset}} ->
        From ! {processo, Ref, baseDados:reset_tables()},
        loop();
    {From,Ref, {tabela}} ->  
        From ! {processo, Ref, baseDados:tabelas()},
        loop();
    {From, Ref,{treq}} ->
        From ! {processo, Ref, baseDados:tab_req()},
        loop();
    {From, Ref,{tpess}} ->
        From ! {processo, Ref, baseDados:tab_pessoa()},
        loop();
    {From, Ref,{tlivro}} ->
        From ! {processo, Ref, baseDados:tab_livro()},
        loop();
    {From, Ref,{addp,CC,Nome,Morada,Telefone}} ->
        From ! {processo, Ref, baseDados:add_pessoa(CC,Nome,Morada,Telefone)},
        loop();
    {From, Ref,{addl,Codigo,Livro,Autor}} ->
        From ! {processo, Ref, baseDados:add_livro(Codigo,Livro,Autor)},
        loop();
    {From,Ref, {empr,Livro}} ->
        From ! {processo, Ref, baseDados:emprestimos(Livro)},
        loop();
    {From,Ref, {req,Codigo}} ->
        From ! {processo, Ref, baseDados:requesitado(Codigo)},
        loop();
    {From, Ref,{book,CC}} ->
        From ! {processo, Ref, baseDados:livros(CC)},
        loop();
    {From, Ref,{code,Livro}} ->
        From ! {processo, Ref, baseDados:codigos(Livro)},
        loop();
    {From,Ref, {nReq,CC}} ->
        From ! {processo, Ref, baseDados:nRequisicoes(CC)},
        loop();
    {From,Ref, {add,CC,Codigo}} ->
        From ! {processo, Ref, baseDados:add_req(CC,Codigo)},
        %io:format("Não existe!~n"),
        loop();
    {From,Ref, {ret,CC,Codigo}} ->
        From ! {processo, Ref, baseDados:retorno(CC,Codigo)},
        loop();
    %{stop,From,Ref} ->
    {From,Ref, {stop}} ->
        From ! {processo, Ref,ok},
        io:format("SERVIDOR FOI FECHADO!~n"),
        ok
    end.

