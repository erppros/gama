#INCLUDE 'PROTHEUS.CH'
#INCLUDE "FWMVCDEF.CH"
#Include "Totvs.ch"
#Include "topconn.ch"
#INCLUDE "TBICONN.CH"


User Function MA415END()
	Local aArea     := GetArea()        //Armazena o ambiente ativo para restaurar ao fim do processo
	Local nTipo     := PARAMIXB[1]      //ndica se confirmou a operação: 0 - Não confirmou / 1 - Confirmou a operação
	Local nOper     := PARAMIXB[2]      //Número da Opção (1 - Inclusão / 2 - Alteração / 3 - Exclusão)
	// Local cQrySCK   := ""               //Query
	// Local cAliasSCK := GetNextAlias()   //Criação de tabelas temporárias

	Private lVersiona := .T.
	If nTipo == 1 .AND. !FwIsInCallStack('U_FB001FAT')
		If nOper == 1
			IncluiVersao()
			RecLock("SCJ",.F.)
			SCJ->CJ_ZVERSAO := '0001'
			SCJ->(MsUnlock())
		ElseIf nOper == 2
			If MsgNoYes("Deseja criar uma nova rodada(versão) para este orçamento?","Orçamento")
				RecLock("SCJ",.F.)
				SCJ->CJ_ZVERSAO := fCodVer(SCJ->CJ_NUM)
				SCJ->(MsUnlock())

				lVersiona := .T.
				IncluiVersao()
			Else
				lVersiona := .F.
				IncluiVersao()
			EndIf
		ElseIf nOper == 3
			Delete()
		EndIf
	EndIf

	RestArea(aArea) //Restaura o ambiente ativo no início da chamada

Return

