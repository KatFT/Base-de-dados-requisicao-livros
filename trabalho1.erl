-module(trabalho1).

-compile(export_all).
-import(lists, [foreach/2]).


%Essa estrutura deve guardar requisições que são pares 
%de identificadores de pessoas e de livros requisitados por essa pessoa.

%INFORMACAO RELATIVA A PESSOA:
%número do cartão de cidadão, nome, morada e telefone
%informaçao relativa a livros
%código do livro, nome do livro e autores

%LOOKUP
%-livros: dado um número de cartão de cidadão determina 
%a lista de livros requisitada por essa pessoa;
%-empréstimos: dado o título de um livro determina a lista de 
%pessoas que requisitaram esse livro;
%-requisitado: dado o código de um livro determina se o livro 
%está requisitado (retorna um booleano);
%-códigos: dado o título de um livro retorna a lista de códigos 
%de livros com esse título;
%-numRequisicões: dado um número de cartão de cidadão retorna 
%o número de livros requisitados por essa pessoa;

%UPDATE
%-requisição: dados os dados de uma pessoa e o código de um 
%livro acrescenta o par {pessoa, livro} à base de dados;
%-retorno: dado um número de cartão de cidadão e o código de
% um livro retira o par respectivo da base de dados;

%start() -> register(simpleTable, spawn(fun() -> loop() end))
			
%de momento acho q n preciso do record de pessoas, so o livro e o requesiçoes
%
-include_lib("stdlib/include/qlc.hrl").
-record(pessoa, {cartaoC ,nome, morada, telefone}).
-record(livro, {codigo, nLivro, autores}).
-record(req, {cartaoC, nome, morada, telefone, codigo, nLivro,autores}).


%inicializar as tabelas (so e preciso fazer isto uma vez)
init() ->
	mnesia:create_schema([node()]),
	mnesia:start(),
	mnesia:create_table(pessoa,[{type, bag},{attributes, record_info(fields, pessoa)}]),
	mnesia:create_table(livro, [{type, bag},{attributes, record_info(fields, livro)}]),
	mnesia:create_table(req,   [{type, bag},{attributes, record_info(fields, req)}]),
	mnesia:stop().

%esperar pelas tabelas
start() ->
	mnesia:start(),
	mnesia:wait_for_tables([livro,req,pessoa],20000).

%exemplos de tabelas
tabelas() ->
	[%tabela dos livros
	{livro, 1234, "principezinho", "atum"},
	{livro, 32, "os maias", "eça de queiros"},
	{livro, 42, "o sentido da vida", "pedro ribeiro"},
	%tabela das requisiçoes
	{req, 12,"a","aaa",121212121,1111,"q","qwee"},
	%tabela das pessoas
	{pessoa, 3006, "Catarina Teixeira", "rua atum", 11234},
	{pessoa, 3444, "Aberto barroso","rua dos adultos", 334343},
	{pessoa, 22222, "Almira Atum", "RRRRRUUUUAAAA",9191919}
	].

do(Q) ->
    F = fun() -> qlc:e(Q) end,
    {atomic, Val} = mnesia:transaction(F),
    Val.
reset_tables() ->
    mnesia:clear_table(livro),
    mnesia:clear_table(req),
    F = fun() ->
		    foreach(fun mnesia:write/1, tabelas())
	  end,
    mnesia:transaction(F).

aaa(Codigo) ->
	do(qlc:q([X || X <- mnesia:table(livro),
		X#livro.codigo=:=Codigo])).
a(show) ->
	do(qlc:q([X|| X<-mnesia:table(req)])).


add(Codigo, Livro,Autor) ->
	Row=#livro{codigo=Codigo,nLivro=Livro,autores=Autor},
	F= fun() ->
		mnesia:write(Row)
	end,
	mnesia:transaction(F).

%adicionar pessoa a lista de requesiçoes
%a partir da inf da pessoa e codigo do livro
add_req(CC, Nome, Morada, Telefone, Codigo) ->
	
	
	F= fun() ->
		%vamos buscar qql informaçao q ha com aquele codigo
		%Query= qlc:q([X || X <- mnesia:table(livro),
		%		X#livro.codigo=:=Codigo]),
		
		[X] = mnesia:read({livro,Codigo}),
		
		if Codigo =:= X#livro.codigo ->
			NCodigo= X#livro.codigo,
			NLivro= X#livro.nLivro,
			NAutores= X#livro.autores,
			%isto vai inserir na tabela req
		Row= #req{cartaoC=CC, nome=Nome, morada=Morada, 
			telefone=Telefone,codigo=NCodigo,nLivro=NLivro,autores=NAutores},
		mnesia:write(Row)

		end
		

	end,
	mnesia:transaction(F).


%vai retornar o livro

