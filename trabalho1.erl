-module(trabalho1).
-author("Catarina Teixeira").
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

-include_lib("stdlib/include/qlc.hrl").

%--------------------------------------%
%req basta ter o cartaoC da pessoa e codigo do livro... 
%as outras informações podes ir buscar a pessoa (dado o cartaoC) e a
% livro (dado o codigo)
-record(pessoa, {cartaoC ,nome, morada, telefone}).
-record(livro, {codigo, nLivro, autores}).
-record(req, {cC, cod}).


%inicializar as tabelas (so e preciso fazer isto uma vez)
init() ->
	mnesia:create_schema([node()]),
	mnesia:start(),
	mnesia:create_table(pessoa,[{attributes, record_info(fields, pessoa)}]),
	mnesia:create_table(livro, [{attributes, record_info(fields, livro)}]),
	mnesia:create_table(req,   [{type,bag},{attributes, record_info(fields, req)}]),
	mnesia:stop(),ok.

%esperar pelas tabelas
start() ->
	mnesia:start(),
	mnesia:wait_for_tables([livro,req,pessoa],20000).

%exemplos de tabelas
tabelas() ->
	[%tabela dos livros
	{livro, "1234", "principezinho", "atum"},
	{livro, "32", "os maias", "eça de queiros"},
	{livro, "42", "o sentido da vida", "pedro ribeiro"},
	{livro, "33", "os maias", "eça de queiros"},

	%tabela das requisiçoes
	{req, 3006, "32"},
	{req, 3444,"1234"},
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
    mnesia:clear_table(pessoa),
    F = fun() ->
		    foreach(fun mnesia:write/1, tabelas())
	  end,
    mnesia:transaction(F).

%----------------------------------------------%
%funçoes de debug
aaa(Codigo) ->
	do(qlc:q([X || X <- mnesia:table(livro),
		X#livro.codigo=:=Codigo])).
%	
atum() ->
	do(qlc:q([X|| X<-mnesia:table(req)])).

%-----------------------------------------------%

%--------------------------------%
%---------lookup-----------------%
%--------------------------------%

%------------emprestimo---------------%
%- empréstimos: dado o título de um livro determina 
%a lista de pessoas que requisitaram esse livro;

%SQL equivalent
%SELECT pessoa
%FROM pessoa, req,livro
%WHERE req.codigo=livro.codigo 
%AND pessoa.cartaoC=req.cC

emprestimos(Livro) ->
	do(qlc:q([X || X <-mnesia:table(pessoa),
		A <- mnesia:table(req),B<-mnesia:table(livro),
		B#livro.codigo=:= A#req.cod,
		B#livro.nLivro=:=Livro,
		X#pessoa.cartaoC=:= A#req.cC])).


%--------------requisitado-----------------%
%- requisitado: dado o código de um livro determina 
%se o livro está requisitado (retorna um booleano);

%Versao mt feia
%requesitado(Codigo) ->
%	F = fun()->
%		qlc:e(qlc:q([A ||
%		A<-mnesia:table(req), A#req.cod=:=Codigo])),
%		io:format("True ~n")
%	end,
%	 {atomic, Val} = mnesia:transaction(F),
%   Val.

requesitado(Codigo) ->
	Q= do(qlc:q([A ||
		A<-mnesia:table(req), A#req.cod=:=Codigo])),
	W=length(Q),
		if W >0 -> 
			'true';
			true-> 'false'
		end.

%-------------livros--------------------%
%livros: dado um número de cartão de cidadão determina 
%a lista de livros requisitada por essa pessoa;

%SQL equivalent
%SELECT livro.nLivro
%FROM livro,req
%WHERE req.cod=livro.codigo
%AND cc=req.cc

livros(CC) ->
	do(qlc:q([X || X<-mnesia:table(livro),
		A<-mnesia:table(req),
		A#req.cC=:=CC, X#livro.codigo=:=A#req.cod])).
%-------------------codigos------------------%
%códigos: dado o título de um livro retorna a lista de 
%códigos de livros com esse título;

%SQL equivalent
%SELECT livro.nLivro
%FROM livro
%WHERE livro.codigo=livro

codigos(Livro) ->
	do(qlc:q([X#livro.codigo || X<-mnesia:table(livro),
		X#livro.nLivro=:=Livro])).

%--------------nRequisiçoes-----------------------%
%numRequisicões: dado um número de cartão de cidadão retorna
% o número de livros requisitados por essa pessoa;


nRequisicoes(CC) ->
	Q=do(qlc:q([X#req.cod || X<-mnesia:table(req),
		A<-mnesia:table(pessoa), A#pessoa.cartaoC=:=X#req.cC,
		A#pessoa.cartaoC=:=CC])),
	length(Q).



%-------------------------------------------------------------%

%---------------------------------%
%-----------update----------------%
%---------------------------------%

%------adicionar requesiçoes------%
%adicionar pessoa a lista de requesiçoes
%a partir da inf da pessoa e codigo do livro
%Assumi que a pessoa já existia,
%verifica se o codigo do livro existe na tabela livros
%vai escrever na tabela req, se nao imprime que nao existe codigo
add_req(CC,Codigo) ->
	Q=length(do(qlc:q([X|| X<-mnesia:table(livro),
		X#livro.codigo=:=Codigo]))),
	A= length(do(qlc:q([X|| X<-mnesia:table(pessoa),
		X#pessoa.cartaoC=:=CC]))),	
	F= fun() ->
		if Q>0  ->
			if A>0 ->
				mnesia:write(#req{cC=CC, cod=Codigo});
				true -> io:format("Não existe a pessoa!~n")
			end;
			
			true ->  io:format("Não existe o código!~n")	
		end
	end,
	mnesia:transaction(F).
	
%-----------------------------------%
%-----------retorno-----------------%

%dado um número de cartão de cidadão e o código 
%de um livro retira o par respectivo da base de dados
%verifica se o codigo do livro existe na tabela livros
%vai retirar da tabela req, senao imprime que n existe codigo
retorno(CC,Codigo) ->
	Q=length(do(qlc:q([X|| X<-mnesia:table(livro),
		X#livro.codigo=:=Codigo]))),
	A= length(do(qlc:q([X|| X<-mnesia:table(pessoa),
		X#pessoa.cartaoC=:=CC]))),
	F= fun() ->
		if Q>0 ->
			if A>0 ->
				mnesia:delete_object(#req{cC=CC, cod=Codigo});
				true-> io:format("Não existe a pessoa!~n")
			end;

			true-> io:format("Não existe o código!~n")
		end
	end,
	mnesia:transaction(F).
%--------------------------------------%

