all:
	ocamlbuild -tags debug,strict-sequence -libs str,unix test1.native

debug:
	ocamlbuild -tags debug,strict-sequence -libs str,unix test1.byte

clean:
	ocamlbuild -clean

test:	| all
	OCAMLRUNPARAM=b ./test1.native
