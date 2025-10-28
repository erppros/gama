#Include "PROTHEUS.CH"

/*/{Protheus.doc} FB001FAT
Função desenvolvida para alterar a versão do orçamento buscando as versão existentes nas tabelas ZCK e ZCJ
@type user function
@author Roberta Neukamp Guerreiro
@since 16/04/2025
/*/
User Function FB001FAT()
	Private cVersao		:= SCJ->CJ_ZVERSAO
	Private cNumOrc		:= SCJ->CJ_NUM

	If fParam()
		Processa({|| AlteraOrc()})
	EndIf

Return

/*/{Protheus.doc} AlteraOrc
    Alteração do orçamento conforme versão selecionada
    @type  Static Function
    @author Roberta Neukamp Guerreiro
    @since 16/04/2025
/*/
Static Function AlteraOrc()
	Local aCabec    := {}
	Local aItens    := {}
	Local aItem     := {}
	Local cAliasZCJ := GetNextAlias()
	Local cAliasZCK := GetNextAlias()

	PRIVATE lMsErroAuto := .F.

	// Busca dados do cabeçalho (ZCJ)
	BeginSql Alias cAliasZCJ
        SELECT *
        FROM %Table:ZCJ% ZCJ
        WHERE ZCJ.%NotDel%
		AND ZCJ.ZCJ_NUM = %EXP:cNumOrc%
        AND ZCJ.ZCJ_ZVERSA = %EXP:cVersao%
        // Adicione filtros adicionais se necessário
	EndSql

	// Verifica se há registros no cabeçalho
	If (cAliasZCJ)->(!EOF())
		// Monta array do cabeçalho com campos preenchidos
		aCabec := MontaCabec(cAliasZCJ)

		// Busca itens relacionados (ZCK)
		BeginSql Alias cAliasZCK
            SELECT *
            FROM %Table:ZCK% ZCK
            WHERE ZCK.%NotDel%
            AND ZCK.ZCK_NUM = %Exp:(cAliasZCJ)->ZCJ_NUM%
            AND ZCK.ZCK_ZVERSA = %EXP:cVersao%
		EndSql

		// Monta array de itens
		While (cAliasZCK)->(!EOF())
			aItem := MontaItem(cAliasZCK)
			If !Empty(aItem)
				AAdd(aItens, aItem)
			EndIf
			(cAliasZCK)->(DbSkip())
		End While
		(cAliasZCK)->(DbCloseArea())

		// Executa o ExecAuto se houver dados válidos
		If !Empty(aCabec) .And. !Empty(aItens)
			MSExecAuto( {|x,y,z| MATA415(x,y,z)}, aCabec, aItens, 4 ) // 4 = Alteração

			// MATA415(aCabec,aItens,4)

			If lMsErroAuto
				MostraErro()

			Else
				MsgInfo("Versão alterada com sucesso!")
			EndIf
		Else
			MsgAlert("Não há dados válidos para alterar a versão!")
		EndIf
	EndIf

	(cAliasZCJ)->(DbCloseArea())

Return

