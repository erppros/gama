#INCLUDE 'PROTHEUS.CH'
#INCLUDE "FWMVCDEF.CH"
#Include "Totvs.ch"
#Include "topconn.ch"
#INCLUDE "TBICONN.CH"


User Function M415GRV()

	Local aArea     := GetArea()        //Armazena o ambiente ativo para restaurar ao fim do processo
	Local nOpcao    := PARAMIXB[1]      //Número da Opção (1 - Inclusão / 2 - Alteração / 3 - Exclusão)
	Local cQrySCK   := ""               //Query
	Local cAliasSCK := GetNextAlias()   //Criação de tabelas temporárias
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

	Local nX		:= 0
	//Local nTotal    := 0                //Valor Total do orçamento


	If nOpcao == 1 .Or. nOpcao  == 2 .AND. !FwIsInCallStack('U_FB001FAT')//Inclusao ou Alteração

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

		//------------------------------------------
		// Query da tabela SCK - Itens de Orçamento
		//------------------------------------------
		cQrySCK := " SELECT CK_FILIAL, CK_NUM, CK_VALOR, CK_ITEM, CK_PRODUTO, CK_TES, CK_QTDVEN, CK_PRCVEN, CK_PRUNIT,CK_VALDESC,CK_LOCAL "
		cQrySCK += " FROM "+RetSqlName("SCK")
		cQrySCK += " WHERE CK_FILIAL = '"+ SCJ->CJ_FILIAL +"' "
		cQrySCK += " AND CK_NUM = '"+ SCJ->CJ_NUM +"' "
		cQrySCK += " AND D_E_L_E_T_=' ' "
		cQrySCK := ChangeQuery(cQrySCK)

		dbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQrySCK),cAliasSCK,.T.,.T.)

		While (cAliasSCK)->(!Eof()) .And. SCK->CK_FILIAL + SCK->CK_NUM == (cAliasSCK)->CK_FILIAL + (cAliasSCK)->CK_NUM

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Posiciona Registros                          ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			SB1->(dbSetOrder(1))
			If SB1->(MsSeek(xFilial("SB1")+(cAliasSCK)->CK_PRODUTO))
				nQtdPeso := (cAliasSCK)->CK_QTDVEN*SB1->B1_PESO
			EndIf
			SB2->(dbSetOrder(1))
			SB2->(MsSeek(xFilial("SB2")+(cAliasSCK)->CK_PRODUTO+(cAliasSCK)->CK_LOCAL))
			SF4->(dbSetOrder(1))
			SF4->(MsSeek(xFilial("SF4")+(cAliasSCK)->CK_TES))
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Calcula o preco de lista                     ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			nValMerc  := (cAliasSCK)->CK_VALOR
			nPrcLista := (cAliasSCK)->CK_PRUNIT
			nQtdPeso  := 0
			nItem++
			If ( nPrcLista == 0 )
				nPrcLista := A410Arred(nValMerc/(cAliasSCK)->CK_QTDVEN,"CK_PRCVEN")
			EndIf
			nAcresFin := A410Arred((cAliasSCK)->CK_PRCVEN*SE4->E4_ACRSFIN/100,"D2_PRCVEN")
			nValMerc  += A410Arred(nAcresFin*(cAliasSCK)->CK_QTDVEN,"D2_TOTAL")
			nDesconto := A410Arred(nPrcLista*(cAliasSCK)->CK_QTDVEN,"D2_DESCON")-nValMerc
			nDesconto := IIf(nDesconto==0,(cAliasSCK)->CK_VALDESC,nDesconto)
			nDesconto := Max(0,nDesconto)
			nPrcLista += nAcresFin

			//Para os outros paises, este tratamento e feito no programas que calculam os impostos.
			If cPaisLoc=="BRA"
				nValMerc  += nDesconto
			Endif

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Agrega os itens para a funcao fiscal         ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			MaFisAdd((cAliasSCK)->CK_PRODUTO,;   	// 1-Codigo do Produto ( Obrigatorio )
			(cAliasSCK)->CK_TES,;	   	// 2-Codigo do TES ( Opcional )
			(cAliasSCK)->CK_QTDVEN,;  	// 3-Quantidade ( Obrigatorio )
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
			If SB1->(MsSeek(xFilial("SB1")+(cAliasSCK)->CK_PRODUTO))
				nQtdPeso := (cAliasSCK)->CK_QTDVEN*SB1->B1_PESO
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
				ElseIf aImp[nX,1]=="PS2"
					nAliqPIS := aImp[nX,4]
					nValPIS  := aImp[nX,5]
				ElseIf aImp[nX,1]=="CF2"
					nAliqCOF := aImp[nX,4]
					nValCOF  := aImp[nX,5]
				ElseIf aImp[nX,1]=="ISS"
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

			//nAliPISCOF := nAliqPIS + nAliqCOF
			//nValPISCOF := nValPIS  + nValCOF

			nAliPISCOF := SA1->A1_ZTXPIS + SA1->A1_ZTXCOF
			nValPISCOF := ((cAliasSCK)->CK_VALOR - nValICM) * (nAliPISCOF/100)

			IF SCK->(MSSEEK(FWXFILIAL("SCK")+(cAliasSCK)->CK_NUM+(cAliasSCK)->CK_ITEM))
				RecLock("SCK",.F.)
				SCK->CK_ZALICMS := nAliqICM		//MaFisRet(nItem,"IT_ALIQICM")
				SCK->CK_ALPISCO := nAliPISCOF	//(nItem,"IT_ALIQPIS")	+ MaFisRet(nItem,"IT_ALIQCOF")
				SCK->CK_ZALISSQ := nAliqIss		//MaFisRet(nItem,"IT_ALIQISS")

				SCK->CK_ZICMS   := nValICM		//MaFisRet(nItem,"IT_VALICM") //SCK->CK_VALOR * (SCK->CK_ZALICMS/100)
				SCK->CK_ZPISCOF := nValPISCOF	//MaFisRet(nItem,"IT_VALPIS") + MaFisRet(nItem,"IT_VALCOF") //SCK->CK_VALOR * (SCK->CK_ALPISCO/100)
				SCK->CK_ZISSQN  := nValISS		//MaFisRet(nItem,"IT_VALISS") //SCK->CK_VALOR * (SCK->CK_ZALISSQ/100)

				SCK->CK_ZTOTIMP := SCK->CK_VALOR - SCK->CK_ZICMS - SCK->CK_ZPISCOF - SCK->CK_ZISSQN

				SCK->(MSUNLOCK())
			EndIf

			(cAliasSCK)->(DbSkip())

		EndDo

		(cAliasSCK)->(dbCloseArea()) //Fecha a tabela temporaria
	EndIf
	RestArea(aArea) //Restaura o ambiente ativo no início da chamada

Return
