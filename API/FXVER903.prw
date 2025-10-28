#Include "Protheus.ch"
#Include "Parmtype.ch"
#Include "Restful.ch"
#Include "tbiconn.ch"
#Include "fileio.ch"
#Include "FWEVENTVIEWCONSTS.CH"

/***********************************************************************************
|----------------------------------------------------------------------------------|
|* Programa   | FXVER903                                        Data | 19/09/22 | *|
|----------------------------------------------------------------------------------|
|* Autor      | Tree Space - Evolução em Negócios                                 *|
|----------------------------------------------------------------------------------|
|* Utilização | Faturamento -> Atualizações -> Diversos -> Int. Veros             *|
|----------------------------------------------------------------------------------|
|* Descricao  | Rotina genérica com funções de integração Protheus x Veros.       *|
|*            |                                                                   *|
|----------------------------------------------------------------------------------|
***********************************************************************************/

// COMPILAR JUNTO: FB001ACD | FB101ACD

User Function FXVER903()

    Local nHdl := -1
	Local lSchedule := .F.

	if "WFLAUNCHER" $ U_MyPCham()
		lSchedule := .T.
	endif

    Private _cMsgLog := ""
    Private _cCRLF := Chr(13) + Chr(10)

    if lSchedule
    
        RpcSetType(3)

        PREPARE ENVIRONMENT EMPRESA '01' FILIAL '01' USER 'veros' PASSWORD 'a2gia3.1' TABLES 'SB1,SC2,SG2,CYN'
        
        CONOUT("INICIO FXVER903")
        
        nHdl := U__Sem101FAT("Integra_Veros_API")
        if nHdl == 0 
            RESET ENVIRONMENT
            return
        endif
    
    endif
            
    _cMsgLog += ">> Inicio processamento " + DtoC(Date()) + " - " + Time() + _cCRLF

    Conout('Execucoes')
    intExec()
    
    _cMsgLog += _cCRLF + ">> Processamento concluido " + DtoC(Date()) + " - " + Time() + _cCRLF
            
    if lSchedule

        CONOUT(_cMsgLog)

        if nHdl > 0
            U__Sem101FAT(nHdl)
            nHdl := 0
        endif
        
        CONOUT("FIM FXVER903")
    
        RESET ENVIRONMENT
    
    endif

Return

/***********************************************************************************
|----------------------------------------------------------------------------------|
|* Função     | intExec                                         Data | 27/10/22 | *|
|----------------------------------------------------------------------------------|
|* Autor      | Tree Space - Evolução em Negócios                                 *|
|----------------------------------------------------------------------------------|
|* Descricao  | Serviço Veros: getExecucoes.                                      *|
|*            | POST 192.168.0.23:8090/integra_h/getExecucoes                     *|
|----------------------------------------------------------------------------------|
***********************************************************************************/

