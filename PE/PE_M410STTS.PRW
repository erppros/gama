#INCLUDE 'PROTHEUS.CH'
#INCLUDE "FWMVCDEF.CH"

User Function M410STTS()

	Local aArea     := GetArea()        //Armazena o ambiente ativo para restaurar ao fim do processo
	Local nOpcao    := PARAMIXB[1]      //Número da Opção (1 - Inclusão / 2 - Alteração / 3 - Exclusão)
	Local cQrySC6   := ""               //Query
	Local cAliasSC6 := GetNextAlias()   //Criação de tabelas temporárias
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


	If nOpcao == 3 .Or.  nOpcao  == 4 .or. nOpcao == 6 //Inclusao ou Alteração

		dbSelectArea("SA1")
		dbSetOrder(1)
		MsSeek(xFilial("SA1")+If(!Empty(M->C5_CLIENT),M->C5_CLIENT,M->C5_CLIENTE)+M->C5_LOJAENT)

		dbSelectArea("SE4")
		dbSetOrder(1)
		MsSeek(xFilial("SE4")+M->C5_CONDPAG)

		If !Empty(M->C5_PROSPE) .And. !Empty(M->C5_LOJPRO)
			cTipo := Posicione("SUS",1,xFilial("SUS") + M->C5_PROSPE + M->C5_LOJPRO,"US_TIPO")
			lProspect := .T.
		Endif

		MaFisSave()
		MaFisEnd()

		//inicializa a funcao fiscal
		//MaFisIni(   SC5->C5_CLIENTE,SC5->C5_LOJA,"C","N",,,,,,,,,,,,SC5->C5_CLIENTE,SC5->C5_LOJA)
		MaFisIni(Iif(Empty(M->C5_CLIENT),M->C5_CLIENTE,M->C5_CLIENT),;// 1-Codigo Cliente/Fornecedor
		M->C5_LOJAENT,;     // 2-Loja do Cliente/Fornecedor
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
			IiF(lProspect,M->C5_PROSPE+M->C5_LOJPRO,""))

		//------------------------------------------
		// Query da tabela SC6 - Itens do Pedido de Venda
		//------------------------------------------
		cQrySC6 := " SELECT C6_FILIAL, C6_NUM, C6_VALOR, C6_ITEM, C6_PRODUTO, C6_TES, C6_QTDVEN, C6_PRCVEN, C6_PRUNIT,C6_VALDESC,C6_LOCAL "
		cQrySC6 += " FROM "+RetSqlName("SC6")
		cQrySC6 += " WHERE C6_FILIAL = '"+ SC5->C5_FILIAL +"' "
		cQrySC6 += " AND C6_NUM = '"+ SC5->C5_NUM +"' "
		cQrySC6 += " AND D_E_L_E_T_=' ' "
		cQrySC6 := ChangeQuery(cQrySC6)

		dbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQrySC6),cAliasSC6,.T.,.T.)

		While (cAliasSC6)->(!Eof()) .And. SC6->C6_FILIAL + SC6->C6_NUM == (cAliasSC6)->C6_FILIAL + (cAliasSC6)->C6_NUM

			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Posiciona Registros                          ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			SB1->(dbSetOrder(1))
			If SB1->(MsSeek(xFilial("SB1")+(cAliasSC6)->C6_PRODUTO))
				nQtdPeso := (cAliasSC6)->C6_QTDVEN*SB1->B1_PESO
			EndIf
			SB2->(dbSetOrder(1))
			SB2->(MsSeek(xFilial("SB2")+(cAliasSC6)->C6_PRODUTO+(cAliasSC6)->C6_LOCAL))
			SF4->(dbSetOrder(1))
			SF4->(MsSeek(xFilial("SF4")+(cAliasSC6)->C6_TES))
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Calcula o preco de lista                     ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			nValMerc  := (cAliasSC6)->C6_VALOR
			nPrcLista := (cAliasSC6)->C6_PRUNIT
			nQtdPeso  := 0
			nItem++
			If ( nPrcLista == 0 )
				nPrcLista := A410Arred(nValMerc/(cAliasSC6)->C6_QTDVEN,"C6_PRCVEN")
			EndIf
			nAcresFin := A410Arred((cAliasSC6)->C6_PRCVEN*SE4->E4_ACRSFIN/100,"D2_PRCVEN")
			nValMerc  += A410Arred(nAcresFin*(cAliasSC6)->C6_QTDVEN,"D2_TOTAL")
			nDesconto := A410Arred(nPrcLista*(cAliasSC6)->C6_QTDVEN,"D2_DESCON")-nValMerc
			nDesconto := IIf(nDesconto==0,(cAliasSC6)->C6_VALDESC,nDesconto)
			nDesconto := Max(0,nDesconto)
			nPrcLista += nAcresFin

			//Para os outros paises, este tratamento e feito no programas que calculam os impostos.
			If cPaisLoc=="BRA"
				nValMerc  += nDesconto
			Endif


			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³Agrega os itens para a funcao fiscal         ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			MaFisAdd((cAliasSC6)->C6_PRODUTO,;   	// 1-Codigo do Produto ( Obrigatorio )
			(cAliasSC6)->C6_TES,;	   	// 2-Codigo do TES ( Opcional )
			(cAliasSC6)->C6_QTDVEN,;  	// 3-Quantidade ( Obrigatorio )
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
			If SB1->(MsSeek(xFilial("SB1")+(cAliasSC6)->C6_PRODUTO))
				nQtdPeso := (cAliasSC6)->C6_QTDVEN*SB1->B1_PESO
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

			nAliPISCOF := nAliqPIS + nAliqCOF
			nValPISCOF := nValPIS  + nValCOF

			AAdd(aDados,{nValICM,nValPISCOF,nValISS})

			if Len(aDados) > 1
				nValICM 	:= aDados[nItem,1] - aDados[nItem-1,1]
				nValPISCOF 	:= aDados[nItem,2] - aDados[nItem-1,2]
				nValISS		:= aDados[nItem,3] - aDados[nItem-1,3]
			Endif

			IF SC6->(MSSEEK(FWXFILIAL("SC6")+(cAliasSC6)->C6_NUM+(cAliasSC6)->C6_ITEM+(cAliasSC6)->C6_PRODUTO))
				RecLock("SC6",.F.)
				SC6->C6_ZALICMS := nAliqICM		//MaFisRet(nItem,"IT_ALIQICM")
				SC6->C6_ZALPISC := nAliPISCOF	//(nItem,"IT_ALIQPIS")	+ MaFisRet(nItem,"IT_ALIQCOF")
				SC6->C6_ZALISSQ := nAliqIss		//MaFisRet(nItem,"IT_ALIQISS")

				SC6->C6_ZICMS   := nValICM		//MaFisRet(nItem,"IT_VALICM") //SC6->C6_VALOR * (SC6->C6_ZALICMS/100)
				SC6->C6_ZPISCOF := nValPISCOF	//MaFisRet(nItem,"IT_VALPIS") + MaFisRet(nItem,"IT_VALCOF") //SC6->C6_VALOR * (SC6->C6_ALPISCO/100)
				SC6->C6_ZISSQN  := nValISS		//MaFisRet(nItem,"IT_VALISS") //SC6->C6_VALOR * (SC6->C6_ZALISSQ/100)

				SC6->C6_ZTOTIMP := SC6->C6_VALOR + SC6->C6_ZICMS + SC6->C6_ZPISCOF + SC6->C6_ZISSQN

				SC6->(MSUNLOCK())
			EndIf

			(cAliasSC6)->(DbSkip())

		EndDo


		(cAliasSC6)->(dbCloseArea()) //Fecha a tabela temporaria
	EndIf

	RestArea(aArea) //Restaura o ambiente ativo no início da chamada

Return

