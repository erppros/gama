#Include "PROTHEUS.CH"
#Include "RPTDEF.CH"
#INCLUDE "TBICONN.CH"

/*/{Protheus.doc} FB601PCP
Relatórop de Ordesn de Produção com Status
@type function
@author Rogério Duarte
@since 29/01/2025
@version 1.0

/*/
User Function FB601PCP()

	//RpcSetType(3)
	//RpcSetEnv("01","0101")

	Private dDatade 	:= CTOD('')
	Private dDataate	:= CTOD('')
	Private cOPde 		:= SPACE(13)
	Private cOPate 		:= SPACE(13)
	Private nSitOP     := 0
	Private nCondOP     := 0
	Private cPerg       := PADR("FB601PCP",LEN(SX1->X1_GRUPO)," ")
	Private nPage  		:= 1
	Private _nLin       := 137
	Private _oPrinter

	Private cAliasSC2 	:= GetNextAlias()

	ValidPerg()
	If Pergunte(cPerg,.T.)
		cOPde   := MV_PAR01
		cOPate  := MV_PAR02
		dDatade := MV_PAR03
		dDataate:= MV_PAR04
		nCondOP := MV_PAR05
		nSitOP := MV_PAR06

		Processa({|| RunReport()})
	EndIf

Return


Static Function RunReport()

	Local cName 			:= ""
	Local lAdjustToLegacy   := .F.
	Local lDisableSetup     := .T.
	Local cPathPDF			:= "C:\TEMP\"



	cName           		:= "FB601PCP_" + DToS(MsDate()) + StrTran(Time(),":", "_")

	_oPrinter:= FWMSPrinter():New(cName, IMP_PDF, lAdjustToLegacy, cPathPDF,lDisableSetup, , , , , , .F.,)
	_oPrinter:lServer:= .T.
	_oPrinter:SetLandscape()

	SearchOP()
	If !( (cAliasSC2)->(EOF()) )
		RunPrint()
	Else
		MsgInfo("Dados nao encontrados!", "Não foram encontrados dados para impressão!")
	Endif

Return


Static Function SearchOP()

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Condicao Where para C2_STATUS                                ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cWhere01 := "%"
	If mv_par06 == 1
		cWhere01 += "'S'"
	ElseIf mv_par06 == 2
		cWhere01 += "'U'"
	ElseIf mv_par06 == 3
		cWhere01 += "'S','U','D','N',' '"
	EndIf
	cWhere01 += "%"

	cSpace     := Space(TamSx3("C2_DATRF")[1])
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Condicao Where para filtrar a condicao da OP(Em Aberto / Encerrada / Todas)³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	cWhere02 := "%"
	If MV_PAR05 == 1
		cWhere02 += " SC2.C2_DATRF =  '"+cSpace+"' AND "
	ElseIf MV_PAR05 == 2
		cWhere02 += " SC2.C2_DATRF <> '"+cSpace+"' AND "
	EndIf
	cWhere02 += "%"

	BeginSql Alias cAliasSC2

    SELECT SC2.C2_NUM, SC2.C2_ITEM, SC2.C2_SEQUEN, SC2.C2_EMISSAO, SC2.C2_ROTEIRO, 
        SC2.C2_PEDIDO, SC2.C2_PRODUTO, SC2.C2_QUANT, SC2.C2_DATPRI, SC2.C2_DATPRF
    FROM %table:SC2% SC2

    WHERE SC2.C2_FILIAL = %xFilial:SC2% AND
	  SC2.C2_NUM || SC2.C2_ITEM || SC2.C2_SEQUEN >= %Exp:cOPde% AND
	  SC2.C2_NUM || SC2.C2_ITEM || SC2.C2_SEQUEN <= %Exp:cOPate% AND
      SC2.C2_EMISSAO BETWEEN %Exp:DTOS(dDatade)% AND %Exp:DTOS(dDataate)% AND
	  SC2.C2_STATUS IN (%Exp:cWhere01%) AND
      %Exp:cWhere02% 
	  SC2.%NotDel%

	ORDER BY SC2.C2_NUM, SC2.C2_ITEM, SC2.C2_SEQUEN

	EndSql

	cQuery := GetLastQuery()[2]
	MemoWrite("c:\temp\queryfb601pcp.txt",cQuery)

Return