/*/{Protheus.doc} IncluiVersao
	Função que irá incluir uma nova versão do orçamento nas tabelas ZCJ e ZCK conforme as tabelas SCJ e SCK
	@type  Static Function
	@author Roberta Neukamp Guerreiro
	@since 16/04/2025
/*/
Static Function IncluiVersao()
	// Local aArea     := GetArea()
	// Local cAliasSCK := GetNextAlias()
	// Local cAliasZCK := GetNextAlias()

	dbSelectArea("SCK")
	dbSetOrder(1)
	dbSelectArea("ZCJ")
	dbSetOrder(1)
	dbSelectArea("ZCK")
	dbSetOrder(1)

	If lVersiona
		RecLock("ZCJ",.T.)

		ZCJ->ZCJ_FILIAL 	:= SCJ->CJ_FILIAL
		ZCJ->ZCJ_NUM 		:= SCJ->CJ_NUM
		ZCJ->ZCJ_ZVERSA		:= SCJ->CJ_ZVERSAO
		ZCJ->ZCJ_EMISSA 	:= SCJ->CJ_EMISSAO
		ZCJ->ZCJ_ZPRAZO		:= SCJ->CJ_ZPRAZO
		ZCJ->ZCJ_CODCLI 	:= SCJ->CJ_CLIENTE
		ZCJ->ZCJ_LOJA 		:= SCJ->CJ_LOJA
		// ZCJ->ZCJ_NOMCLI 	:= SCJ->CJ_NOMCLI
		ZCJ->ZCJ_CLIENT 	:= SCJ->CJ_CLIENT
		ZCJ->ZCJ_LOJAEN 	:= SCJ->CJ_LOJAENT
		ZCJ->ZCJ_CONDPA 	:= SCJ->CJ_CONDPAG
		ZCJ->ZCJ_ZDCOND 	:= SCJ->CJ_ZDCOND
		ZCJ->ZCJ_TIPOCL 	:= SCJ->CJ_TIPOCLI
		ZCJ->ZCJ_TABELA 	:= SCJ->CJ_TABELA
		ZCJ->ZCJ_ZRESPO 	:= SCJ->CJ_ZRESPOR
		ZCJ->ZCJ_ZNOMRE 	:= SCJ->CJ_ZNOMRES
		ZCJ->ZCJ_LOJPRO 	:= SCJ->CJ_LOJPRO
		ZCJ->ZCJ_PROSPE 	:= SCJ->CJ_PROSPE
		ZCJ->ZCJ_ZREGTR 	:= SCJ->CJ_ZREGTRI
		ZCJ->ZCJ_ZCONCL 	:= SCJ->CJ_ZCONCLI
		ZCJ->ZCJ_ZNCONT 	:= SCJ->CJ_ZNCONT
		ZCJ->ZCJ_DESC3 		:= SCJ->CJ_DESC3
		ZCJ->ZCJ_DESC4 		:= SCJ->CJ_DESC4
		ZCJ->ZCJ_DESC1		:= SCJ->CJ_DESC1
		ZCJ->ZCJ_PARC1 		:= SCJ->CJ_PARC1
		ZCJ->ZCJ_DATA1 		:= SCJ->CJ_DATA1
		ZCJ->ZCJ_DESC2 		:= SCJ->CJ_DESC2
		ZCJ->ZCJ_PARC2 		:= SCJ->CJ_PARC2
		ZCJ->ZCJ_DATA2 		:= SCJ->CJ_DATA2
		ZCJ->ZCJ_PARC3 		:= SCJ->CJ_PARC3
		ZCJ->ZCJ_DATA3 		:= SCJ->CJ_DATA3
		ZCJ->ZCJ_PARC4 		:= SCJ->CJ_PARC4
		ZCJ->ZCJ_DATA4 		:= SCJ->CJ_DATA4
		ZCJ->ZCJ_STATUS 	:= SCJ->CJ_STATUS
		ZCJ->ZCJ_COTCLI 	:= SCJ->CJ_COTCLI
		ZCJ->ZCJ_FRETE 		:= SCJ->CJ_FRETE
		ZCJ->ZCJ_SEGURO 	:= SCJ->CJ_SEGURO
		ZCJ->ZCJ_DESPES 	:= SCJ->CJ_DESPESA
		ZCJ->ZCJ_FRETAU 	:= SCJ->CJ_FRETAUT
		ZCJ->ZCJ_VALIDA 	:= SCJ->CJ_VALIDA
		ZCJ->ZCJ_TIPO 		:= SCJ->CJ_TIPO
		ZCJ->ZCJ_MOEDA 		:= SCJ->CJ_MOEDA
		// ZCJ->ZCJ_FILVEN 	:= SCJ->CJ_FILVEN
		// ZCJ->ZCJ_FILENT 	:= SCJ->CJ_FILENT
		ZCJ->ZCJ_TPCARG 	:= SCJ->CJ_TPCARGA
		ZCJ->ZCJ_DESCON 	:= SCJ->CJ_DESCONT
		ZCJ->ZCJ_PDESCA 	:= SCJ->CJ_PDESCAB
		ZCJ->ZCJ_NUMEXT 	:= SCJ->CJ_NUMEXT
		ZCJ->ZCJ_PROPOS 	:= SCJ->CJ_PROPOST
		ZCJ->ZCJ_NROPOR 	:= SCJ->CJ_NROPOR
		ZCJ->ZCJ_REVISA 	:= SCJ->CJ_REVISA
		ZCJ->ZCJ_TXMOED 	:= SCJ->CJ_TXMOEDA
		ZCJ->ZCJ_TPFRET 	:= SCJ->CJ_TPFRETE
		ZCJ->ZCJ_CODA1U 	:= SCJ->CJ_CODA1U
		ZCJ->ZCJ_ZINFCO 	:= SCJ->CJ_ZINFCOM
		ZCJ->ZCJ_CCONST 	:= SCJ->CJ_CCONSTR
		ZCJ->ZCJ_INDPRE 	:= SCJ->CJ_INDPRES
		ZCJ->ZCJ_ZOPER 		:= SCJ->CJ_ZOPER
		ZCJ->ZCJ_TIPLIB 	:= SCJ->CJ_TIPLIB
		ZCJ->ZCJ_ZEST 		:= SCJ->CJ_ZEST
		ZCJ->ZCJ_ZMUN 		:= SCJ->CJ_ZMUN

		ZCJ->(MsUnlock())

		//------------------------------------------
		// Query da tabela SCK - Itens de Orçamento
		//------------------------------------------
		// cQrySCK := " SELECT *"
		// cQrySCK += " FROM "+RetSqlName("SCK")
		// cQrySCK += " WHERE CK_FILIAL = '"+SCJ->CJ_FILIAL +"' "
		// cQrySCK += " AND CK_NUM = '"+SCJ->CJ_NUM +"' "
		// cQrySCK += " AND D_E_L_E_T_=' ' "
		// cQrySCK := ChangeQuery(cQrySCK)

		// dbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQrySCK),cAliasSCK,.T.,.T.)
		SCK->(dbGoTop())
		SCK->(MsSeek(xFilial("SCK")+SCJ->CJ_NUM))

		While SCK->(!Eof()) .And. SCK->CK_FILIAL + SCK->CK_NUM ==SCJ->CJ_FILIAL +SCJ->CJ_NUM

			RecLock("ZCK",.T.)

			ZCK->ZCK_FILIAL 	:= SCK->CK_FILIAL
			ZCK->ZCK_ITEM 		:= SCK->CK_ITEM
			ZCK->ZCK_PRODUT		:= SCK->CK_PRODUTO
			ZCK->ZCK_DESCRI 	:= SCK->CK_DESCRI
			ZCK->ZCK_ZDCOMP		:= SCK->CK_ZDCOMP
			ZCK->ZCK_ZNCM 		:= SCK->CK_ZNCM
			ZCK->ZCK_OPER 		:= SCK->CK_OPER
			ZCK->ZCK_TES 		:= SCK->CK_TES
			ZCK->ZCK_UM 		:= SCK->CK_UM
			ZCK->ZCK_ZCAVID 	:= SCK->CK_ZCAVIDA
			ZCK->ZCK_QTDVEN 	:= SCK->CK_QTDVEN
			ZCK->ZCK_ZPRCVE		:= SCK->CK_ZPRCVEN
			ZCK->ZCK_PRCVEN 	:= SCK->CK_PRCVEN
			ZCK->ZCK_VALOR 		:= SCK->CK_VALOR
			ZCK->ZCK_ZTOTIM 	:= SCK->CK_ZTOTIMP
			ZCK->ZCK_LOCAL 		:= SCK->CK_LOCAL
			ZCK->ZCK_ZIMPIM 	:= SCK->CK_ZIMPIMG
			ZCK->ZCK_CLIENT 	:= SCK->CK_CLIENTE
			ZCK->ZCK_LOJA 		:= SCK->CK_LOJA
			ZCK->ZCK_DESCON 	:= SCK->CK_DESCONT
			ZCK->ZCK_VALDES 	:= SCK->CK_VALDESC
			ZCK->ZCK_PEDCLI		:= SCK->CK_PEDCLI
			ZCK->ZCK_NUM		:= SCK->CK_NUM
			ZCK->ZCK_PRUNIT		:= SCK->CK_PRUNIT
			ZCK->ZCK_NUMPV 		:= SCK->CK_NUMPV
			ZCK->ZCK_CLASFI 	:= SCK->CK_CLASFIS
			ZCK->ZCK_NUMOP 		:= SCK->CK_NUMOP
			ZCK->ZCK_OBS 		:= SCK->CK_OBS
			ZCK->ZCK_ENTREG 	:= SCK->CK_ENTREG
			ZCK->ZCK_COTCLI		:= SCK->CK_COTCLI
			ZCK->ZCK_ITECLI 	:= SCK->CK_ITECLI
			ZCK->ZCK_OPC 		:= SCK->CK_OPC
			ZCK->ZCK_FILVEN 	:= SCK->CK_FILVEN
			ZCK->ZCK_FILENT 	:= SCK->CK_FILENT
			ZCK->ZCK_CONTRA		:= SCK->CK_CONTRAT
			ZCK->ZCK_ITEMCO 	:= SCK->CK_ITEMCON
			ZCK->ZCK_PROJPM 	:= SCK->CK_PROJPMS
			ZCK->ZCK_NVERPM 	:= SCK->CK_NVERPMS
			ZCK->ZCK_EDTPMS 	:= SCK->CK_EDTPMS
			ZCK->ZCK_TASKPM		:= SCK->CK_TASKPMS
			ZCK->ZCK_TPPROD		:= SCK->CK_TPPROD
			ZCK->ZCK_FCICOD 	:= SCK->CK_FCICOD
			ZCK->ZCK_VLIMPO 	:= SCK->CK_VLIMPOR
			ZCK->ZCK_COMIS1 	:= SCK->CK_COMIS1
			ZCK->ZCK_PROPOS 	:= SCK->CK_PROPOST
			ZCK->ZCK_ITEMPR 	:= SCK->CK_ITEMPRO
			ZCK->ZCK_NORCPM 	:= SCK->CK_NORCPMS
			ZCK->ZCK_DT1VEN 	:= SCK->CK_DT1VEN
			ZCK->ZCK_ITEMGR 	:= SCK->CK_ITEMGRD
			ZCK->ZCK_MOPC 		:= SCK->CK_MOPC
			ZCK->ZCK_ZALICM 	:= SCK->CK_ZALICMS
			ZCK->ZCK_ALPISC 	:= SCK->CK_ALPISCO
			ZCK->ZCK_ZALISS 	:= SCK->CK_ZALISSQ
			ZCK->ZCK_ZICMS 		:= SCK->CK_ZICMS
			ZCK->ZCK_ZPISCO 	:= SCK->CK_ZPISCOF
			ZCK->ZCK_ZISSQN 	:= SCK->CK_ZISSQN
			ZCK->ZCK_ZVERSA		:= SCJ->CJ_ZVERSAO

			ZCK->(MsUnlock())

			SCK->(DbSkip())
		EndDo

		// SCK->(dbCloseArea())

	Else
		// ZCJ->(dbGoTop())
		If ZCJ->(MsSeek(xFilial("ZCJ")+SCJ->CJ_NUM+SCJ->CJ_ZVERSAO))
			RecLock("ZCJ",.F.)

			ZCJ->ZCJ_FILIAL 	:= SCJ->CJ_FILIAL
			ZCJ->ZCJ_NUM 		:= SCJ->CJ_NUM
			ZCJ->ZCJ_ZVERSA		:= SCJ->CJ_ZVERSAO
			ZCJ->ZCJ_EMISSA 	:= SCJ->CJ_EMISSAO
			ZCJ->ZCJ_ZPRAZO		:= SCJ->CJ_ZPRAZO
			ZCJ->ZCJ_CODCLI 	:= SCJ->CJ_CLIENTE
			ZCJ->ZCJ_LOJA 		:= SCJ->CJ_LOJA
			// ZCJ->ZCJ_NOMCLI 	:= SCJ->CJ_NOMCLI
			ZCJ->ZCJ_CLIENT 	:= SCJ->CJ_CLIENT
			ZCJ->ZCJ_LOJAEN 	:= SCJ->CJ_LOJAENT
			ZCJ->ZCJ_CONDPA 	:= SCJ->CJ_CONDPAG
			ZCJ->ZCJ_ZDCOND 	:= SCJ->CJ_ZDCOND
			ZCJ->ZCJ_TIPOCL 	:= SCJ->CJ_TIPOCLI
			ZCJ->ZCJ_TABELA 	:= SCJ->CJ_TABELA
			ZCJ->ZCJ_ZRESPO 	:= SCJ->CJ_ZRESPOR
			ZCJ->ZCJ_ZNOMRE 	:= SCJ->CJ_ZNOMRES
			ZCJ->ZCJ_LOJPRO 	:= SCJ->CJ_LOJPRO
			ZCJ->ZCJ_PROSPE 	:= SCJ->CJ_PROSPE
			ZCJ->ZCJ_ZREGTR 	:= SCJ->CJ_ZREGTRI
			ZCJ->ZCJ_ZCONCL 	:= SCJ->CJ_ZCONCLI
			ZCJ->ZCJ_ZNCONT 	:= SCJ->CJ_ZNCONT
			ZCJ->ZCJ_DESC3 		:= SCJ->CJ_DESC3
			ZCJ->ZCJ_DESC4 		:= SCJ->CJ_DESC4
			ZCJ->ZCJ_DESC1		:= SCJ->CJ_DESC1
			ZCJ->ZCJ_PARC1 		:= SCJ->CJ_PARC1
			ZCJ->ZCJ_DATA1 		:= SCJ->CJ_DATA1
			ZCJ->ZCJ_DESC2 		:= SCJ->CJ_DESC2
			ZCJ->ZCJ_PARC2 		:= SCJ->CJ_PARC2
			ZCJ->ZCJ_DATA2 		:= SCJ->CJ_DATA2
			ZCJ->ZCJ_PARC3 		:= SCJ->CJ_PARC3
			ZCJ->ZCJ_DATA3 		:= SCJ->CJ_DATA3
			ZCJ->ZCJ_PARC4 		:= SCJ->CJ_PARC4
			ZCJ->ZCJ_DATA4 		:= SCJ->CJ_DATA4
			ZCJ->ZCJ_STATUS 	:= SCJ->CJ_STATUS
			ZCJ->ZCJ_COTCLI 	:= SCJ->CJ_COTCLI
			ZCJ->ZCJ_FRETE 		:= SCJ->CJ_FRETE
			ZCJ->ZCJ_SEGURO 	:= SCJ->CJ_SEGURO
			ZCJ->ZCJ_DESPES 	:= SCJ->CJ_DESPESA
			ZCJ->ZCJ_FRETAU 	:= SCJ->CJ_FRETAUT
			ZCJ->ZCJ_VALIDA 	:= SCJ->CJ_VALIDA
			ZCJ->ZCJ_TIPO 		:= SCJ->CJ_TIPO
			ZCJ->ZCJ_MOEDA 		:= SCJ->CJ_MOEDA
			// ZCJ->ZCJ_FILVEN 	:= SCJ->CJ_FILVEN
			// ZCJ->ZCJ_FILENT 	:= SCJ->CJ_FILENT
			ZCJ->ZCJ_TPCARG 	:= SCJ->CJ_TPCARGA
			ZCJ->ZCJ_DESCON 	:= SCJ->CJ_DESCONT
			ZCJ->ZCJ_PDESCA 	:= SCJ->CJ_PDESCAB
			ZCJ->ZCJ_NUMEXT 	:= SCJ->CJ_NUMEXT
			ZCJ->ZCJ_PROPOS 	:= SCJ->CJ_PROPOST
			ZCJ->ZCJ_NROPOR 	:= SCJ->CJ_NROPOR
			ZCJ->ZCJ_REVISA 	:= SCJ->CJ_REVISA
			ZCJ->ZCJ_TXMOED 	:= SCJ->CJ_TXMOEDA
			ZCJ->ZCJ_TPFRET 	:= SCJ->CJ_TPFRETE
			ZCJ->ZCJ_CODA1U 	:= SCJ->CJ_CODA1U
			ZCJ->ZCJ_ZINFCO 	:= SCJ->CJ_ZINFCOM
			ZCJ->ZCJ_CCONST 	:= SCJ->CJ_CCONSTR
			ZCJ->ZCJ_INDPRE 	:= SCJ->CJ_INDPRES
			ZCJ->ZCJ_ZOPER 		:= SCJ->CJ_ZOPER
			ZCJ->ZCJ_TIPLIB 	:= SCJ->CJ_TIPLIB
			ZCJ->ZCJ_ZEST 		:= SCJ->CJ_ZEST
			ZCJ->ZCJ_ZMUN 		:= SCJ->CJ_ZMUN

			ZCJ->(MsUnlock())

			ZCK->(MsSeek(xFilial("ZCK")+SCJ->CJ_NUM+SCJ->CJ_ZVERSAO))

			SCK->(dbGoTop())
			SCK->(MsSeek(xFilial("SCK")+SCJ->CJ_NUM))

			While ZCK->(!Eof()) .And. SCK->CK_FILIAL + SCK->CK_NUM + SCJ->CJ_ZVERSAO == ZCK->ZCK_FILIAL + ZCK->ZCK_NUM + ZCK->ZCK_ZVERSA
				RecLock("ZCK",.F.)

				ZCK->ZCK_FILIAL 	:= SCK->CK_FILIAL
				ZCK->ZCK_ITEM 		:= SCK->CK_ITEM
				ZCK->ZCK_PRODUT		:= SCK->CK_PRODUTO
				ZCK->ZCK_DESCRI 	:= SCK->CK_DESCRI
				ZCK->ZCK_ZDCOMP		:= SCK->CK_ZDCOMP
				ZCK->ZCK_ZNCM 		:= SCK->CK_ZNCM
				ZCK->ZCK_OPER 		:= SCK->CK_OPER
				ZCK->ZCK_TES 		:= SCK->CK_TES
				ZCK->ZCK_UM 		:= SCK->CK_UM
				ZCK->ZCK_ZCAVID 	:= SCK->CK_ZCAVIDA
				ZCK->ZCK_QTDVEN 	:= SCK->CK_QTDVEN
				ZCK->ZCK_ZPRCVE		:= SCK->CK_ZPRCVEN
				ZCK->ZCK_PRCVEN 	:= SCK->CK_PRCVEN
				ZCK->ZCK_VALOR 		:= SCK->CK_VALOR
				ZCK->ZCK_ZTOTIM 	:= SCK->CK_ZTOTIMP
				ZCK->ZCK_LOCAL 		:= SCK->CK_LOCAL
				ZCK->ZCK_ZIMPIM 	:= SCK->CK_ZIMPIMG
				ZCK->ZCK_CLIENT 	:= SCK->CK_CLIENTE
				ZCK->ZCK_LOJA 		:= SCK->CK_LOJA
				ZCK->ZCK_DESCON 	:= SCK->CK_DESCONT
				ZCK->ZCK_VALDES 	:= SCK->CK_VALDESC
				ZCK->ZCK_PEDCLI		:= SCK->CK_PEDCLI
				ZCK->ZCK_NUM		:= SCK->CK_NUM
				ZCK->ZCK_PRUNIT		:= SCK->CK_PRUNIT
				ZCK->ZCK_NUMPV 		:= SCK->CK_NUMPV
				ZCK->ZCK_CLASFI 	:= SCK->CK_CLASFIS
				ZCK->ZCK_NUMOP 		:= SCK->CK_NUMOP
				ZCK->ZCK_OBS 		:= SCK->CK_OBS
				ZCK->ZCK_ENTREG 	:= SCK->CK_ENTREG
				ZCK->ZCK_COTCLI		:= SCK->CK_COTCLI
				ZCK->ZCK_ITECLI 	:= SCK->CK_ITECLI
				ZCK->ZCK_OPC 		:= SCK->CK_OPC
				ZCK->ZCK_FILVEN 	:= SCK->CK_FILVEN
				ZCK->ZCK_FILENT 	:= SCK->CK_FILENT
				ZCK->ZCK_CONTRA		:= SCK->CK_CONTRAT
				ZCK->ZCK_ITEMCO 	:= SCK->CK_ITEMCON
				ZCK->ZCK_PROJPM 	:= SCK->CK_PROJPMS
				ZCK->ZCK_NVERPM 	:= SCK->CK_NVERPMS
				ZCK->ZCK_EDTPMS 	:= SCK->CK_EDTPMS
				ZCK->ZCK_TASKPM		:= SCK->CK_TASKPMS
				ZCK->ZCK_TPPROD		:= SCK->CK_TPPROD
				ZCK->ZCK_FCICOD 	:= SCK->CK_FCICOD
				ZCK->ZCK_VLIMPO 	:= SCK->CK_VLIMPOR
				ZCK->ZCK_COMIS1 	:= SCK->CK_COMIS1
				ZCK->ZCK_PROPOS 	:= SCK->CK_PROPOST
				ZCK->ZCK_ITEMPR 	:= SCK->CK_ITEMPRO
				ZCK->ZCK_NORCPM 	:= SCK->CK_NORCPMS
				ZCK->ZCK_DT1VEN 	:= SCK->CK_DT1VEN
				ZCK->ZCK_ITEMGR 	:= SCK->CK_ITEMGRD
				ZCK->ZCK_MOPC 		:= SCK->CK_MOPC
				ZCK->ZCK_ZALICM 	:= SCK->CK_ZALICMS
				ZCK->ZCK_ALPISC 	:= SCK->CK_ALPISCO
				ZCK->ZCK_ZALISS 	:= SCK->CK_ZALISSQ
				ZCK->ZCK_ZICMS 		:= SCK->CK_ZICMS
				ZCK->ZCK_ZPISCO 	:= SCK->CK_ZPISCOF
				ZCK->ZCK_ZISSQN 	:= SCK->CK_ZISSQN
				ZCK->ZCK_ZVERSA		:= SCJ->CJ_ZVERSAO

				ZCK->(MsUnlock())

				ZCK->(DbSkip())
				SCK->(DbSkip())
			EndDo
			// (cAliasZCK)->(dbCloseArea())
		EndIf
	EndIf