Static Function intExec()

	Local aArea := GetArea()

    Local cJsonEnv := ""
	Local cUrlAux := "192.168.0.23:8090/integra_h/getExecucoes"

	Local nTimeOut := 120
	Local aHeadOut := {}
	Local cHeadRet := ""
	Local sPostRet := ""

	Local nX := 0
	Local nY := 0

	Local aDadosInt := {}

	Local dDtAux := Date() - 2

	aADD(aHeadOut, "User-Agent: Mozilla/4.0 (compatible; Protheus "+GetBuild()+")")
	aADD(aHeadOut, "Content-Type: application/json")
	aADD(aHeadOut, "Accept: application/json")
  
    //******************************
    // Efetua a busca das Execuções
    //******************************
  
	cJsonEnv := '{"desde": "'+Alltrim(StrZero(Day(dDtAux),2))+'.'+Alltrim(StrZero(Month(dDtAux),2))+'.'+Alltrim(Str(Year(dDtAux)))+', 01.00.00"}'
	
	sPostRet := HttpPost(cUrlAux,,cJsonEnv,nTimeOut,aHeadOut,@cHeadRet)

	if !empty(sPostRet)

		sPostRet := NoAcento(sPostRet)

		aJson := {}
		nRetParser := 0
		oJHM := Nil

		oJson := tJsonParser():New()
		lRet := oJson:Json_Hash(sPostRet, Len(sPostRet), @aJson, @nRetParser, @oJHM)

		if !lRet
			MsgInfo("##### [JSON][ERRO] " + "Parser com erro" + " MSG len: " + AllTrim(Str(Len(sPostRet))) + " bytes lidos: " + AllTrim(Str(nRetParser)))
			MsgInfo("Erro a partir: " + SubStr(sPostRet, (nRetParser+1)))
		else
			
			if len(aJson) >= 0

				aRetWS := aJson[1,2]

				if aRetWS[1,1] == "execs"

					aRetExecs := aRetWS[1,2]

					for nX := 1 to len(aRetExecs)

						aRetExec := aRetExecs[nX, 2]

						aAuxA := Array(12)
						aAuxB := Array(14)
						
						for nY := 1 to len(aRetExec)

							if Alltrim(aRetExec[nY,1]) == "id_exec"
								aAuxA[1] := aRetExec[nY,2]
							elseif Alltrim(aRetExec[nY,1]) == "id_item"
								aAuxA[2] := aRetExec[nY,2]
							elseif Alltrim(aRetExec[nY,1]) == "id_ordem"
								aAuxA[3] := aRetExec[nY,2]
							elseif Alltrim(aRetExec[nY,1]) == "id_servico"
								aAuxA[4] := aRetExec[nY,2]
							elseif Alltrim(aRetExec[nY,1]) == "id_funcionario"
								aAuxA[5] := aRetExec[nY,2]
							elseif Alltrim(aRetExec[nY,1]) == "ini"
								aAuxA[6] := aRetExec[nY,2]
							elseif Alltrim(aRetExec[nY,1]) == "fim"
								aAuxA[7] := aRetExec[nY,2]
							elseif Alltrim(aRetExec[nY,1]) == "qtd_produzida"
								aAuxA[8] := aRetExec[nY,2]
							elseif Alltrim(aRetExec[nY,1]) == "qtd_n_conforme"
								aAuxA[9] := aRetExec[nY,2]
							elseif Alltrim(aRetExec[nY,1]) == "tempo_medio"
								aAuxA[10] := aRetExec[nY,2]
							elseif Alltrim(aRetExec[nY,1]) == "id_operacao"
								aAuxA[11] := aRetExec[nY,2]
							elseif Alltrim(aRetExec[nY,1]) == "id_recurso"
								aAuxA[12] := aRetExec[nY,2]
							endif

						next

						aAuxB[1] := aAuxA[1] // ID Execução
						aAuxB[2] := aAuxA[2] // Código Produto
						aAuxB[3] := aAuxA[3] // Ordem de Produção
						aAuxB[4] := aAuxA[4] // ID Serviço
						aAuxB[5] := aAuxA[5] // ID Funcionário
						
						dDtIni := CtoD(StrTran(left(aAuxA[6], 10),".","/"))
						dDtFim := CtoD(StrTran(left(aAuxA[7], 10),".","/"))
						cHrIni := StrTran(right(aAuxA[6],8),".",":")
						cHrFim := StrTran(right(aAuxA[7],8),".",":")
						
						aAuxB[6] := dDtIni // Data Inicio
						aAuxB[7] := cHrIni // Hora Inicio
						aAuxB[8] := dDtFim // Data Fim
						aAuxB[9] := cHrFim // Hora Fim
						
						aAuxB[10] := val(aAuxA[8]) // Qtd Produzida
						aAuxB[11] := val(aAuxA[9]) // Qtd Não Conforme
						aAuxB[12] := aAuxA[10] // Tempo Médio
						aAuxB[13] := aAuxA[11] // Operação
						aAuxB[14] := aAuxA[12] // Recurso
						
						//aOPTeste := {"S6690301001","S6690401001","S6690501001"}
						//aRecHab := {"CNC01","CNC02","CNC03","CNC04","CNC05","CNC06"}

                        //if aScan(aOPTeste, { |x| Alltrim(x) == Alltrim(aAuxB[3]) }) <> 0 .AND. aScan(aRecHab, { |x| Alltrim(x) == Alltrim(aAuxB[14]) }) <> 0
                        //if aScan(aRecHab, { |x| Alltrim(x) == Alltrim(aAuxB[14]) }) <> 0
						//	aADD(aDadosInt, aAuxB)
						//endif

						aADD(aDadosInt, aAuxB)

					next

				endif

			endif

		endif
		
		if len(aDadosInt) > 0
			grvExecucoes(aDadosInt)
		endif

	endif

	restArea(aArea)