// Função para montar o cabeçalho
Static Function MontaCabec(cAliasZCJ)
	Local aCabec    := {}

	dbSelectArea("ZCJ")
	dbSetOrder(1)
	ZCJ->(MsSeek(xFilial("ZCJ")+(cAliasZCJ)->ZCJ_NUM+(cAliasZCJ)->ZCJ_ZVERSA))

	aCabec := {{"CJ_FILIAL"	, (cAliasZCJ)->ZCJ_FILIAL	, Nil},;
		{"CJ_NUM"		, (cAliasZCJ)->ZCJ_NUM	, Nil},;
		{"CJ_ZVERSAO"	, (cAliasZCJ)->ZCJ_ZVERSA	, Nil},;
		{"CJ_EMISSAO"	, STOD((cAliasZCJ)->ZCJ_EMISSA)	, Nil},;
		{"CJ_ZPRAZO"	, (cAliasZCJ)->ZCJ_ZPRAZO	, Nil},;
		{"CJ_CLIENTE"	, (cAliasZCJ)->ZCJ_CODCLI	, Nil},;
		{"CJ_LOJA"		, (cAliasZCJ)->ZCJ_LOJA		, Nil},;
		{"CJ_CLIENT"	, (cAliasZCJ)->ZCJ_CLIENT	, Nil},;
		{"CJ_LOJAENT"	, (cAliasZCJ)->ZCJ_LOJAEN	, Nil},;
		{"CJ_CONDPAG"	, (cAliasZCJ)->ZCJ_CONDPA	, Nil},;
		{"CJ_ZDCOND"	, (cAliasZCJ)->ZCJ_ZDCOND	, Nil},;
		{"CJ_TIPOCLI"	, (cAliasZCJ)->ZCJ_TIPOCL	, Nil},;
		{"CJ_TABELA"	, (cAliasZCJ)->ZCJ_TABELA	, Nil},;
		{"CJ_ZRESPOR"	, (cAliasZCJ)->ZCJ_ZRESPO	, Nil},;
		{"CJ_ZNOMRES"	, (cAliasZCJ)->ZCJ_ZNOMRE	, Nil},;
		{"CJ_LOJPRO"	, (cAliasZCJ)->ZCJ_LOJPRO	, Nil},;
		{"CJ_PROSPE"	, (cAliasZCJ)->ZCJ_PROSPE	, Nil},;
		{"CJ_ZREGTRI"	, (cAliasZCJ)->ZCJ_ZREGTR	, Nil},;
		{"CJ_ZCONCLI"	, (cAliasZCJ)->ZCJ_ZCONCL	, Nil},;
		{"CJ_ZNCONT"	, (cAliasZCJ)->ZCJ_ZNCONT	, Nil},;
		{"CJ_DESC3"		, (cAliasZCJ)->ZCJ_DESC3	, Nil},;
		{"CJ_DESC4"		, (cAliasZCJ)->ZCJ_DESC4	, Nil},;
		{"CJ_DESC1"		, (cAliasZCJ)->ZCJ_DESC1	, Nil},;
		{"CJ_PARC1"		, (cAliasZCJ)->ZCJ_PARC1	, Nil},;
		{"CJ_DATA1"		, STOD((cAliasZCJ)->ZCJ_DATA1)	, Nil},;
		{"CJ_DESC2"		, (cAliasZCJ)->ZCJ_DESC2	, Nil},;
		{"CJ_PARC2"		, (cAliasZCJ)->ZCJ_PARC2	, Nil},;
		{"CJ_DATA2"		, STOD((cAliasZCJ)->ZCJ_DATA2)	, Nil},;
		{"CJ_PARC3"		, (cAliasZCJ)->ZCJ_PARC3	, Nil},;
		{"CJ_DATA3"		, STOD((cAliasZCJ)->ZCJ_DATA3)	, Nil},;
		{"CJ_PARC4"		, (cAliasZCJ)->ZCJ_PARC4	, Nil},;
		{"CJ_DATA4"		, STOD((cAliasZCJ)->ZCJ_DATA4)	, Nil},;
		{"CJ_STATUS"	, (cAliasZCJ)->ZCJ_STATUS	, Nil},;
		{"CJ_COTCLI"	, (cAliasZCJ)->ZCJ_COTCLI	, Nil},;
		{"CJ_FRETE"		, (cAliasZCJ)->ZCJ_FRETE	, Nil},;
		{"CJ_SEGURO"	, (cAliasZCJ)->ZCJ_SEGURO	, Nil},;
		{"CJ_DESPESA"	, (cAliasZCJ)->ZCJ_DESPES	, Nil},;
		{"CJ_FRETAUT"	, (cAliasZCJ)->ZCJ_FRETAU	, Nil},;
		{"CJ_VALIDA"	, STOD((cAliasZCJ)->ZCJ_VALIDA)	, Nil},;
		{"CJ_TIPO"		, (cAliasZCJ)->ZCJ_TIPO		, Nil},;
		{"CJ_MOEDA"		, (cAliasZCJ)->ZCJ_MOEDA	, Nil},;
		{"CJ_TPCARGA"	, (cAliasZCJ)->ZCJ_TPCARG	, Nil},;
		{"CJ_DESCONT"	, (cAliasZCJ)->ZCJ_DESCON	, Nil},;
		{"CJ_PDESCAB"	, (cAliasZCJ)->ZCJ_PDESCA	, Nil},;
		{"CJ_NUMEXT"	, (cAliasZCJ)->ZCJ_NUMEXT	, Nil},;
		{"CJ_PROPOST"	, (cAliasZCJ)->ZCJ_PROPOS	, Nil},;
		{"CJ_NROPOR"	, (cAliasZCJ)->ZCJ_NROPOR	, Nil},;
		{"CJ_REVISA"	, (cAliasZCJ)->ZCJ_REVISA	, Nil},;
		{"CJ_TXMOEDA"	, (cAliasZCJ)->ZCJ_TXMOED	, Nil},;
		{"CJ_TPFRETE"	, (cAliasZCJ)->ZCJ_TPFRET	, Nil},;
		{"CJ_CODA1U"	, (cAliasZCJ)->ZCJ_CODA1U	, Nil},;
		{"CJ_ZINFCOM"	, ZCJ->ZCJ_ZINFCO			, Nil},;
		{"CJ_CCONSTR"	, ZCJ->ZCJ_CCONST			, Nil},;
		{"CJ_INDPRES"	, (cAliasZCJ)->ZCJ_INDPRE	, Nil},;
		{"CJ_ZOPER"		, (cAliasZCJ)->ZCJ_ZOPER	, Nil},;
		{"CJ_TIPLIB"	, (cAliasZCJ)->ZCJ_TIPLIB	, Nil},;
		{"CJ_ZEST"		, (cAliasZCJ)->ZCJ_ZEST		, Nil},;
		{"CJ_ZMUN"		, (cAliasZCJ)->ZCJ_ZMUN		, Nil}}