Return

/*/{Protheus.doc} Delete
	Função que irá fazer a deleção dos registros das tabelas ZCJ e ZCK
	@type  Static Function
	@author Roberta Neukamp Guerreiro
	@since 16/04/2025
/*/
Static Function Delete()
	// Local aArea     := GetArea()
	Local cAliasZCJ := GetNextAlias()
	Local cAliasZCK := GetNextAlias()

	dbSelectArea("ZCJ")
	dbSetOrder(1)
	dbSelectArea("ZCK")
	dbSetOrder(1)

	//------------------------------------------
	// Query da tabela ZCJ - Versao Orçamento
	//------------------------------------------
	cQryZCJ := " SELECT ZCJ_FILIAL, ZCJ_NUM, ZCJ_ZVERSA "
	cQryZCJ += " FROM "+RetSqlName("ZCJ")
	cQryZCJ += " WHERE ZCJ_FILIAL = '"+ SCJ->CJ_FILIAL +"' "
	cQryZCJ += " AND ZCJ_NUM = '"+ SCJ->CJ_NUM +"' "
	cQryZCJ += " AND D_E_L_E_T_=' ' "
	cQryZCJ := ChangeQuery(cQryZCJ)

	dbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQryZCJ),cAliasZCJ,.T.,.T.)

	While (cAliasZCJ)->(!Eof()) .And. SCJ->CJ_FILIAL + SCJ->CJ_NUM == (cAliasZCJ)->ZCJ_FILIAL + (cAliasZCJ)->ZCJ_NUM
		ZCJ->(MsSeek(xFilial("ZCJ")+(cAliasZCJ)->ZCJ_NUM+(cAliasZCJ)->ZCJ_ZVERSA))
		RecLock('ZCJ', .F.)
		dbDelete()
		ZCJ->(MsUnlock())
		(cAliasZCJ)->(DbSkip())
	EndDo
	(cAliasZCJ)->(dbCloseArea())

	//------------------------------------------
	// Query da tabela ZCK - Versao Itens do Orçamento
	//------------------------------------------
	cQryZCK := " SELECT ZCK_FILIAL, ZCK_NUM, ZCK_ITEM, ZCK_ZVERSA "
	cQryZCK += " FROM "+RetSqlName("ZCK")
	cQryZCK += " WHERE ZCK_FILIAL = '"+ SCJ->CJ_FILIAL +"' "
	cQryZCK += " AND ZCK_NUM = '"+ SCJ->CJ_NUM +"' "
	cQryZCK += " AND D_E_L_E_T_=' ' "
	cQryZCK := ChangeQuery(cQryZCK)

	dbUseArea(.T.,"TOPCONN",TCGENQRY(,,cQryZCK),cAliasZCK,.T.,.T.)

	While (cAliasZCK)->(!Eof()) .And. SCJ->CJ_FILIAL + SCJ->CJ_NUM == (cAliasZCK)->ZCK_FILIAL + (cAliasZCK)->ZCK_NUM
		ZCK->(MsSeek(xFilial("ZCK")+(cAliasZCK)->ZCK_NUM+(cAliasZCK)->ZCK_ZVERSA))
		RecLock('ZCK', .F.)
		dbDelete()
		ZCK->(MsUnlock())
		(cAliasZCK)->(DbSkip())
	EndDo
	(cAliasZCK)->(dbCloseArea())

Return

Static Function fCodVer(cNumOrc)

	Local cCodigo := ""

	BEGINSQL ALIAS "TMPZCJ"

        SELECT MAX(ZCJ_ZVERSA) AS CODVER
        FROM %TABLE:ZCJ% ZCJ
        WHERE ZCJ.%NOTDEL%
		AND ZCJ.ZCJ_NUM = %EXP:cNumOrc%

	ENDSQL

	If !Empty(TMPZCJ->CODVER)
		cCodigo := SOMA1(TMPZCJ->CODVER)
	Endif

	TMPZCJ->(DBCLOSEAREA())
Return cCodigo