Static Function RunPrint()

	Private _oFont06  := TFont():New( "Arial" /*cName*/, /*uPar2*/, 06 /*nHeight*/, /*uPar4*/, .F. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont09B := TFont():New( "Arial" /*cName*/, /*uPar2*/, 09 /*nHeight*/, /*uPar4*/, .T. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont09  := TFont():New( "Arial" /*cName*/, /*uPar2*/, 09 /*nHeight*/, /*uPar4*/, .F. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont10B := TFont():New( "Arial" /*cName*/, /*uPar2*/, 10 /*nHeight*/, /*uPar4*/, .T. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont10  := TFont():New( "Arial" /*cName*/, /*uPar2*/, 10 /*nHeight*/, /*uPar4*/, .F. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont11B := TFont():New( "Arial" /*cName*/, /*uPar2*/, 11 /*nHeight*/, /*uPar4*/, .T. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont11  := TFont():New( "Arial" /*cName*/, /*uPar2*/, 11 /*nHeight*/, /*uPar4*/, .F. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont12B := TFont():New( "Arial" /*cName*/, /*uPar2*/, 12 /*nHeight*/, /*uPar4*/, .T. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont12  := TFont():New( "Arial" /*cName*/, /*uPar2*/, 12 /*nHeight*/, /*uPar4*/, .F. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont13B := TFont():New( "Arial" /*cName*/, /*uPar2*/, 13 /*nHeight*/, /*uPar4*/, .T. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont13  := TFont():New( "Arial" /*cName*/, /*uPar2*/, 13 /*nHeight*/, /*uPar4*/, .F. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont14B := TFont():New( "Arial" /*cName*/, /*uPar2*/, 14 /*nHeight*/, /*uPar4*/, .T. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont14  := TFont():New( "Arial" /*cName*/, /*uPar2*/, 14 /*nHeight*/, /*uPar4*/, .F. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont16B := TFont():New( "Arial" /*cName*/, /*uPar2*/, 16 /*nHeight*/, /*uPar4*/, .T. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont16  := TFont():New( "Arial" /*cName*/, /*uPar2*/, 16 /*nHeight*/, /*uPar4*/, .F. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont18B := TFont():New( "Arial" /*cName*/, /*uPar2*/, 18 /*nHeight*/, /*uPar4*/, .T. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont18  := TFont():New( "Arial" /*cName*/, /*uPar2*/, 18 /*nHeight*/, /*uPar4*/, .F. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont20B := TFont():New( "Arial" /*cName*/, /*uPar2*/, 20 /*nHeight*/, /*uPar4*/, .T. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont20  := TFont():New( "Arial" /*cName*/, /*uPar2*/, 20 /*nHeight*/, /*uPar4*/, .F. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont24B := TFont():New( "Arial" /*cName*/, /*uPar2*/, 24 /*nHeight*/, /*uPar4*/, .T. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont24  := TFont():New( "Arial" /*cName*/, /*uPar2*/, 24 /*nHeight*/, /*uPar4*/, .F. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )
	Private _oFont32B := TFont():New( "Arial" /*cName*/, /*uPar2*/, 32 /*nHeight*/, /*uPar4*/, .T. /*lBold*/, /*uPar6*/, /*uPar7*/, /*uPar8*/, /*uPar9*/, /*lUnderline*/, .F. /*lItalic*/ )

	PrintHead()


	While !( (cAliasSC2)->(EOF()) )

		ItensOP()

		(cAliasSC2)->(DBSKIP())
	EndDo

	_oPrinter:Preview()

Return

Static Function PrintHead()

	cCliLogo := "\system\logo_gama.png"

	//nLargura := _oPrinter:nHorzSize()


	_oPrinter:EndPage()
	_oPrinter:StartPage()

	//Logo
	_oPrinter:SayBitmap(015, 035, cCliLogo, 70, 70)

	_oPrinter:SayAlign(040, 010, "Relatório de OPs por Status", _oFont14B,820 ,, , 2, 0)

	_oPrinter:Line( 080, 20, 080,820)

	oBrush1 := TBrush():New( , CLR_HGRAY )
	_oPrinter:Fillrect( {82, 20, 98, 820 }, oBrush1, "-1")

	_oPrinter:SayAlign(082, 60, "CONDIÇÃO\STATUS = ", _oFont14B,820 ,, , 0, 0)

	//1-EM ABERTO 2-ENCERRADAS  3-TODAS
	if nCondOP == 1
		cCond:="EM ABERTO"
	elseif nCondOP == 2
		cCond:="ENCERRADA"
	else
		cCond:="TODAS"
	Endif

	// 1-SACRAMENTADAS 2-SUSPENSA 3-TODAS
	if nSitOP == 1
		cSitua:="SACRAMENTADAS"
	elseif nSitOP == 2
		cSitua:="SUSPENSA"
	else
		cSitua:="TODAS"
	Endif

	_oPrinter:SayAlign(082, 180, cCond+"\"+cSitua, _oFont14B,820 ,, CLR_RED, 0, 0)

	_oPrinter:Line( 100, 20, 100,820)

	_oPrinter:SayAlign(102, 20, "OP "			, _oFont09B,50 ,, , 0, 0)
	_oPrinter:SayAlign(102, 070, "Cliente "		, _oFont09B,100,, , 0, 0)
	_oPrinter:SayAlign(102, 170, "Pedido "		, _oFont09B,50 ,, , 0, 0)
	_oPrinter:SayAlign(102, 220, "Produto "		, _oFont09B,50 ,, , 0, 0)
	_oPrinter:SayAlign(102, 270, "Descrição "	, _oFont09B,230,, , 0, 0)
	_oPrinter:SayAlign(102, 500, "Total Pedido ", _oFont09B,60 ,, , 0, 0)
	_oPrinter:SayAlign(102, 560, "Valor do"		, _oFont09B,60 ,, , 0, 0)
	_oPrinter:SayAlign(112, 560, "Pedido"		, _oFont09B,60 ,, , 0, 0)
	_oPrinter:SayAlign(122, 560, "sem Impostos"	, _oFont09B,60 ,, , 0, 0)
	_oPrinter:SayAlign(102, 620, "Custo"		, _oFont09B,60 ,, , 0, 0)
	_oPrinter:SayAlign(112, 620, "de Compras"	, _oFont09B,60 ,, , 0, 0)
	_oPrinter:SayAlign(102, 680, "Diferenca(3)-(7)"	, _oFont09B,60 ,, , 0, 0)
	_oPrinter:SayAlign(102, 740, "NF"	, _oFont09B,60 ,, , 0, 0)
	_oPrinter:SayAlign(102, 790, "Dt. Fatur."	, _oFont09B,60 ,, , 0, 0)


	_oPrinter:Line( 135, 20, 135,820)


Return

Static Function ItensOP()
	Local nCusto := 0
	Local cNumOP := (cAliasSC2)->C2_NUM
	Local cItemOP := (cAliasSC2)->C2_ITEM
	Local cSequen := (cAliasSC2)->C2_SEQUEN
	Local cPedido := (cAliasSC2)->C2_PEDIDO
	Local cPedPai := ""

	DbSelectArea("SC5")
	DbSelectArea("SC6")
	DbSelectArea("SA1")
	DbSelectArea("SB1")

	SC5->(DbSetOrder(1))
	SA1->(DbSetOrder(1))
	SB1->(DbSetOrder(1))
	SC6->(DbSetOrder(2))

	fNextPage()

	_oPrinter:SayAlign(_nLin, 20, cNumOP + cItemOP + cSequen, _oFont09, 50, , , 0, 0)

	// Identificar se é uma OP filha e buscar o pedido da OP pai
	If cSequen > "001"  // Considera que a OP pai é a de sequência "001"
		cPedPai := fGetPedidoPai(cNumOP, cItemOP)
		If !Empty(cPedPai)
			cPedido := cPedPai
		EndIf
	EndIf

	If SC5->(MsSeek(FwxFilial("SC5") + cPedido))
		SA1->(MsSeek(FwxFilial("SA1") + SC5->C5_CLIENTE + SC5->C5_LOJACLI))
		SB1->(MsSeek(FwxFilial("SB1") + (cAliasSC2)->C2_PRODUTO))

		_oPrinter:SayAlign(_nLin, 070, AllTrim(SA1->A1_NOME), _oFont09, 100, , , 0, 0)
		_oPrinter:SayAlign(_nLin, 170, SC5->C5_NUM, _oFont09, 60, , , 0, 0)
		_oPrinter:SayAlign(_nLin, 220, (cAliasSC2)->C2_PRODUTO, _oFont09, 60, , , 0, 0)
		_oPrinter:SayAlign(_nLin, 270, AllTrim(SB1->B1_DESC), _oFont09, 230, , , 0, 0)
		_oPrinter:SayAlign(_nLin, 500, AllTrim(Transform(fTotalPedido(1), PesqPictQt("D2_TOTAL"))), _oFont09, 60, , , 0, 0)
		_oPrinter:SayAlign(_nLin, 560, AllTrim(Transform(fTotalPedido(2), PesqPictQt("D2_TOTAL"))), _oFont09, 60, , , 0, 0)

		nCusto := fCusto(cNumOP + cItemOP + cSequen, (cAliasSC2)->C2_PRODUTO)
		_oPrinter:SayAlign(_nLin, 620, AllTrim(Transform(nCusto, PesqPictQt("D2_TOTAL"))), _oFont09, 60, , , 0, 0)

		nDif := fTotalPedido(2) - nCusto
		_oPrinter:SayAlign(_nLin, 680, AllTrim(Transform(nDif, PesqPictQt("D2_TOTAL"))), _oFont09, 60, , , 0, 0)

		If SC6->(MsSeek(FwxFilial("SC6") + SB1->B1_COD + SC5->C5_NUM))
			_oPrinter:SayAlign(_nLin, 740, AllTrim(SC6->C6_NOTA), _oFont09, 60, , , 0, 0)
			_oPrinter:SayAlign(_nLin, 790, DToC(SC6->C6_DATFAT), _oFont09, 60, , , 0, 0)
		EndIf
	Else
		// Caso não encontre o pedido, exibir apenas os dados básicos da OP
		SB1->(MsSeek(FwxFilial("SB1") + (cAliasSC2)->C2_PRODUTO))
		_oPrinter:SayAlign(_nLin, 220, (cAliasSC2)->C2_PRODUTO, _oFont09, 60, , , 0, 0)
		_oPrinter:SayAlign(_nLin, 270, AllTrim(SB1->B1_DESC), _oFont09, 230, , , 0, 0)
		nCusto := fCusto(cNumOP + cItemOP + cSequen,(cAliasSC2)->C2_PRODUTO)
		_oPrinter:SayAlign(_nLin, 620, AllTrim(Transform(nCusto, PesqPictQt("D2_TOTAL"))), _oFont09, 60, , , 0, 0)
	EndIf

	_nLin += 10
Return
Static Function fGetPedidoPai(cNumOP, cItemOP)
	Local cPedidoPai := ""
	Local cAliasTmp := GetNextAlias()

	BeginSql Alias cAliasTmp
        SELECT C2_PEDIDO, C2_PRODUTO
        FROM %table:SC2% SC2
        WHERE SC2.C2_FILIAL = %xFilial:SC2%
          AND SC2.C2_NUM = %Exp:cNumOP%
          AND SC2.C2_ITEM = %Exp:cItemOP%
          AND SC2.C2_SEQUEN = '001'
          AND SC2.%NotDel%
	EndSql

	If !(cAliasTmp)->(Eof())
		cPedidoPai := (cAliasTmp)->C2_PEDIDO
	EndIf

	(cAliasTmp)->(DbCloseArea())
Return cPedidoPai

Static Function fCusto(cOp,cProduto)
	nValor := 0

	BeginSql Alias "SD3TMP"
		SELECT D3_CUSTO1
		FROM %TABLE:SD3% SD3
		WHERE D3_OP = %EXP:cop%
		AND D3_COD = %EXP:cProduto%
		AND D3_TM = '010'
		AND SD3.%NOTDEL%
	endSQL
	nValor := SD3TMP->D3_CUSTO1

	SD3TMP->(DBCLOSEAREA())

Return nValor

Static Function fNextPage()

	if _nLin >= 577
		_oPrinter:EndPage()
		_oPrinter:StartPage()
		_nLin := 20
	Endif

Return

/*/{Protheus.doc} fTotalPedido
	Fnção para calcular o Valor Total do Pedido
	@type  Static Function
	@author user
	@since 03/02/2025
	@version version
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example
	(examples)
	@see (links_or_references)
/*/
Static Function fTotalPedido(nTipo)

	Local nvalor 	:= 0


	BeginSql Alias "SC6TMP"
	
		SELECT C6_NUM, SUM(C6_VALOR) AS TOTAL, SUM(C6_ZTOTIMP) AS TOTALIMP
		FROM %TABLE:SC6% SC6
		WHERE SC6.%NOTDEL%
		AND C6_FILIAL 	= %EXP:SC5->C5_FILIAL%
		AND C6_NUM 		= %EXP:SC5->C5_NUM%
		AND C6_CLI      = %EXP:SC5->C5_CLIENTE%
		AND C6_LOJA     = %EXP:SC5->C5_LOJACLI%
		GROUP BY C6_NUM
		ORDER BY C6_NUM

	endSQL

	IF nTipo == 1
		nValor := SC6TMP->TOTALIMP
	ELSEIF nTipo == 2
		nValor := SC6TMP->TOTAL
	EndIf

	SC6TMP->(DBCLOSEAREA())

Return nValor


Static Function ValidPerg()
	Local _aRegs  := {}
	Local _aHelps := {}
	Local _i      := 0
	Local _j      := 0
	_aRegs := {}

//                 GRUPO  ORDEM PERGUNT           	     PERSPA 				PERENG 			VARIAVL  TIPO 	TAM 		  DEC PRESEL 	GSC  VALID           VAR01       DEF01         DEFSPA1 DEFENG1 CNT01 VAR02 DEF02        DEFSPA2 DEFENG2 CNT02 VAR03 DEF03    DEFSPA3 DEFENG3 CNT03 VAR04 DEF04 DEFSPA4 DEFENG4 CNT04 VAR05 DEF05 DEFSPA5 DEFENG5 CNT05 F3     GRPSXG
	AADD (_aRegs, {cPerg, "01", "Da OP ?            	", "                ", "                ",  "mv_ch1", "C", 11,  			0,  0,		"G", "", 			"mv_par01", "",				"",    "",		"",		"",	"",				"",	"",	     "",	"", "",         "",     "", 	"",		"",   		"",				"",				"",		"",		"",			"",   		"",     		 "",	"","SC2"   , ""})
	AADD (_aRegs, {cPerg, "02", "Ate a OP ?         	", "        		", "          		",  "mv_ch2", "C", 11, 				0,  0, 		"G", "", 			"mv_par02", "",				"",    "",		"",		"",	"",				"",	"",	     "",	"", "",      	"",     "", 	"",		"",   		"",				"",				"",		"",		"",			"",  		"",    			 "",	"","SC2"   , ""})
	AADD (_aRegs, {cPerg, "03", "Da Data de Emissao ?   ", "     			", "    			",  "mv_ch3", "D", 08,				0,  0,		"G", "", 			"mv_par03", "",				"",    "",		"",		"",	"",				"",	"",	     "",	"", "",      	"",     "",		"",		"",   		"",				"",				"",		"",		"",			"",  		"",     		 "",	"",""  	   , ""})
	AADD (_aRegs, {cPerg, "04", "Ate a Data de Emissao ?", "     			", "       			",  "mv_ch4", "D", 08, 				0,  0,		"G", "", 			"mv_par04",	"",				"",    "",		"",		"",	"",				"",	"",	     "",	"", "",     	"",     "", 	"",		"",   		"",				"",				"",		"",		"",			"",  		"",    			 "",	"",""  	   , ""})
	AADD (_aRegs, {cPerg, "05", "Condicao da OP ?   	", "				", "				",  "mv_ch5", "N", 01, 				0,  3,		"C", "", 			"mv_par05", "Em Aberto",    "",    "",		"",     "",	"Encerrada",	"",	"",	     "",	"", "Todas",    "",		"",		"",		"",   		"",				"",             "",		"",		"",			"",			"",              "",	"",""      , ""})
	AADD (_aRegs, {cPerg, "06", "Situacao da OP ?   	", "				", "				",  "mv_ch6", "N", 01, 				0,  3,		"C", "", 			"mv_par06", "Sacramentada", "",    "",		"",     "",	"Suspensa",		"",	"",	     "",	"", "Todas",    "",		"",		"",		"",   		"",				"",             "",		"",		"",			"",			"",              "",	"",""      , ""})

// Definicao de textos de help (versao 7.10 em diante): uma array para cada linha.
	_aHelps = {}

	DbSelectArea ("SX1")
	DbSetOrder (1)
	For _i := 1 to Len (_aRegs)
		If ! DbSeek (cPerg + _aRegs [_i, 2])
			RecLock("SX1", .T.)
		Else
			RecLock("SX1", .F.)
		Endif
		For _j := 1 to FCount ()
// Campos CNT nao sao gravados para preservar conteudo anterior.
			If _j <= Len (_aRegs [_i]) .and. left (fieldname (_j), 6) != "X1_CNT" .and. fieldname (_j) != "X1_PRESEL"
				FieldPut(_j, _aRegs [_i, _j])
			Endif
		Next
		MsUnlock()
	Next
Return
