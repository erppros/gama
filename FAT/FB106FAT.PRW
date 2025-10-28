/*/{Protheus.doc} FB106FAT
Gatilho impostos
@type user function
@author user
@since 10/04/2025
@version version
@param param_name, param_type, param_descr
@return return_var, return_type, return_description
@example
(examples)
@see (links_or_references)
/*/
User Function FB106FAT(nOpc)

	Local aArea     := GetArea()        //Armazena o ambiente ativo para restaurar ao fim do processo
	Local cTipo 	:= ""
	local lProspect := .F.


	Local nPrcLista	:= 0
	Local nQtdPeso 	:= 0
	Local nItem		:= 0
	Local nAcresFin	:= 0

	Local nDesconto	:= 0
	Local nValMerc	:= 0

	Local nAliqICM  := 0
	Local nValICM   := 0
	Local nAliqPis  := 0
	Local nValPIS   := 0
	Local nAliqCof 	:= 0
	local nValCof   := 0
	Local nAliPISCOF:= 0
	Local nValPISCOF:= 0
	Local nAliqISS  := 0
	Local nValISS   := 0
	Local aDados 	:= {}
	Local nRet      := 0

	Local nX		:= 0



	dbSelectArea("SA1")
	dbSetOrder(1)
	MsSeek(xFilial("SA1")+If(!Empty(M->CJ_CLIENT),M->CJ_CLIENT,M->CJ_CLIENTE)+M->CJ_LOJAENT)

	dbSelectArea("SE4")
	dbSetOrder(1)
	MsSeek(xFilial("SE4")+M->CJ_CONDPAG)

	If !Empty(M->CJ_PROSPE) .And. !Empty(M->CJ_LOJPRO)
		cTipo := Posicione("SUS",1,xFilial("SUS") + M->CJ_PROSPE + M->CJ_LOJPRO,"US_TIPO")
		lProspect := .T.
	Endif

	MaFisSave()
	MaFisEnd()

	//inicializa a funcao fiscal
	//MaFisIni(   SCJ->CJ_CLIENTE,SCJ->CJ_LOJA,"C","N",,,,,,,,,,,,SCJ->CJ_CLIENTE,SCJ->CJ_LOJA)
	MaFisIni(Iif(Empty(M->CJ_CLIENT),M->CJ_CLIENTE,M->CJ_CLIENT),;// 1-Codigo Cliente/Fornecedor
	M->CJ_LOJAENT,;     // 2-Loja do Cliente/Fornecedor
	"C",;               // 3-C:Cliente , F:Fornecedor
	"N",;               // 4-Tipo da NF
	Iif(lProspect,cTipo,SA1->A1_TIPO),;     // 5-Tipo do Cliente/Fornecedor
	Nil,;
	Nil,;
	Nil,;
	Nil,;
	"MATA461",;
	Nil,;
	Nil,;
	IiF(lProspect,M->CJ_PROSPE+M->CJ_LOJPRO,""))


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Posiciona Registros                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	SB1->(dbSetOrder(1))
	If SB1->(MsSeek(xFilial("SB1")+TMP1->CK_PRODUTO))
		nQtdPeso := TMP1->CK_QTDVEN*SB1->B1_PESO
	EndIf
	SB2->(dbSetOrder(1))
	SB2->(MsSeek(xFilial("SB2")+TMP1->CK_PRODUTO+TMP1->CK_LOCAL))
	SF4->(dbSetOrder(1))
	SF4->(MsSeek(xFilial("SF4")+TMP1->CK_TES))
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Calcula o preco de lista                     ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	nValMerc  := TMP1->CK_VALOR
	nPrcLista := TMP1->CK_PRUNIT
	nQtdPeso  := 0
	nItem++
	If ( nPrcLista == 0 )
		nPrcLista := A410Arred(nValMerc/TMP1->CK_QTDVEN,"CK_PRCVEN")
	EndIf
	nAcresFin := A410Arred(TMP1->CK_PRCVEN*SE4->E4_ACRSFIN/100,"D2_PRCVEN")
	nValMerc  += A410Arred(nAcresFin*TMP1->CK_QTDVEN,"D2_TOTAL")
	nDesconto := A410Arred(nPrcLista*TMP1->CK_QTDVEN,"D2_DESCON")-nValMerc
	nDesconto := IIf(nDesconto==0,TMP1->CK_VALDESC,nDesconto)
	nDesconto := Max(0,nDesconto)
	nPrcLista += nAcresFin

	//Para os outros paises, este tratamento e feito no programas que calculam os impostos.
	If cPaisLoc=="BRA"
		nValMerc  += nDesconto
	Endif


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Agrega os itens para a funcao fiscal         ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	MaFisAdd(TMP1->CK_PRODUTO,;   	// 1-Codigo do Produto ( Obrigatorio )
	TMP1->CK_TES,;	   	// 2-Codigo do TES ( Opcional )
	TMP1->CK_QTDVEN,;  	// 3-Quantidade ( Obrigatorio )
	nPrcLista,;		  	// 4-Preco Unitario ( Obrigatorio )
	nDesconto,; 	// 5-Valor do Desconto ( Opcional )
	"",;	   			// 6-Numero da NF Original ( Devolucao/Benef )
	"",;				// 7-Serie da NF Original ( Devolucao/Benef )
	0,;					// 8-RecNo da NF Original no arq SD1/SD2
	0,;					// 9-Valor do Frete do Item ( Opcional )
	0,;					// 10-Valor da Despesa do item ( Opcional )
	0,;					// 11-Valor do Seguro do item ( Opcional )
	0,;					// 12-Valor do Frete Autonomo ( Opcional )
	nValMerc,;			// 13-Valor da Mercadoria ( Obrigatorio )
	0)					// 14-Valor da Embalagem ( Opiconal )

	SB1->(dbSetOrder(1))
	If SB1->(MsSeek(xFilial("SB1")+TMP1->CK_PRODUTO))
		nQtdPeso := TMP1->CK_QTDVEN*SB1->B1_PESO
	Endif

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Calculo do ISS                               ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If SA1->A1_INCISS == "N"
		If ( SF4->F4_ISS=="S" )
			nPrcLista := a410Arred(nPrcLista/(1-(MaAliqISS(nItem)/100)),"D2_PRCVEN")
			nValMerc  := a410Arred(nValMerc/(1-(MaAliqISS(nItem)/100)),"D2_PRCVEN")
			MaFisAlt("IT_PRCUNI",nPrcLista,nItem)
			MaFisAlt("IT_VALMERC",nValMerc,nItem)
		EndIf
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³Altera peso para calcular frete              ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	MaFisAlt("IT_PESO",nQtdPeso,nItem)
	MaFisAlt("IT_PRCUNI",nPrcLista,nItem)
	MaFisAlt("IT_VALMERC",nValMerc,nItem)



	aImp := MaFisRodape(1,Nil,,,Nil,.T.,,,,,,,,,,,,,,,.T.)

	For nX:= 1 to Len(aImp)
		If aImp[nX,1]=="ICM"
			nAliqICM := aImp[nX,4]
			nValICM  := aImp[nX,5]
		ElseIf aImp[nX,1]=="PS2
			nAliqPIS := aImp[nX,4]
			nValPIS  := aImp[nX,5]
		ElseIf aImp[nX,1]=="CF2
			nAliqCOF := aImp[nX,4]
			nValCOF  := aImp[nX,5]
		ElseIf aImp[nX,1]=="ISS
			nAliqIss := aImp[nX,4]
			nValISS  := aImp[nX,5]
		ENDIF
	Next

	AAdd(aDados,{nValICM,nValPISCOF,nValISS})

	if Len(aDados) > 1
		nValICM 	:= aDados[nItem,1] - aDados[nItem-1,1]
		nValPISCOF 	:= aDados[nItem,2] - aDados[nItem-1,2]
		nValISS		:= aDados[nItem,3] - aDados[nItem-1,3]
	Endif


	nAliPISCOF := SA1->A1_ZTXPIS + SA1->A1_ZTXCOF
	nValPISCOF := (TMP1->CK_VALOR - nValICM) * (nAliPISCOF/100)


	TMP1->CK_ZALICMS := nAliqICM		//MaFisRet(nItem,"IT_ALIQICM")
	TMP1->CK_ALPISCO := nAliPISCOF	//(nItem,"IT_ALIQPIS")	+ MaFisRet(nItem,"IT_ALIQCOF")
	TMP1->CK_ZALISSQ := nAliqIss		//MaFisRet(nItem,"IT_ALIQISS")

	TMP1->CK_ZICMS   := nValICM		//MaFisRet(nItem,"IT_VALICM") //SCK->CK_VALOR * (SCK->CK_ZALICMS/100)
	TMP1->CK_ZPISCOF := nValPISCOF	//MaFisRet(nItem,"IT_VALPIS") + MaFisRet(nItem,"IT_VALCOF") //SCK->CK_VALOR * (SCK->CK_ALPISCO/100)
	TMP1->CK_ZISSQN  := nValISS		//MaFisRet(nItem,"IT_VALISS") //SCK->CK_VALOR * (SCK->CK_ZALISSQ/100)

	TMP1->CK_ZTOTIMP := TMP1->CK_VALOR - TMP1->CK_ZICMS - TMP1->CK_ZPISCOF - TMP1->CK_ZISSQN


	RestArea(aArea) //Restaura o ambiente ativo no início da chamada
	if nOpc == 1
		nRet := M->CK_QTDVEN
	elseif nOpc==2
		nRet := M->CK_ZPRCVEN
	elseif nOpc==3
		nRet := M->CK_PRCVEN
	else
		nRet := M->CK_VALOR
	endif

Return nRet