Return aCabec

// Função para montar os itens
Static Function MontaItem(cAliasZCK)
	Local aItem     := {}

	dbSelectArea("ZCK")
	dbSetOrder(1)
	ZCK->(MsSeek(xFilial("ZCK")+(cAliasZCK)->ZCK_NUM+(cAliasZCK)->ZCK_ZVERSA))

	aItem := {{"CK_FILIAL"		, (cAliasZCK)->ZCK_FILIAL		, Nil},;
		{"CK_ITEM"		, (cAliasZCK)->ZCK_ITEM		, Nil},;
		{"CK_PRODUTO"	, (cAliasZCK)->ZCK_PRODUT	, Nil},;
		{"CK_DESCRI"	, (cAliasZCK)->ZCK_DESCRI	, Nil},;
		{"CK_ZDCOMP"	, ZCK->ZCK_ZDCOMP			, Nil},;
		{"CK_ZNCM"		, (cAliasZCK)->ZCK_ZNCM		, Nil},;
		{"CK_OPER"		, (cAliasZCK)->ZCK_OPER		, Nil},;
		{"CK_TES"		, (cAliasZCK)->ZCK_TES		, Nil},;
		{"CK_UM"		, (cAliasZCK)->ZCK_UM		, Nil},;
		{"CK_ZCAVIDA"	, (cAliasZCK)->ZCK_ZCAVID	, Nil},;
		{"CK_QTDVEN"	, (cAliasZCK)->ZCK_QTDVEN	, Nil},;
		{"CK_ZPRCVEN"	, (cAliasZCK)->ZCK_ZPRCVE	, Nil},;
		{"CK_PRCVEN"	, (cAliasZCK)->ZCK_PRCVEN	, Nil},;
		{"CK_VALOR"		, (cAliasZCK)->ZCK_VALOR	, Nil},;
		{"CK_ZTOTIMP"	, (cAliasZCK)->ZCK_ZTOTIM	, Nil},;
		{"CK_LOCAL"		, (cAliasZCK)->ZCK_LOCAL	, Nil},;
		{"CK_ZIMPIMG"	, (cAliasZCK)->ZCK_ZIMPIM	, Nil},;
		{"CK_CLIENTE"	, (cAliasZCK)->ZCK_CLIENT	, Nil},;
		{"CK_LOJA"		, (cAliasZCK)->ZCK_LOJA		, Nil},;
		{"CK_DESCONT"	, (cAliasZCK)->ZCK_DESCON	, Nil},;
		{"CK_VALDESC"	, (cAliasZCK)->ZCK_VALDES	, Nil},;
		{"CK_PEDCLI"	, (cAliasZCK)->ZCK_PEDCLI	, Nil},;
		{"CK_NUM"		, (cAliasZCK)->ZCK_NUM		, Nil},;
		{"CK_PRUNIT"	, (cAliasZCK)->ZCK_PRUNIT	, Nil},;
		{"CK_NUMPV"		, (cAliasZCK)->ZCK_NUMPV	, Nil},;
		{"CK_CLASFIS"	, (cAliasZCK)->ZCK_CLASFI	, Nil},;
		{"CK_NUMOP"		, (cAliasZCK)->ZCK_NUMOP	, Nil},;
		{"CK_OBS"		, (cAliasZCK)->ZCK_OBS		, Nil},;
		{"CK_ENTREG"	, STOD((cAliasZCK)->ZCK_ENTREG)	, Nil},;
		{"CK_COTCLI"	, (cAliasZCK)->ZCK_COTCLI	, Nil},;
		{"CK_ITECLI"	, (cAliasZCK)->ZCK_ITECLI	, Nil},;
		{"CK_OPC"		, (cAliasZCK)->ZCK_OPC		, Nil},;
		{"CK_CONTRAT"	, (cAliasZCK)->ZCK_CONTRA	, Nil},;
		{"CK_ITEMCON"	, (cAliasZCK)->ZCK_ITEMCO	, Nil},;
		{"CK_PROJPMS"	, (cAliasZCK)->ZCK_PROJPM	, Nil},;
		{"CK_NVERPMS"	, (cAliasZCK)->ZCK_NVERPM	, Nil},;
		{"CK_EDTPMS"	, (cAliasZCK)->ZCK_EDTPMS	, Nil},;
		{"CK_TASKPMS"	, (cAliasZCK)->ZCK_TASKPM	, Nil},;
		{"CK_TPPROD"	, (cAliasZCK)->ZCK_TPPROD	, Nil},;
		{"CK_FCICOD"	, (cAliasZCK)->ZCK_FCICOD	, Nil},;
		{"CK_VLIMPOR"	, (cAliasZCK)->ZCK_VLIMPO	, Nil},;
		{"CK_COMIS1"	, (cAliasZCK)->ZCK_COMIS1	, Nil},;
		{"CK_PROPOST"	, (cAliasZCK)->ZCK_PROPOS	, Nil},;
		{"CK_ITEMPRO"	, (cAliasZCK)->ZCK_ITEMPR	, Nil},;
		{"CK_NORCPMS"	, (cAliasZCK)->ZCK_NORCPM	, Nil},;
		{"CK_DT1VEN"	, STOD((cAliasZCK)->ZCK_DT1VEN)	, Nil},;
		{"CK_ITEMGRD"	, (cAliasZCK)->ZCK_ITEMGR	, Nil},;
		{"CK_MOPC"		, ZCK->ZCK_MOPC				, Nil},;
		{"CK_ZALICMS"	, (cAliasZCK)->ZCK_ZALICM	, Nil},;
		{"CK_ALPISCO"	, (cAliasZCK)->ZCK_ALPISC	, Nil},;
		{"CK_ZALISSQ"	, (cAliasZCK)->ZCK_ZALISS	, Nil},;
		{"CK_ZICMS"		, (cAliasZCK)->ZCK_ZICMS	, Nil},;
		{"CK_ZPISCOF"	, (cAliasZCK)->ZCK_ZPISCO	, Nil},;
		{"CK_ZISSQN"	, (cAliasZCK)->ZCK_ZISSQN	, Nil}}