Return

/***********************************************************************************
|----------------------------------------------------------------------------------|
|* Função     | grvExecucoes                                    Data | 27/10/22 | *|
|----------------------------------------------------------------------------------|
|* Autor      | Tree Space - Evolução em Negócios                                 *|
|----------------------------------------------------------------------------------|
|* Descricao  | Efetua a gravação das execuções recebidas do Veros.               *|
|*            |                                                                   *|
|----------------------------------------------------------------------------------|
***********************************************************************************/

Static Function grvExecucoes(aDadAux)
	
	Local aArea := GetArea()
	
	Local nX := 0
	Local nCount := 0
	
	Local nPosIdExec := 1
	Local nPosOp := 3
	Local nPosDtIni := 6
	Local nPosHrIni := 7
	Local nPosDtFim := 8
	Local nPosHrFim := 9
	Local nPosQtd := 10
	Local nPosPerd := 11
	Local nPosOper := 13

	Local lOpFim := .F.
	
	//********************************
	// Gravação dos dados de Produção
	//********************************

	If len(aDadAux) > 0
		
		_cMsgLog += ">> Processando " + Alltrim(Str(len(aDadAux))) + " registros de execução." + Chr(13) + Chr(10)
		
		dbSelectArea("SC2")
		SC2->(dbSetOrder(1)) // C2_FILIAL+C2_NUM+C2_ITEM+C2_SEQUEN+C2_ITEMGRD
		
		dbSelectArea("ZC0")
		ZC0->(dbSetOrder(1)) // ZC0_FILIAL+ZC0_OP+ZC0_PRODUT+ZC0_OPERAC
		
		dbSelectArea("SB1")
		SB1->(dbSetOrder(1)) // B1_FILIAL+B1_COD

		dbSelectArea("SG2")
		SG2->(dbSetOrder(1)) // G2_FILIAL+G2_PRODUTO+G2_CODIGO+G2_OPERAC
		
		For nX:=1 to len(aDadAux)

			lOpFim := .F.
			_aIDVeros := {}
			_nMaxOper := 0

			// ** Verifico existência da OP
			If SC2->(MsSeek( xFilial("SC2") + Alltrim(aDadAux[nX,nPosOp]) ))
				
				SB1->(MsSeek( xFilial("SB1") + SC2->C2_PRODUTO ))

				SG2->(dbSetOrder(1)) // G2_FILIAL+G2_PRODUTO+G2_CODIGO+G2_OPERAC
				if !SG2->(MsSeek( xFilial("SG2") + SC2->C2_PRODUTO + SC2->C2_ROTEIRO + StrZero(Val(aDadAux[nX,nPosOper]),2) ))

					_cMsgLog += ">> Operação não encontrada para a OP: " + Alltrim(aDadAux[nX,nPosOp]) + " - Operação: " + StrZero(Val(aDadAux[nX,nPosOper]),2) + Chr(13) + Chr(10)

				else
				
					//****************************************
					// Busco operações que já foram iniciadas
					//****************************************
					if ZC0->(MsSeek( xFilial("ZC0") + SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN+SC2->C2_ITEMGRD + SC2->C2_PRODUTO ))

						while !ZC0->(EoF()) .AND. ZC0->ZC0_FILIAL + ZC0->ZC0_OP + ZC0->ZC0_PRODUT == xFilial("ZC0") + SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN+SC2->C2_ITEMGRD + SC2->C2_PRODUTO

							if val(ZC0->ZC0_OPERAC) > _nMaxOper
								_nMaxOper := val(ZC0->ZC0_OPERAC)
							endif
							
							ZC0->(dbSkip())
						enddo

					endif
					
					//*********************************************************
					// Verifico se existe algum apontamento para essa operação
					//*********************************************************
					if ZC0->(MsSeek( xFilial("ZC0") + SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN+SC2->C2_ITEMGRD + SC2->C2_PRODUTO + StrZero(Val(aDadAux[nX,nPosOper]),2) ))

						while !ZC0->(EoF()) .AND. ZC0->ZC0_FILIAL + ZC0->ZC0_OP + ZC0->ZC0_PRODUT + ZC0->ZC0_OPERAC == xFilial("ZC0") + SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN+SC2->C2_ITEMGRD + SC2->C2_PRODUTO + StrZero(Val(aDadAux[nX,nPosOper]),2)

							if !empty(ZC0->ZC0_IDVERO)
								aADD(_aIDVeros, ZC0->ZC0_IDVERO)
							endif
							
							if Alltrim(ZC0->ZC0_USRINI) == "veros" .AND. empty(ZC0->ZC0_IDVERO) .AND. ZC0->ZC0_QTPROD == (aDadAux[nX,nPosQtd] - aDadAux[nX,nPosPerd]) .AND. ZC0->ZC0_QTPERD == aDadAux[nX,nPosPerd]

								RecLock("ZC0", .F.)
									ZC0->ZC0_IDVERO := Alltrim(aDadAux[nX,nPosIdExec])
								ZC0->(MsUnlock())

								aADD(_aIDVeros, Alltrim(aDadAux[nX,nPosIdExec]))

							endif

							ZC0->(dbSkip())
						enddo

					endif

					if Val(aDadAux[nX,nPosOper]) >= _nMaxOper .AND. aScan(_aIDVeros, { |x| Alltrim(x) == Alltrim(aDadAux[nX,nPosIdExec]) }) == 0
						_lApont := .T.
					else
						_lApont := .F.
					endif
					
					if !ZC0->(MsSeek( xFilial("ZC0") + SC2->C2_NUM+SC2->C2_ITEM+SC2->C2_SEQUEN+SC2->C2_ITEMGRD + SC2->C2_PRODUTO + StrZero(Val(aDadAux[nX,nPosOper]),2) )) .or. _lApont
					
						// ** Faz apontamento inicial
						RecLock("ZC0", .T.)
							ZC0->ZC0_FILIAL := xFilial("ZC0")
							ZC0->ZC0_OP     := aDadAux[nX,nPosOp]
							ZC0->ZC0_OPERAC := StrZero(Val(aDadAux[nX,nPosOper]),2)
							ZC0->ZC0_QTPROD := 0
							ZC0->ZC0_QTPERD := 0
							ZC0->ZC0_QTDAMO := 0
							ZC0->ZC0_PESOAM := 0
							ZC0->ZC0_PRODUT := SC2->C2_PRODUTO
							ZC0->ZC0_HRINI  := aDadAux[nX,nPosHrIni]
							ZC0->ZC0_HRFIM  := ""
							ZC0->ZC0_DTINI  := aDadAux[nX,nPosDtIni]
							ZC0->ZC0_DTFIM  := CtoD("")
							ZC0->ZC0_RECSH6 := 0
							ZC0->ZC0_USRINI := "veros"
							ZC0->ZC0_USRFIM := ""
							ZC0->ZC0_PRDIMP := IIF(SB1->B1_ORIGEM == "0", "N", "I")
							ZC0->ZC0_RECURS := ""
							ZC0->ZC0_SMO    := 0
							ZC0->ZC0_DTVALI := CtoD("")
							ZC0->ZC0_LOTECT := ""
							ZC0->ZC0_IDVERO := Alltrim(aDadAux[nX,nPosIdExec])
						ZC0->(MsUnLock())
						
						_cMsgLog += ">> Apontamento inicial da OP " + Alltrim(aDadAux[nX,nPosOp]) + " efetuado." + Chr(13) + Chr(10)
					
					else

						_cMsgLog += ">> Apontamento inicial da OP " + Alltrim(aDadAux[nX,nPosOp]) + " já existente." + Chr(13) + Chr(10)

						if !empty(ZC0->ZC0_DTFIM)
							lOpFim := .T.
						endif
						
					endif
					
					// ** Faz apontamento final
					If !Empty(aDadAux[nX,nPosDtFim])
						
						if !lOpFim
						
							RegToMemory("ZC0",.F.,.F.)
							
							M->ZC0_QTPROD := aDadAux[nX,nPosQtd] - aDadAux[nX,nPosPerd]
							M->ZC0_QTPERD := aDadAux[nX,nPosPerd]
							M->ZC0_HRINI  := aDadAux[nX,nPosHrIni]
							M->ZC0_DTINI  := aDadAux[nX,nPosDtIni]
							M->ZC0_HRFIM  := aDadAux[nX,nPosHrFim]
							M->ZC0_DTFIM  := aDadAux[nX,nPosDtFim]
							M->ZC0_USRFIM := "veros"
							M->ZC0_DESC	  := "                                                            "
							
							RecLock("ZC0", .F.)
								ZC0->ZC0_QTPROD := aDadAux[nX,nPosQtd] - aDadAux[nX,nPosPerd]
								ZC0->ZC0_QTPERD := aDadAux[nX,nPosPerd]
								ZC0->ZC0_HRFIM  := aDadAux[nX,nPosHrFim]
								ZC0->ZC0_DTFIM  := aDadAux[nX,nPosDtFim]
								ZC0->ZC0_USRFIM := "veros"
							ZC0->(MsUnLock())
							
							if ZC0->ZC0_QTPROD > 0 .or. ZC0->ZC0_QTPERD > 0

								INCLUI := .F.
								ALTERA := .T.
								
								_nRecSH6 := 0
								_nRecZC0 := ZC0->( Recno() )
								
								U_FXACDFIM(1)
								ZC0->(dbGoTo(_nRecZC0))
								U_FXACDFIM(2)
								
								// Se deu problema volta estado anterior
								if _nRecSH6 == 0
									
									//RecLock("ZC0", .F.)
									//	ZC0->ZC0_QTPROD := 0
									//	ZC0->ZC0_QTPERD := 0
									//	ZC0->ZC0_HRFIM  := ""
									//	ZC0->ZC0_DTFIM  := CtoD("")
									//	ZC0->ZC0_USRFIM := ""
									//ZC0->(MsUnLock())
									
									_cMsgLog += ">> Falha ao apontar final da OP " + Alltrim(aDadAux[nX,nPosOp]) + "." + Chr(13) + Chr(10)
									
									cMensagem := Chr(13) + Chr(10)
									cMensagem += Chr(13) + Chr(10)
									cMensagem += "Data: " + DtoC(dDataBase) + Chr(13) + Chr(10)
									cMensagem += "Hora: " + Time() + Chr(13) + Chr(10)
									cMensagem += "OP: " + Alltrim(aDadAux[nX,nPosOp]) + Chr(13) + Chr(10)
									cMensagem += Chr(13) + Chr(10)
									cMensagem += Chr(13) + Chr(10)
									cMensagem += "Registro de Log: "
									cMensagem += Chr(13) + Chr(10)
									cMensagem += ">> Falha ao apontar final da OP " + Alltrim(aDadAux[nX,nPosOp]) + "." + Chr(13) + Chr(10)
									cMensagem += Chr(13) + Chr(10)
									cMensagem += Chr(13) + Chr(10)
									
									_aErro := GetAutoGrLog()
									
									for nCount := 1 To Len(_aErro)
										_cMsgLog += _aErro[nCount] + Chr(13) + Chr(10)
										cMensagem += _aErro[nCount] + Chr(13) + Chr(10)
									next nCount
									
									Conout(cMensagem)

									cEventID := "906"
									cTitulo := "[VEROS] - Erro apontamento OP"
									EventInsert(FW_EV_CHANEL_ENVIRONMENT, FW_EV_CATEGORY_MODULES, cEventID, FW_EV_LEVEL_INFO,"",cTitulo,cMensagem,.T.)
								
								else
									_cMsgLog += ">> Apontamento final da OP " + Alltrim(aDadAux[nX,nPosOp]) + " efetuado." + Chr(13) + Chr(10)
								endif

							else
								_cMsgLog += ">> Somente apontamento de tempo da OP " + Alltrim(aDadAux[nX,nPosOp]) + " efetuado." + Chr(13) + Chr(10)
							endif
							
						else
							_cMsgLog += ">> Apontamento final da OP " + Alltrim(aDadAux[nX,nPosOp]) + " já existe." + Chr(13) + Chr(10)
						endif
						
					endif
				
				endif
				
			Else
				_cMsgLog += ">> Ordem de Producao " + Alltrim(aDadAux[nX,nPosOp]) + " nao encontrada." + Chr(13) + Chr(10)
			Endif
		
		Next
		
	Endif
	
	restArea(aArea)

Return