Return aItem

/*/{Protheus.doc} fParam
    Tela de parâmetros para selecionar a versão 
    @type  Static Function
    @author Roberta Neukamp Guerreiro
    @since 16/04/2025
/*/
Static Function fParam()
	Local lRet
	Local aButtons := {}

	oParamTl    := FWDialogModal():New()
	oParamTl:SetEscClose(.F.)
	oParamTl:setTitle("Informar Versao")
	//SETA A LARGURA E ALTURA DA JANELA EM PIXELS
	oParamTl:setSize(80, 160)
	oParamTl:createDialog()

	AADD(aButtons, { /*null*/, "Confirmar" /*cTitle*/, {|| lRet := .T., oParamTl:DeActivate() } /*bCodeBlock*/, /*cToolTip*/, /*nShortCut*/, .T. /*lShowBar*/, /*lConfig*/})
	AADD(aButtons, { /*null*/, "Cancelar"  /*cTitle*/, {|| lRet := .F., oParamTl:DeActivate() } /*bCodeBlock*/, /*cToolTip*/, /*nShortCut*/, .T. /*lShowBar*/, /*lConfig*/})

	TSay():New(010,010,{|| "Versao?"} ,oParamTl:getPanelMain(),,,,,,.T.,,,060,014,,,,,,.T.)
	oGetOSDe    := TGet():New(007,075,bSETGET(cVersao),oParamTl:getPanelMain(),080,010,X3Picture("ZCJ_ZVERSA"),{||},0,,,,,.T.,/*15*/,,{||},,,,.F.,.F.,,"",,,, )
	oGetOSDe:cF3:= 'ZCJ'

	oParamTl:AddButtons(aButtons)
	// oParamTl:addButton("Confirmar",{|| lRet := .T., oParamTl:OOWNER:END()},"Confirmar")
	// oParamTl:addButton("Cancelar" ,{|| lRet := .F.,oParamTl:OOWNER:END()},"Cancelar",,.T.,.F.)
	oParamTl:Activate()

Return lRet
