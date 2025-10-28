#Include "Protheus.ch"
#Include "Parmtype.ch"
#Include "tbiconn.ch"
#Include "fileio.ch"
#Include "FWEVENTVIEWCONSTS.CH"

/***********************************************************************************
|----------------------------------------------------------------------------------|
|* Programa   | FXVER901                                        Data | 07/09/20 | *|
|----------------------------------------------------------------------------------|
|* Autor      | 4Fx Soluções em Tecnologia                                        *|
|----------------------------------------------------------------------------------|
|* Utilização | PCP -> Atualizações -> **************                             *|
|----------------------------------------------------------------------------------|
|* Descricao  | Rotina de integração Protheus x Veros.                            *|
|*            |                                                                   *|
|----------------------------------------------------------------------------------|
***********************************************************************************/

User Function FXVER901()
	
	Local aServ := {{"001", "entrada_compras",         .T., "E"},;
	                {"002", "produtos",                .T., "E"},;
									{"003", "informacao_movimentacao", .T., "I"},;
	                {"004", "solicitacao_compra",      .T., "I"}}
	                
	Local nX := 0
	
	Local cFunAux := ""
	Private _cMsgLog := ""
	
	Private _aDadAux := {}
	Private _cCRLF := Chr(13) + Chr(10)
	
	Private _cFolderOut := "/folder_veros/saida/"
	Private _cFolder := "/folder_veros/entrada/"
	Private _cSrvVeros := "\\srvveros\Dados\"
	
	Private nTimeOut := 120
	Private aHeadOut := {}
	Private cHeadRet := ""
	Private sPostRet := ""
	
	Private cJSONSnd := ""
	
	Private _cFilC2 := 	" AND SC2.C2_EMISSAO >= '20190930' " 
	
	Private nHdlSem := 0
	Private _nHdl := 0
	
	Private _lSchedule := .F.
	
	if "WFLAUNCHER" $ _PCham()
		_lSchedule := .T.
	endif

	if _lSchedule
		RpcSetType(3)
		PREPARE ENVIRONMENT EMPRESA '01' FILIAL '01' USER 'veros' PASSWORD 'a2gia3.1' TABLES 'SB1,SC2,SG2,CYN'

		CONOUT("INICIO FXVER901")
	else
		MsgInfo("INICIO FXVER901")
	endif
	
	nHdlSem := U__Sem101FAT("Integra_Veros")
	If nHdlSem == 0 
		RESET ENVIRONMENT
		Return
	Endif
	
	_cMsgLog += ">> Inicio processamento " + DtoC(Date()) + " - " + Time() + _cCRLF
	
	//*******************************************************************
	// Copio todos os arquivos do servidor Veros para o Servidor Protheus
	//*******************************************************************
	_aFiles := Directory(_cSrvVeros+'*.*','S',,.F.)
	
	For nX:=1 to len(_aFiles)
		
		cArqTxt := _aFiles[nX,1]

		if "MOV_" $ UPPER(cArqTxt) .or. "PED_" $ UPPER(cArqTxt)

			// Copia o arquivo
			__COPYFILE( _cSrvVeros+cArqTxt, _cFolder+cArqTxt )
			
			If File(_cFolder+cArqTxt)
				fErase(_cSrvVeros+cArqTxt)
			Endif
		
		endif
		
	Next
	
	For nX := 1 to len(aServ)
		
		_aDadAux := {}
		
		// Se estiver habilitado
		If aServ[nX,3]
			
			_cMsgLog += _cCRLF + ">> Iniciando Servico " + aServ[nX,2] + _cCRLF
			
			cFunAux := "FXVER" + aServ[nX,1] + "()"
			&(cFunAux)
							
		Endif
		
	Next nX
	
	_cMsgLog += _cCRLF + ">> Processamento concluido " + DtoC(Date()) + " - " + Time() + _cCRLF
	
	if "Falha" $ _cMsgLog
		cEventID := "906"
		cTitulo := "[Veros] - Verifique erros da integração"
		EventInsert(FW_EV_CHANEL_ENVIRONMENT, FW_EV_CATEGORY_MODULES, cEventID, FW_EV_LEVEL_INFO,"",cTitulo,_cMsgLog,.T.)
	endif
	
	if _lSchedule
		CONOUT(_cMsgLog)
	else
		MsgInfo(_cMsgLog)
	endif
	
	_nHdl := fCreate( _cFolder + "/log/int_veros_"+StrTran(DtoC(dDataBase),'/','_')+"_"+StrTran(Time(),':','_')+".log", 0)

	If _nHdl == -1
		if _lSchedule
			CONOUT("O Arquivo de log não foi criado:" + STR(FERROR()))
		else
			MsgInfo("O Arquivo de log não foi criado:" + STR(FERROR()))
		endif
	Else
		fSeek(_nHdl, 0, 2)      // Encontra final do arquivo
		fWrite(_nHdl, _cMsgLog + CHR(13) + CHR(10))
	Endif
	
	fClose(_nHdl)
	
	TRB->(dbCloseArea())

	//********************************************************************
	// Copio todos os arquivos do Servidor Protheus para o servidor Veros
	//********************************************************************
	_aFiles := Directory(_cFolderOut+'*.*','S',,.F.)
	
	For nX:=1 to len(_aFiles)
		
		cArqTxt := _aFiles[nX,1]

		// Copia o arquivo
		__COPYFILE( _cFolderOut+cArqTxt, _cSrvVeros+cArqTxt )

		If File(_cSrvVeros+cArqTxt)
			fErase(_cFolderOut+cArqTxt)
		Endif

	Next
	
	If nHdlSem > 0
		U__Sem101FAT(nHdlSem)
		nHdlSem := 0
	Endif

	if _lSchedule
		CONOUT("FIM FXVER901")
		RESET ENVIRONMENT
	else
		MsgInfo("FIM FXVER901")
	endif

Return

/***********************************************************************************
|----------------------------------------------------------------------------------|
|* Função     | FXCODI001                                       Data | 03/08/19 | *|
|----------------------------------------------------------------------------------|   
|* Autor      | 4Fx Soluções em Tecnologia                                        *|
|----------------------------------------------------------------------------------|
|* Descricao  | Serviço CODI: unidadeMedida.        				              *|
|*            |                                                                   *|
|----------------------------------------------------------------------------------|
***********************************************************************************/

Static Function FXVER001()

	Local aArea := GetArea()
	Local aDadAux := {}
	Local cSep := ";"
	Local cCRLF := Chr(13) + Chr(10)

	Local cFileName := _cFolderOut + "CMP_" + StrZero(Year(dDataBase),4) + "." + StrZero(Month(dDataBase),2) + "." + StrZero(Day(dDataBase),2) + "," + StrTran(Time(),":",".") + ".txt"

	Local cQry := ""
	Local dDtEmis := CtoD("")
	
	//****************************************************************
	// Efetua a busca dos produtos para integração com Veros
	//****************************************************************
	
	If Select("TRB") > 0
		TRB->(dbCloseArea())
	Endif

	cQry := " SELECT SD1.R_E_C_N_O_, SD1.D1_COD, SB1.B1_DESC, SD1.D1_DOC, SD1.D1_FORNECE, SA2.A2_NOME, SD1.D1_UM, SD1.D1_QUANT, SD1.D1_EMISSAO, SD1.D1_TOTAL "
	cQry += " FROM "+RetSqlName("SD1")+" SD1 INNER JOIN "+RetSqlName("SB1")+" SB1 ON SB1.B1_COD = SD1.D1_COD "
	cQry += "                                INNER JOIN "+RetSqlName("SA2")+" SA2 ON SA2.A2_COD = SD1.D1_FORNECE AND SA2.A2_LOJA = SD1.D1_LOJA "
	cQry += " WHERE SD1.D_E_L_E_T_ = ' ' "
	cQry += "   AND SB1.D_E_L_E_T_ = ' ' "
	cQry += "   AND SA2.D_E_L_E_T_ = ' ' "
	cQry += "   AND SD1.D1_FILIAL = '010101' "
	cQry += "   AND SD1.D1_EMISSAO >= '20200820' "
	cQry += "   AND SD1.D1_TIPO = 'N' "
	cQry += "   AND SD1.D1_TES <> ' ' "
	cQry += "   AND SD1.D1_SVEROS <> 'S' "
	cQry += "   AND (SB1.B1_GRUPO = '4010' OR SB1.B1_GRUPO = '4020') "

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"TRB",.F.,.T.)

	TRB->(dbGoTop())
	
	If !TRB->(EoF())

		nHdl := fCreate(cFileName)
		
		If nHdl == -1
			MsgAlert("O arquivo de nome "+cFileName+" nao pode ser executado! Verifique os parametros.","Atencao!")
			Return
		Endif

		cLine := "ID" + cSep
		cLine += "COD_PROTHEUS" + cSep
		cLine += "DESCRICAO_ITEM" + cSep
		cLine += "MARCA_ITEM" + cSep
		cLine += "COD_FORNECEDOR" + cSep
		cLine += "NOME_FORNECEDOR" + cSep
		cLine += "UNIDADE_MEDIDA" + cSep
		cLine += "QTD_MINIMA" + cSep
		cLine += "QTD_COMPRA" + cSep
		cLine += "DATA_HORA_COMPRA" + cSep
		cLine += "VALOR_COMPRA" + cSep
		cLine += "ARMAZEN" + cSep
		cLine += "ARMARIO" + cSep
		cLine += "PRATELEIRA" + cSep
		cLine += "RECIPIENTE" + cSep
		cLine += cCRLF

		fWrite(nHdl,cLine,Len(cLine))
		
		While !TRB->(EoF())
			
			aDadAux := {}

			dDtEmis := StoD(TRB->D1_EMISSAO)
			
			cLine := Alltrim(Str(TRB->R_E_C_N_O_)) + cSep
			cLine += Alltrim(TRB->D1_COD) + cSep
			cLine += Alltrim(TRB->B1_DESC) + cSep
			cLine += '' + cSep
			cLine += Alltrim(TRB->D1_FORNECE) + cSep
			cLine += Alltrim(TRB->A2_NOME) + cSep
			cLine += Alltrim(UPPER(TRB->D1_UM)) + cSep
			cLine += Alltrim(Str(0)) + cSep
			cLine += Alltrim(Str(TRB->D1_QUANT)) + cSep
			cLine += StrZero(Day(dDtEmis),2) + "." + StrZero(Month(dDtEmis),2) + "." + Alltrim(Str(Year(dDtEmis))) + ",00.00.00" + cSep
			cLine += Alltrim(Str(TRB->D1_TOTAL)) + cSep
			cLine += '' + cSep
			cLine += '' + cSep
			cLine += '' + cSep
			cLine += '' + cSep
			cLine += cCRLF
			
			fWrite(nHdl,cLine,Len(cLine))

			dbSelectArea("SD1")
			SD1->(dbGoTo(TRB->R_E_C_N_O_))

			if SD1->(Recno()) == TRB->R_E_C_N_O_

				RecLock("SD1", .F.)
					SD1->D1_SVEROS := "S"
				SD1->(MsUnLock())
			
			endif
			
			_cMsgLog += ">>>> Entrada de Material: " + Alltrim(TRB->D1_COD) + " - " + Alltrim(TRB->D1_DOC) + " exportado." + _cCRLF
			
			TRB->(dbSkip())
		Enddo
		
		fClose(nHdl)

	Endif

	restArea(aArea)


Return

/***********************************************************************************
|----------------------------------------------------------------------------------|
|* Função     | FXVER002                                        Data | 18/09/20 | *|
|----------------------------------------------------------------------------------|   
|* Autor      | 4Fx Soluções em Tecnologia                                        *|
|----------------------------------------------------------------------------------|
|* Descricao  | Serviço Veros: produtos.                    				              *|
|*            |                                                                   *|
|----------------------------------------------------------------------------------|
***********************************************************************************/

Static Function FXVER002()

	Local aArea := GetArea()
	Local aDadAux := {}
	Local cSep := ";"
	Local cCRLF := Chr(13) + Chr(10)

	Local cFileName := _cFolderOut + "CAD_" + StrZero(Year(dDataBase),4) + "." + StrZero(Month(dDataBase),2) + "." + StrZero(Day(dDataBase),2) + "," + StrTran(Time(),":",".") + ".txt"
	//Local cFileName := _cFolderOut + "CAD_" + StrTran(DtoC(dDataBase),'/','_')+"_"+StrTran(Time(),':','_')+".txt"

	Local cQry := ""
	
	//****************************************************************
	// Efetua a busca dos produtos para integração com Veros
	//****************************************************************
	
	If Select("TRB") > 0
		TRB->(dbCloseArea())
	Endif
	
	cQry := " SELECT TOP 50 SB1.R_E_C_N_O_ as RECNO, SB1.B1_COD, SB1.B1_DESC, SB1.B1_UM "
	cQry += " FROM "+RetSqlName("SB1")+" SB1 "
	cQry += " WHERE SB1.D_E_L_E_T_ = ' ' "
	cQry += "   AND SB1.B1_SVEROS <> 'S' "
	cQry += "   AND SB1.B1_MSBLQL = '2' "
	cQry += "   AND (SB1.B1_GRUPO = '4010' OR SB1.B1_GRUPO = '4020') "

	dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"TRB",.F.,.T.)

	TRB->(dbGoTop())
	
	If !TRB->(EoF())

		nHdl := fCreate(cFileName)
		
		If nHdl == -1
			MsgAlert("O arquivo de nome "+cFileName+" nao pode ser executado! Verifique os parametros.","Atencao!")
			Return
		Endif

		cLine := "ID" + cSep
		cLine += "COD_PROTHEUS" + cSep
		cLine += "DESCRICAO_ITEM" + cSep
		cLine += "UNIDADE_MEDIDA" + cSep
		cLine += cCRLF
		
		fWrite(nHdl,cLine,Len(cLine))
		
		While !TRB->(EoF())
			
			aDadAux := {}
			
			cLine := Alltrim(Str(TRB->RECNO)) + cSep
			cLine += Alltrim(TRB->B1_COD) + cSep
			cLine += Alltrim(TRB->B1_DESC) + cSep
			cLine += Alltrim(UPPER(TRB->B1_UM)) + cSep
			cLine += cCRLF
			
			fWrite(nHdl,cLine,Len(cLine))

			dbSelectArea("SB1")
			SB1->(dbGoTo(TRB->RECNO))

			if SB1->(Recno()) == TRB->RECNO

				RecLock("SB1", .F.)
					SB1->B1_SVEROS := "S"
				SB1->(MsUnLock())
			
			endif
			
			_cMsgLog += ">>>> Produto: " + Alltrim(TRB->B1_COD) + " exportado." + _cCRLF
			
			TRB->(dbSkip())
		Enddo
		
		fClose(nHdl)

	Endif

	restArea(aArea)
	
Return

/***********************************************************************************
|----------------------------------------------------------------------------------|
|* Função     | FXVER003                                        Data | 07/09/20 | *|
|----------------------------------------------------------------------------------|
|* Autor      | 4Fx Soluções em Tecnologia                                        *|
|----------------------------------------------------------------------------------|
|* Descricao  | Serviço Veros: movimentações.                                     *|
|*            |                                                                   *|
|----------------------------------------------------------------------------------|
***********************************************************************************/

Static Function FXVER003()
	
	Local aArea := GetArea()
	Local aDadAux := {}
	Local aArray := {}
	Local cArqTxt := ""
	Local cSepara := ";"
	
	Local nX := 0
	Local cCodSA := ""
	Local cCodPR := ""
	
	Local nPosId := 1
	Local nPosPrd := 2
	Local nPosOper := 3
	Local nPosQtd := 4
	Local nPosDtPed := 5

	Local aItens := {}
	Local lOk := .F.
	Local aBaixaAux := {}
	
	Local aFiles := Directory(_cFolder+'*.txt','S',,.F.)

	PRIVATE l185Auto := .T.
	
  /* 
   ID;
   COD_PROTHEUS;
   COD_FORNECEDOR;
   QTD;
   DATA_HORA
  */

	//************************************
	// Efetua a leitura dos arquivos .txt
	//************************************
	
	For nX:=1 to len(aFiles)
		
		aDadAux := {}
		
		If "MOV_" $ UPPER(aFiles[nX,1])
			
			cArqTxt := _cFolder + aFiles[nX,1]
			
			If !File(cArqTxt)
				//Conout("Arquivo inválido: " + cArqTxt)
				MsgInfo("Arquivo inválido: " + cArqTxt)
				LOOP
			Endif
			
			FT_FUSE(cArqTxt)
			ProcRegua(FT_FLASTREC())
			FT_FGOTOP()
			
			While !FT_FEoF()
				
				cLine  := FT_FReadLn()
				aArray := StrTokArr(cLine,cSepara)
				
				if len(aArray) > 0
					aADD(aDadAux, aArray)
				endif
				
				FT_FSkip()
			Enddo
			
			FT_FUse()

			//************************************
			// Geração das Solicitações de Compra
			//************************************
			
			If len(aDadAux) > 0

				lOk := .F.
				
				_cMsgLog += ">> Processando " + Alltrim(Str(len(aDadAux))) + " registros de movimentações." + Chr(13) + Chr(10)
				
				dbSelectArea("SB1")
				SB1->(dbSetOrder(1)) // B1_FILIAL+B1_COD
				
				For nX:=1 to len(aDadAux)
				
					// ** Verifico a existência do Produto
					If SB1->(MsSeek( xFilial("SB1") + Alltrim(aDadAux[nX,nPosPrd]) ))
						
						aADD(aItens, { SB1->B1_COD, Val(aDadAux[nX,nPosQtd]), Alltrim(aDadAux[nX,nPosOper]) })
						
					Else
						_cMsgLog += ">> Produto " + Alltrim(aDadAux[nX,nPosPrd]) + " nao encontrado." + Chr(13) + Chr(10)
					Endif
				
				Next

				cCodSA := GeraSA(aItens)

				if !Empty(cCodSA)

					_cMsgLog += ">> Solicitação ao Armazém gerada com sucesso: " + Alltrim(cCodSA) + Chr(13) + Chr(10)

					// Efetua liberação da SA
					lSALib := _A107Lib(cCodSA)

					if lSALib

						_cMsgLog += ">> Liberação da SA efetuada com sucesso." + Chr(13) + Chr(10)

						GeraPR(cCodSA)
						
						dbSelectArea("SCQ")
						SCQ->(dbSetOrder(1)) // CQ_FILIAL+CQ_NUM+CQ_ITEM+CQ_NUMSQ

						if SCQ->(MsSeek( xFilial("SCQ") + cCodSA ))
							
							_cMsgLog += ">> Pré-Requisição gerada com sucesso: " + Alltrim(cCodSA) + Chr(13) + Chr(10)

							aBaixaAux := BaixaPR(cCodSA)
							
							if !aBaixaAux[1]
								_cMsgLog += ">> Falha ao baixar Pré-Requisição: " + Alltrim(cCodSA) + Chr(13) + Chr(10)
								_cMsgLog += aBaixaAux[2]
							else
								_cMsgLog += ">> Pré-Requisição baixada com sucesso: " + Alltrim(cCodSA) + Chr(13) + Chr(10)
							endif

							lOk := .T.

						else
							_cMsgLog += ">> Falha ao gerar Solicitação ao Armazém." + Chr(13) + Chr(10)
							lOk := .F.
						endif
					
					else
						_cMsgLog += ">> Falha ao liberar Solicitação ao Armazém." + Chr(13) + Chr(10)
						lOk := .F.
					endif

				else
					_cMsgLog += ">> Falha ao gerar Solicitação ao Armazém." + Chr(13) + Chr(10)
					lOk := .F.
				endif
				
			Endif

			if lOk

				// Mover arquivo para processadas
				_cArqProc := cArqTxt
				_cArqNew := StrTran(_cArqProc,'/entrada/','/entrada/processados/')
				
				__COPYFILE( _cArqProc, _cArqNew )
				
				If File(_cArqNew)
					fErase(_cArqProc)
				Endif
			
			endif
			
		Endif
		
	Next
	
	restArea(aArea)

Return

/***********************************************************************************
|----------------------------------------------------------------------------------|
|* Função     | FXVER004                                        Data | 07/09/20 | *|
|----------------------------------------------------------------------------------|
|* Autor      | 4Fx Soluções em Tecnologia                                        *|
|----------------------------------------------------------------------------------|
|* Descricao  | Serviço Veros: solicitacao_compra.           				              *|
|*            |                                                                   *|
|----------------------------------------------------------------------------------|
***********************************************************************************/

Static Function FXVER004()
	
	Local aArea := GetArea()
	Local aDadAux := {}
	Local aArray := {}
	Local cArqTxt := ""
	Local cSepara := ";"
	
	Local nX := 0
	
	Local nPosId := 1
	Local nPosPrd := 2
	Local nPosOper := 3
	Local nPosQtd := 4
	Local nPosDtPed := 5

	Local aItens := {}
	
	Local aFiles := Directory(_cFolder+'*.txt','S',,.F.)
	
  /* 
   ID;
   COD_PROTHEUS;
   COD_FORNECEDOR;
   QTD;
   DATA_PEDIDO
  */

	//************************************
	// Efetua a leitura dos arquivos .txt
	//************************************
	
	For nX:=1 to len(aFiles)
		
		aDadAux := {}
		
		If "PED_" $ UPPER(aFiles[nX,1])
			
			cArqTxt := _cFolder + aFiles[nX,1]
			
			If !File(cArqTxt)
				//Conout("Arquivo inválido: " + cArqTxt)
				MsgInfo("Arquivo inválido: " + cArqTxt)
				LOOP
			Endif
			
			FT_FUSE(cArqTxt)
			ProcRegua(FT_FLASTREC())
			FT_FGOTOP()
			
			While !FT_FEoF()
				
				cLine  := FT_FReadLn()
				aArray := StrTokArr(cLine,cSepara)
				
				if len(aArray) > 0
					aADD(aDadAux, aArray)
				endif
				
				FT_FSkip()
			Enddo
			
			FT_FUse()

			//************************************
			// Geração das Solicitações de Compra
			//************************************
			
			If len(aDadAux) > 0
				
				_cMsgLog += ">> Processando " + Alltrim(Str(len(aDadAux))) + " registros de solicitações de compra." + Chr(13) + Chr(10)
				
				dbSelectArea("SC1")
				SC1->(dbSetOrder(1)) // C2_FILIAL+C2_NUM+C2_ITEM+C2_SEQUEN+C2_ITEMGRD
				
				dbSelectArea("SB1")
				SB1->(dbSetOrder(1)) // B1_FILIAL+B1_COD
				
				For nX:=1 to len(aDadAux)
				
					// ** Verifico a existência do Produto
					If SB1->(MsSeek( xFilial("SB1") + Alltrim(aDadAux[nX,nPosPrd]) ))
						
						aADD(aItens, { SB1->B1_COD, Val(aDadAux[nX,nPosQtd]) })
						
					Else
						_cMsgLog += ">> Produto " + Alltrim(aDadAux[nX,nPosPrd]) + " nao encontrado." + Chr(13) + Chr(10)
					Endif
				
				Next

				GeraSC(aItens)
				
			Endif

			// Mover arquivo para processadas
			_cArqProc := cArqTxt
			_cArqNew := StrTran(_cArqProc,'/entrada/','/entrada/processados/')
			
			__COPYFILE( _cArqProc, _cArqNew )
			
			If File(_cArqNew)
				fErase(_cArqProc)
			Endif
			
		Endif
		
	Next
	
	restArea(aArea)

Return

/***********************************************************************************
|----------------------------------------------------------------------------------|
|* Função     | GeraSC                                          Data | 15/10/20 | *|
|----------------------------------------------------------------------------------|
|* Autor      | 4Fx Soluções em Tecnologia                                        *|
|----------------------------------------------------------------------------------|
|* Descricao  | Rotina para geração das Solicitações de Compra - Veros.           *|
|*            |                                                                   *|
|----------------------------------------------------------------------------------|
***********************************************************************************/

Static Function GeraSC(aProd)

	Local aCabec := {}
	Local aItens := {}
	Local aLinha := {}
	
	Local nX := 0
	Local cDoc := ""
	Local lRet := .F.
	
	Private lMsHelpAuto := .T.
	Private lMsErroAuto := .F.
	
	aCabec := {}
	aItens := {}
	
	cDoc := GetSXENum("SC1","C1_NUM")
	SC1->(dbSetOrder(1))
	
	aADD(aCabec, {"C1_NUM",     cDoc} )
	aADD(aCabec, {"C1_SOLICIT", "Veros"} )
	aADD(aCabec, {"C1_EMISSAO", dDataBase} )
	
	For nX := 1 To len(aProd)

		aLinha := {}
		
		aADD(aLinha, {"C1_ITEM",    StrZero(nX,len(SC1->C1_ITEM)), Nil} )
		aADD(aLinha, {"C1_PRODUTO", aProd[nX,1],                   Nil} )
		aADD(aLinha, {"C1_QUANT",   aProd[nX,2],                   Nil} )
		aADD(aLinha, {"C1_LOCAL",   "ALC",                         Nil} )
		
		aADD(aItens, aLinha)
	
	Next nX

	lMsHelpAuto := .T.
	lMsErroAuto := .F.
	lAutoErrNoFile := .T.
	
	MsExecAuto({|x,y| MATA110(x,y)}, aCabec, aItens)
	
	If !lMsErroAuto
		Conout(OemToAnsi("Incluido com sucesso! ")+cDoc)
		lRet := .T.
	Else
		Conout(OemToAnsi("Erro na inclusao!"))
		
		_cMsgLog += ">> Erro ao incluir solicitação de compra." + _cCRLF
		
		_aErro := GetAutoGrLog()
		
		For nCount := 1 To Len(_aErro)
			_cMsgLog += _aErro[nCount] + Chr(13) + Chr(10)
		Next nCount
		
		//MostraErro()
		lRet := .F.
	EndIf

Return lRet

/***********************************************************************************
|----------------------------------------------------------------------------------|
|* Função     | GeraSA                                          Data | 15/10/20 | *|
|----------------------------------------------------------------------------------|
|* Autor      | 4Fx Soluções em Tecnologia                                        *|
|----------------------------------------------------------------------------------|
|* Descricao  | Rotina para geração das Solicitações ao Armazém - Veros.          *|
|*            |                                                                   *|
|----------------------------------------------------------------------------------|
***********************************************************************************/

Static Function GeraSA(aProd)

	Local cRet := ""
	Local aCab := {}
	Local aItens := {}
	Local nSaveSx8 := 0
	Local cNumero := ''
	Local nOpcx := 0

	Local cLocal := ""
	Local cCentroC := ""
	Local cFinalid := ""
	Local nSaldo := 0

	Local nQtd := 0

	Private lMsErroAuto := .F.
	Private lMsErroHelp := .T.
	
	nOpcx := 3
	cNumero := GetSx8Num('SCP', 'CP_NUM')

	dbSelectArea('SB1')
	SB1->(dbSetOrder(1)) // B1_FILIAL+B1_COD
	
	dbSelectArea('SCP')
	SCP->(dbSetOrder(1)) // CP_FILIAL+CP_NUM+CP_ITEM+DTOS(CP_EMISSAO)

	dbSelectArea('SB2')
	SB2->(dbSetOrder(1)) // B2_FILIAL+B2_COD+B2_LOCAL
	
	aADD(aCab, {"CP_NUM",     cNumero,   Nil })
	aADD(aCab, {"CP_EMISSAO", dDataBase, Nil })
	aADD(aCab, {"CP_SOLICIT", "Veros",   Nil })
	
	//U_ShowArray(aProd)

	for nX := 1 To len(aProd)

		aLinha := {}

		cCentroC := getCC(Alltrim(aProd[nX,3]))

		cLocal := "PRO"
		
		if SB2->(MsSeek( xFilial("SB2") + Padr(aProd[nX,1],TamSX3("B1_COD")[1]) + "ALC" ))

			nSaldo := SaldoSB2()

			if nSaldo >= aProd[nX,2]
				cLocal := "ALC"
			endif
			
		endif
		
		cFinalid := getFinalid(aProd[nX,1])

		nQtd := aProd[nX,2]

		if nQtd < 0

			nQtd := nQtd * -1
		
			aADD(aLinha, {"CP_ITEM",    StrZero(nX,len(SCP->CP_ITEM)), Nil} )
			aADD(aLinha, {"CP_PRODUTO", aProd[nX,1],                   Nil} )
			aADD(aLinha, {"CP_QUANT",   nQtd,                          Nil} )
			aADD(aLinha, {"CP_CC",      cCentroC,                      Nil} )
			aADD(aLinha, {"CP_LOCAL",   cLocal,                        Nil} )
			aADD(aLinha, {"CP_STPMOV",  cFinalid,                      Nil} )
			
			aADD(aItens, aLinha)
		
		endif
	
	next nX

	lMsHelpAuto := .T.
	lMsErroAuto := .F.
	lAutoErrNoFile := .T.

	MsExecAuto({ |x,y,z| MATA105(x,y,z) }, aCab, aItens, nOpcx)
	
	if lMsErroAuto
		MsgStop('Erro ao Executar o Processo')
		
		_cMsgLog += ">> Erro ao incluir solicitação de compra." + _cCRLF
		
		_aErro := GetAutoGrLog()
		
		For nCount := 1 To Len(_aErro)
			_cMsgLog += _aErro[nCount] + Chr(13) + Chr(10)
		Next nCount
		
		//MostraErro()
		cRet := ""
	else
		cRet := cNumero
	endIf

Return cRet

/***********************************************************************************
|----------------------------------------------------------------------------------|
|* Função     | getCC                                           Data | 22/10/20 | *|
|----------------------------------------------------------------------------------|
|* Autor      | 4Fx Soluções em Tecnologia                                        *|
|----------------------------------------------------------------------------------|
|* Descricao  | Relação entre Operadores x Centros de Custo.                      *|
|*            |                                                                   *|
|----------------------------------------------------------------------------------|
***********************************************************************************/

Static Function getCC(cOper)

	Local cCC := ""
	
	if cOper == "CNC01"
		cCC := "20040201"
	elseif cOper == "CNC02"
		cCC := "20040201"
	elseif cOper == "CNC03"
		cCC := "20040201"
	elseif cOper == "CNC04"
		cCC := "20040201"
	elseif cOper == "CNC05"
		cCC := "20040201"
	elseif cOper == "CNC06"
		cCC := "20040201"
	elseif cOper == "CNC07"
		cCC := "20040201"
	elseif cOper == "CNC08"
		cCC := "20040201"
	elseif cOper == "CNC09"
		cCC := "20040201"
	elseif cOper == "CNC10"
		cCC := "20040201"
	elseif cOper == "CNC11"
		cCC := "20040201"
	elseif cOper == "CNC12"
		cCC := "20040201"
	elseif cOper == "CNC13"
		cCC := "20040201"
	elseif cOper == "CNC14"
		cCC := "20040201"
	elseif cOper == "CNC15"
		cCC := "20040201"
	elseif cOper == "CNC16"
		cCC := "20040201"
	elseif cOper == "CNC17"
		cCC := "20040201"
	elseif cOper == "CNC18"
		cCC := "20040201"
	elseif cOper == "CNC19"
		cCC := "20040201"
	elseif cOper == "CNC20"
		cCC := "20040201"
	elseif cOper == "CONF01"
		cCC := "20040201"
	elseif cOper == "CONF02"
		cCC := "20040201"
	elseif cOper == "FRECN1"
		cCC := "20040205"
	elseif cOper == "FRECNC"
		cCC := "20040205"
	elseif cOper == "TC07"
		cCC := "20040200"
	elseif cOper == "TC08"
		cCC := "20040200"
	elseif cOper == "TC09"
		cCC := "20040200"
	elseif cOper == "TC10"
		cCC := "20040200"
	elseif cOper == "TC11"
		cCC := "20040200"
	elseif cOper == "TC12"
		cCC := "20040200"
	elseif cOper == "TC13"
		cCC := "20040200"
	elseif cOper == "TC14"
		cCC := "20040200"
	elseif cOper == "DES01"
		cCC := "20040200"
	elseif cOper == "ESM01"
		cCC := "20040200"
	elseif cOper == "ESM02"
		cCC := "20040200"
	elseif cOper == "FREMAN"
		cCC := "20040200"
	elseif cOper == "FUR01"
		cCC := "20040200"
	elseif cOper == "FUR02"
		cCC := "20040200"
	elseif cOper == "FUR03"
		cCC := "20040200"
	elseif cOper == "FUR04"
		cCC := "20040200"
	elseif cOper == "FUR05"
		cCC := "20040200"
	elseif cOper == "LAV01"
		cCC := "20040200"
	elseif cOper == "LAV02"
		cCC := "20040200"
	elseif cOper == "LIX01"
		cCC := "20040200"
	elseif cOper == "LIX02"
		cCC := "20040200"
	elseif cOper == "LM01"
		cCC := "20040200"
	elseif cOper == "M07"
		cCC := "20040200"
	elseif cOper == "M09"
		cCC := "20040200"
	elseif cOper == "PH07"
		cCC := "20040200"
	elseif cOper == "PM04"
		cCC := "20040200"
	elseif cOper == "PM05"
		cCC := "20040200"
	elseif cOper == "SEC01"
		cCC := "20040200"
	elseif cOper == "SEC02"
		cCC := "20040200"
	elseif cOper == "TA01"
		cCC := "20040200"
	elseif cOper == "BU01"
		cCC := "20040200"
	elseif cOper == "BU02"
		cCC := "20040200"
	elseif cOper == "BU03"
		cCC := "20040200"
	elseif cOper == "DOB01"
		cCC := "20040200"
	elseif cOper == "M06"
		cCC := "20040200"
	elseif cOper == "DOB02"
		cCC := "20040202"
	elseif cOper == "JAT01"
		cCC := "20040202"
	elseif cOper == "ME01"
		cCC := "20040202"
	elseif cOper == "ME02"
		cCC := "20040202"
	elseif cOper == "ME03"
		cCC := "20040202"
	elseif cOper == "PH01"
		cCC := "20040202"
	elseif cOper == "PH02"
		cCC := "20040202"
	elseif cOper == "PH03"
		cCC := "20040202"
	elseif cOper == "PH04"
		cCC := "20040202"
	elseif cOper == "PH05"
		cCC := "20040202"
	elseif cOper == "PH06"
		cCC := "20040202"
	elseif cOper == "PH08"
		cCC := "20040202"
	elseif cOper == "PH09"
		cCC := "20040202"
	elseif cOper == "PH10"
		cCC := "20040202"
	elseif cOper == "PM01"
		cCC := "20040202"
	elseif cOper == "SOL01"
		cCC := "20040202"
	elseif cOper == "SOL02"
		cCC := "20040202"
	elseif cOper == "SOL03"
		cCC := "20040202"
	elseif cOper == "TR01"
		cCC := "20040202"
	elseif cOper == "DSC01"
		cCC := "20040203"
	elseif cOper == "M01"
		cCC := "20040203"
	elseif cOper == "M02"
		cCC := "20040203"
	elseif cOper == "M03"
		cCC := "20040203"
	elseif cOper == "M04"
		cCC := "20040203"
	elseif cOper == "M05"
		cCC := "20040203"
	elseif cOper == "M08"
		cCC := "20040203"
	elseif cOper == "M10"
		cCC := "20040203"
	elseif cOper == "M11"
		cCC := "20040203"
	elseif cOper == "M12"
		cCC := "20040203"
	elseif cOper == "M14"
		cCC := "20040203"
	elseif cOper == "M15"
		cCC := "20040203"
	elseif cOper == "MON02"
		cCC := "20040203"
	elseif cOper == "P-CAB"
		cCC := "20040203"
	elseif cOper == "P-CAB1"
		cCC := "20040203"
	elseif cOper == "P-CAB2"
		cCC := "20040203"
	elseif cOper == "P-CAB3"
		cCC := "20040203"
	elseif cOper == "P-CAB4"
		cCC := "20040203"
	elseif cOper == "P-CAB5"
		cCC := "20040203"
	elseif cOper == "P-CAB6"
		cCC := "20040203"
	elseif cOper == "EMB01"
		cCC := "20040204"
	elseif cOper == "AXBLI"
		cCC := "20040204"
	elseif cOper == "AXSKI"
		cCC := "20040204"
	elseif cOper == "AXSEL"
		cCC := "20040204"
	elseif cOper == "AXSEL2"
		cCC := "20040204"
	elseif cOper == "MON03"
		cCC := "20050200"
	elseif cOper == "MON04"
		cCC := "20050200"
	elseif cOper == "B.EXT"
		cCC := "99999999"
	endif
	
Return cCC

/***********************************************************************************
|----------------------------------------------------------------------------------|
|* Função     | getFinalid                                      Data | 22/10/20 | *|
|----------------------------------------------------------------------------------|
|* Autor      | 4Fx Soluções em Tecnologia                                        *|
|----------------------------------------------------------------------------------|
|* Descricao  | Relação entre Produtos x Finalidades.                             *|
|*            |                                                                   *|
|----------------------------------------------------------------------------------|
***********************************************************************************/

Static Function getFinalid(cProd)

	Local cFinalid := "01"

	if Alltrim(cProd) == "4010.2245" .OR. Alltrim(cProd) == "4021.0017" .OR. Alltrim(cProd) == "4021.0031" .OR. ;
	   Alltrim(cProd) == "4021.0012" .OR. Alltrim(cProd) == "4010.2217" .OR. Alltrim(cProd) == "4010.0002" .OR. ;
	   Alltrim(cProd) == "4021.0011" .OR. Alltrim(cProd) == "4021.0015" .OR. Alltrim(cProd) == "4021.0043"

		 cFinalid := "03"

	endif

Return cFinalid

/***********************************************************************************
|----------------------------------------------------------------------------------|
|* Função     | GeraPR                                          Data | 15/10/20 | *|
|----------------------------------------------------------------------------------|
|* Autor      | 4Fx Soluções em Tecnologia                                        *|
|----------------------------------------------------------------------------------|
|* Descricao  | Rotina para geração das Solicitações ao Armazém - Veros.          *|
|*            |                                                                   *|
|----------------------------------------------------------------------------------|
***********************************************************************************/

Static Function GeraPR(cPreReq)

	Local lMarkB, lDtNec
	Local BFiltro
	Local lConsSPed, lGeraSC1, lAmzSA
	Local cSldAmzIni, cSldAmzFim
	Local lLtEco, lConsEmp
	Local nAglutSC
	Local lAuto, lEstSeg
	Local aRecSCP
	Local lRateio

	Private _cPreReq := cPreReq
	BFiltro := {|| SCP->CP_NUM == _cPreReq }
	
	Pergunte("MTA106",.F.)

	lMarkB     := .F.
	lDtNec     := (MV_PAR01 == 1)
	lConsSPed  := (MV_PAR02 == 1)
	lGeraSC1   := (MV_PAR03 == 1)
	lAmzSA     := (MV_PAR04 == 1)
	cSldAmzIni := MV_PAR05
	cSldAmzFim := MV_PAR06
	lLtEco     := (MV_PAR07 == 1)
	lConsEmp   := (MV_PAR08 == 1)
	nAglutSC   := MV_PAR09
	lAuto      := .T.
	lEstSeg    := (MV_PAR10 == 1)
	aRecSCP    := {}
	lRateio    := .F.

	MaSAPreReq(lMarkB,lDtNec,BFiltro,lConsSPed,lGeraSC1,lAmzSA,cSldAmzIni,cSldAmzFim,lLtEco,lConsEmp,nAglutSC,lAuto,lEstSeg,@aRecSCP,lRateio)

Return

/***********************************************************************************
|----------------------------------------------------------------------------------|
|* Função     | BaixaPR                                         Data | 15/10/20 | *|
|----------------------------------------------------------------------------------|
|* Autor      | 4Fx Soluções em Tecnologia                                        *|
|----------------------------------------------------------------------------------|
|* Descricao  | Rotina para baixa da pre-requisicao - Veros                       *|
|*            |                                                                   *|
|----------------------------------------------------------------------------------|
***********************************************************************************/

Static Function BaixaPR(cNumSA)

	Local aArea := GetArea()

	Local aCamposSCP
	Local aCamposSD3
	Local aRelProj

	Local lRet := .T.
	Local nX := 0
	Local cMsgAux := ""

	dbSelectArea("SCP")
	SCP->(dbSetOrder(1))

	if SCP->(MsSeek( xFilial("SCP") + cNumSA ))

		while !SCP->(EoF()) .AND. SCP->CP_FILIAL + SCP->CP_NUM == xFilial("SCP") + cNumSA

			_aAreaCP := SCP->(GetArea())

			aCamposSCP := { {"CP_NUM",     SCP->CP_NUM,     Nil },;
											{"CP_ITEM",    SCP->CP_ITEM,    Nil },;
											{"CP_QUANT",   SCP->CP_QUANT,   Nil }}
																		
			aCamposSD3 := { {"D3_TM",      "544",           Nil },; // Tipo do Mov. 
											{"D3_COD",     SCP->CP_PRODUTO, Nil },;
											{"D3_LOCAL",   SCP->CP_LOCAL,   Nil },;
											{"D3_LOCALIZ", SCP->CP_LOCAL,   Nil },;
											{"D3_DOC",     "",              Nil },; // No.do Docto.
											{"D3_EMISSAO", DDATABASE,       Nil }}

			aRelProj := {}

			lMsHelpAuto := .T.
			lMsErroAuto := .F.
			lAutoErrNoFile := .T.

			MSExecAuto({|v,x,y,z,w| mata185(v,x,y,z,w)},aCamposSCP,aCamposSD3,1)   // 1 = BAIXA (ROT.AUT)

			if lMsErroAuto

				//MostraErro()

				aLogAux := GetAutoGRLog()
				cMsgAux += "--------------------------------------" + CHR(13)+CHR(10)
				
				For nX := 1 To Len(aLogAux)
					cMsgAux += aLogAux[nX] + CHR(13)+CHR(10)
				Next nX

			 	if "AJUDA:A240DOC" $ cMsgAux
					lRet := .T.
				endif

			endif

			restArea(_aAreaCP)
			
			SCP->(dbSkip())
		enddo

	endif

	restArea(aArea)

	/*
	Local aAreaAnt := GetArea()
	Local aCols    := {}
	Local lPreRequ := .F.
	Local lStatus  := .F.
	Local lRet	   := .T.
	Local nQtdSegUm:= 0
	Local nRegist  := SCP->(Recno())

	Local lPIMSInt	:= SuperGetMV("MV_PIMSINT",.F.,.F.)
	Local lMT185BX := .F.

	INCLUI := .T.

	Private aRatAFH:= {}
	Private aRetCQ := {}
	Private nQAtu  := 0

	PRIVATE cNuSATOP := ""
	PRIVATE cITSATOP := ""
	PRIVATE lPermBx  := GetNewPar("MV_BXPRERQ",.F.)
	PRIVATE cMarca
	PRIVATE cCadastro := OemToAnsi("Geracao das Requisicoes")
	PRIVATE aAcho:={}
	PRIVATE cCusMed := GetMv("MV_CUSMED")

	Pergunte("MTA185",.F.)

	dbSelectArea("SCP")
	dbSetOrder(1)
	//cNumSA := CP_NUM
	If dbSeek(xFilial()+cNumSA)
		lMT185BX := ExistBlock("MT185BX")
		While !Eof() .And. xFilial()+cNumSA == CP_FILIAL+CP_NUM
			If !SoftLock("SCP")
				Return .F.
			EndIf
			SB2->(dbSetOrder(1))
			If SB2->(dbSeek(xFilial("SB2")+SCP->CP_PRODUTO+SCP->CP_LOCAL))
				//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
				//³ ca100RetCQ() ----------->                   ³
				//³ [1] -  Saldo do Item                        ³
				//³ [2] -  Quantidade diponivel ja reservada    ³
				//³ [3] -  Quantidade em Processo de Compra     ³
				//³ [4] -  Situacao Atual                       ³
				//³ [5] -  Numero da Solicitacao de Compras     ³
				//³ [6] -  Numero de Requisicao                 ³
				//³ [7] -  Quantidade ja Entregue               ³
				//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
				aRetCQ := ca100RetCQ(SCP->CP_NUM,SCP->CP_ITEM)
			Else
				Help(" ",1,"REGNOIS")
				Return .F.
			EndIf
			If SCP->CP_STATUS == "E"
				lStatus := .T.
				dbSkip()
				Loop
			EndIf
			
			If Empty(SCP->CP_PREREQU)
				lPreRequ := .T.
				dbSkip()
				Loop
			EndIf

			//-- Tratamento para Segunda Unidade de Medida
			nQtdSegUm := IIf(A185SegUm(SCP->CP_PRODUTO)==1,ConvUM(SCP->CP_PRODUTO,aRetCQ[2],0,2),IIf(SCP->CP_QUANT == 0,0,(SCP->CP_QTSEGUM/SCP->CP_QUANT)*aRetCQ[2]))
			
			aAdd(aCols,{	.F.			,;									// Marca de selecao
							CP_NUM		,; 									// Numero da SA
							CP_ITEM		,;									// Item da SA
							CP_PRODUTO	,;									// Produto
							CP_DESCRI	,;									// Descricao do Produto
							CP_LOCAL	,;									// Armazem
							CP_UM		,;									// UM
							Transform(aRetCQ[2],PesqPictQt('D3_QUANT')),;	// Qtd. a Requisitar (Formato Caracter)
							CP_QUANT,; //aRetCQ[2]	,;									// Qtd. a Requisitar
							CP_CC		,;									// Centro de Custo
							CP_SEGUM	,;									// 2a.UM
							nQtdSegUm	,;									// Qtd. 2a.UM
							CP_OP		,;									// Ordem de Producao
							CP_CONTA	,;									// Conta Contabil
							CP_ITEMCTA	,;									// Item Contabil
							CP_CLVL		,;									// Classe Valor
							CriaVar('AFH_PROJET',.F.),; 				 	// Projeto
							CP_NUMOS 	,;									// Nr. da OS
							CriaVar('AFH_TAREFA',.F.),;				 	// Tarefa
							"SCP"	,;										// Alias Walk-Thru
							SCP->(RecNo()) ,;								// Recno Walk-Thru
							Iif(lPIMSInt,CP_NRBPIMS,' ')})								// Numero Boletim PIMS
							
			dbSkip()
		EndDo

	Else
		Help(" ",1,"REGNOIS")
		lRet := .F.
	EndIf

	If lRet .And. Len(aCols) == 0 .And. lStatus
		If Inclui //IF utilizado para nao exibir mensagem quando baixada a pre-requisicao
			Help(" ",1,"A185BX")
		EndIf	
		lRet := .F.
	EndIf	
	If lRet .And. Len(aCols) == 0 .And. lPreRequ
		If Inclui //IF utilizado para nao exibir mensagem quando baixada a pre-requisicao
			Help(" ",1,"A185PRE")
		EndIf	
		lRet := .F.
	EndIf	
						
	If lRet .And. Len(aCols) == 0
		lRet := .F.
	EndIf

	If lRet
		dbSelectArea("SCP")
		dbGoTo(nRegist)
		SB2->(dbSetOrder(1))
		If SB2->(dbSeek(xFilial("SB2")+SCP->CP_PRODUTO+SCP->CP_LOCAL))
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ ca100RetCQ() ----------->                   ³
			//³ [1] -  Saldo do Item                        ³
			//³ [2] -  Quantidade diponivel ja reservada    ³
			//³ [3] -  Quantidade em Processo de Compra     ³
			//³ [4] -  Situacao Atual                       ³
			//³ [5] -  Numero da Solicitacao de Compras     ³
			//³ [6] -  Numero de Requisicao                 ³
			//³ [7] -  Quantidade ja Entregue               ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			aRetCQ := ca100RetCQ(SCP->CP_NUM,SCP->CP_ITEM)
		EndIf	
		
		lRet := A185GeraAut(cNumSA,aCols)

	EndIf

	//-- Libera os registros bloqueado pelo SoftLock
	MsUnlockAll()

	RestArea(aAreaAnt)
	*/


Return {lRet,cMsgAux}

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A185SegUM ³ Autor ³ Microsiga S/A         ³ Data ³03.10.2008³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Funcao utilizada para verificar se o produto utiliza       ³±±
±±³          ³ segunda unidade de medida com fator de conversao.          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³A185SegUM(cCod)                                             ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 = Codigo do produto                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ ExpN1 = 1 - Utiliza SegUM com fator de conversao           ³±±
±±³          ³         2 - Utiliza SegUM sem fator de conversao           ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³MATA185                                                     ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function A185SegUm(cCod)

	Local nRet     := 1 //-- Caso não utilize SegUm Forcar ConvUM
	Local aAreaAnt := GetArea()
	Local aAreaSB1 := SB1->(GetArea())
	dbSelectArea("SB1")
	dbSetOrder(1)
	If dbSeek(xFilial("SB1")+cCod)
		If !Empty(SB1->B1_SEGUM) .And. !Empty(SB1->B1_CONV)
			lRet := 1
		ElseIf !Empty(SB1->B1_SEGUM) .And. Empty(SB1->B1_CONV)
			nRet := 2
		EndIf	
	EndIf
	RestArea(aAreaSB1)
	RestArea(aAreaAnt)
	
Return nRet

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A185MudaVl³ Autor ³ Larson Zordan         ³ Data ³22.07.2002³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Atualiza os valores do Resumo do Estoque                   ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ A185MudaVlr(ExpO1,ExpC1,ExpC2,ExpC3,ExpC4,ExpN1,ExpA1,     ³±±
±±³          ³             ExpN2,ExpN3,ExpN4,ExpA2,ExpL1)                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpO1 = Objeto da MsDialog                                 ³±±
±±³          ³ ExpC1 = Numero da SA                                       ³±±
±±³          ³ ExpC2 = Item da SA                                         ³±±
±±³          ³ ExpC3 = Produto                                            ³±±
±±³          ³ ExpC4 = Armazem                                            ³±±
±±³          ³ ExpN1 = Qtd. a Requisitar                                  ³±±
±±³          ³ ExpA1 = Array com valores das Pre-Requisicao               ³±±
±±³          ³ ExpN2 = Saldo Atual                                        ³±±
±±³          ³ ExpN3 = Reserva PV/OP                                      ³±±
±±³          ³ ExpN4 = Qtd. Disponivel                                    ³±±
±±³          ³ ExpA2 = Array das posicoes na Tela                         ³±±
±±³          ³ ExpL1 = Flag indicando se deve atualizar tela              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATA185                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function A185MudaVlr(oDlg,cNumSA,cItSA,cProduto,cLocal,nQtReq,aRetCQ,nQAtu,nQtRes,nQtSal,aPosObj,lTela,oQAtu,oQtRes,oQtSal,oRetCQ,oQtTotal,nQtTotal)

	DEFAULT nQtReq   := 0
	DEFAULT nQAtu    := 0
	DEFAULT nQtRes   := 0
	DEFAULT nQtSal   := 0
	DEFAULT nQtTotal := 0
	DEFAULT lTela    := .T.

	dbSelectArea("SCP")
	dbSeek(xFilial()+cNumSA+cItSA)
	If SB2->(dbSeek(xFilial("SB2")+cProduto+cLocal))
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ ca100RetCQ() ----------->                   ³
		//³ [1] -  Saldo do Item                        ³
		//³ [2] -  Quantidade diponivel ja reservada    ³
		//³ [3] -  Quantidade em Processo de Compra     ³
		//³ [4] -  Situacao Atual                       ³
		//³ [5] -  Numero da Solicitacao de Compras     ³
		//³ [6] -  Numero de Requisicao                 ³
		//³ [7] -  Quantidade ja Entregue               ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		aRetCQ := ca100RetCQ(cNumSA,cItSA)
		nQAtu := SB2->B2_QATU
		nQtRes:= SB2->B2_RESERVA+SB2->B2_QEMP+SB2->B2_QEMPSA+SB2->B2_QACLASS-If(mv_par03==1.And.!Empty(SCP->CP_OP),SCP->CP_QUANT,0)
		nQtSal:= nQAtu - nQtRes
	EndIf

	nQtTotal := If( (mv_par02==2), A185QtProc(cProduto), aRetCQ[3] )

	If lTela                
		oQatu:Refresh()
		oQtRes:Refresh()
		oQtSal:Refresh()
		oRetCq[1]:Refresh() 	
		oRetCq[2]:Refresh() 	
		oQtTotal:Refresh()
	EndIf
	
Return

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A185EdtQtd³ Autor ³ Larson Zordan         ³ Data ³22.07.2002³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Editar o campo Quantidade a Requisitar                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ A185EdtQtd(ExpO1,ExpA1)                                    ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpO1 = Objeto do ListBox                                  ³±±
±±³          ³ ExpA1 = Array com os dados                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ ExpA1 = Array com os dados                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATA185                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function A185EdtQtd( oLbx,aCols )

	Local nVlr1   := aCols[oLbx:nAt,8]
	Local nVlr2   := aCols[oLbx:nAt,9]
	Local cProd   := aCols[oLbx:nAt,4]
	Local cLocal  := aCols[oLbx:nAt,6]
	Local nQtdTot := 0
	Local nX 	    := 0

	aCols[oLbx:nAt,8] := aCols[oLbx:nAt,9]
	lEditCell( aCols, oLbx , PesqPictQt('D3_QUANT'), 8 )
	oLbx:SetFocus()
	aCols[oLbx:nAt,9] := aCols[oLbx:nAt,8]
	aCols[oLbx:nAt,8] := Transform(aCols[oLbx:nAt,8],PesqPictQt('D3_QUANT'))
	For nX := 1 to Len(aCols)
		If aCols[nX,1] .And. cProd == aCols[nX,4] .And. cLocal == aCols[nX,6]
			nQtdTot := nQtdTot + Val(aCols[nX,8])
		EndIf	
	Next nX
	If ! A185QtRequ(aCols[oLbx:nAt,9],aRetCQ[2],aRetCQ[1],nQAtu,(nQtdTot-Val(aCols[oLbx:nAt,8])),,,,@aCols)
		aCols[oLbx:nAt,8] := nVlr1
		aCols[oLbx:nAt,9] := nVlr2
	Else
		//Marca o item para baixa da pre-requisicao	
		aCols[oLbx:nAt,01] := .T.
		aCols[oLbx:nAt,12] :=  IIf(A185SegUm(SCP->CP_PRODUTO)==1,ConvUM(SCP->CP_PRODUTO,aCols[oLbx:nAt,9],0,2),IIf(SCP->CP_QUANT == 0,0,(SCP->CP_QTSEGUM/SCP->CP_QUANT)*aCols[oLbx:nAt,9]))
	EndIf

Return( aCols )

/*/
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A185GeraAu³ Autor ³ Larson Zordan         ³ Data ³23.07.2002³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³ Gera as requisicoes usando o Movimentos Modelo 2           ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Sintaxe   ³ A185GeraAut(ExpC1,ExpA1)			                          ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpC1 = Numero da SA                                       ³±±
±±³          ³ ExpA1 = Array com os dados                                 ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ .T. / .F.                                                  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATA185                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
/*/
Static Function A185GeraAut(cNumSa,aDados,lEnd)

	Local aCopia    := {}
	Local lMov      := .F.
	Local lValZero  := .F.
	Local nX		:= 1
	Local cProjeto	:= ""	
	Local cTarefa	:= ""
	Local cDocumento:= ""
	Local lChangeDoc:= .F.
	Local lGeraBx   := .F.
	Local lCC

	Private bCols     := {|x,y|aCols[x][y]}
	Private cFunc     := "A185Atu2SD3"
	Private a185Dados := aClone(aDados)
	Private aCC       := {}
	Private aAlter    := {}
	Private lMT241GRV := ExistBlock("MT241GRV")
	Private lLogMov   := GetMV("MV_IMPMOV")
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Esta variavel indica se utiliza segunda unidade de medida.   ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Private lUsaSegUm

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Variavel utilizada na rotina de atualizacao da SCQ/SCP/SB2   ³
	//³ disparada pelo MATA241 (controle de transacoes)              ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Private aDadosCQ := {}

	PRIVATE aRotina   := MenuDef()
	
	AEval(aDados, {|z| z[1] := If(z[1]==.T.,.F.,If(z[9]>0,.T.,.F.))})

	//ProcRegua(Len(aDados),23,4)
	For nX := 1 To Len(aDados)
		//IncProc()
		If aDados[nX,1]

			// Atualiza array aRetCQ
			A185MudaVlr(NIL,cNumSA,aDados[NX,3],aDados[nx,4],aDados[nx,6],aDados[nx,9],@aRetCQ,@nQAtu,,,,.F.)
			If Len(aDados[nX]) >= 21		// Incluidos campos ref. Walk-Thru
				cProjeto	:=	aDados[nX,17]
				cTarefa 	:=	aDados[nX,19]
			Else
				cProjeto	:=	""	
				cTarefa		:=	""
			Endif
			If !A185QtRequ(aDados[nX,9],aRetCQ[2],aRetCQ[1],nQAtu,,.F.,cProjeto,cTarefa)
				Exit
			EndIf
			nPos := aScan(aCC,{|x| x == aDados[nX,10]})
			If nPos == 0
				aAdd(aCC,aDados[nX,10])
			EndIf
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Existem itens selecionados              ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			lMov := .T.
			//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
			//³ Verifica se ha itens zerados.           ³
			//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
			lValZero := If(aDados[nX,9]<=0,.T.,lValZero)
		EndIf	
	Next nX

	If !lMov
		Return(.F.)
	EndIf

	If lValZero
		Help(" ",1,"VALZERADO")
		Return(.F.)
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se ha mais de um centro de custo. ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	lCC := If(Len(aCC)>1,.T.,.F.)

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Notifica o usuario sobre o uso de mais de  ³
	//| um Centro de Custo na Pre-Requisicao.      |
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If lCC
		If !MsgYesNo(	OemToAnsi("Esta Pre-Requisicao tem diversos Centros de Custos cadastrados.")+CHR(13)+; 			//"Esta Pre-Requisicao tem diversos Centros de Custos cadastrados."
						OemToAnsi("Portanto,  ao continuar a rotina,  voce devera digitar o Centro")+CHR(13)+; 			//"Portanto,  ao continuar a rotina,  voce devera digitar o Centro"
						OemToAnsi("de Custo adequado para os itens requisitados.")+CHR(13)+CHR(13)+;	//"de Custo adequado para os itens requisitados."
						OemToAnsi("Deseja continuar o processo de requisicao ?"))						//"Deseja continuar o processo de requisicao ?"
			Return(.F.)
		EndIf
	EndIf


	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Verifica se o custo medio e' calculado On-Line.              ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	If cCusMed == "O"
		Private nHdlPrv 			// Endereco do arquivo de contra prova dos lanctos cont.
		Private lCriaHeader := .T.	// Para criar o header do arquivo Contra Prova
		Private cLoteEst 			// Numero do lote para lancamentos do estoque
		//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
		//³ Posiciona numero do Lote para Lancamentos do Estoque.        ³
		//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
		dbSelectArea("SX5")
		dbSeek(xFilial()+"09EST")
		cLoteEst:=IIF(Found(),Trim(X5Descri()),"EST ")
		PRIVATE nTotal := 0 		// Total dos lancamentos contabeis
		PRIVATE cArquivo			// Nome do arquivo contra prova
	EndIf

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Estas variaveis indicam para as funcoes de validacao qual    ³
	//³ programa as esta' chamando.                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Private l241Auto := .F., l250Auto := .F.
	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Estas variaveis indicam para as funcoes de validacao qual    ³
	//³ programa as esta' chamando.                                  ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	Private l240:=.F.,l250:=.F.,l241:=.T.,l242:=.F.,l261:=.F.,l185 :=.T.

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Atualiza Pergunta MTA240						³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	A185AtuPer(1)

	aCopia  := aClone(aRotina)
	aRotina := {}
	For nX := 1 To 5	// Walk_Thru
		aAdd(aRotina,{ "" , "        ", 0 , 6} )
	Next

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ A funcao A241Inclui abrira a transacao e gravara as informacoes da tabela SD3.    ³
	//³ Se estiver tudo certo, ela executara a funcao A185AtuSCQ que atualizara as demais ³
	//³ tabelas realizando corretamente o controle de transacao. Toda a operacao estara   ³
	//³ em uma unica transacao aberta e finalizada pelo MATA241.                          ³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	//Variavel private a ser usada pela A185AtuSCQ
	aDadosCQ := aClone(aDados)
	dbSelectArea("SD3")
	dbSetOrder(1)
	
	CXFUNC := "A185Atu2SD3"
	lGeraBx := ( A241Inclui("SD3",0,1,@cDocumento,@lChangeDoc) == 1 )

	//ÚÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ¿
	//³ Atualiza Pergunta MTA185						³
	//ÀÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ
	A185AtuPer(2)

	aRotina := aClone(aCopia)

	If lChangeDoc
		Help("",1,"A240DOC",,cDocumento,4,30)  // No.Docto. foi alterado
	EndIf

Return(.T.)

Static Function _PCham()

	Local _i      := 0
	Local _sPilha := ""
	Do While procname (_i) != ""
		_sPilha += chr (13) + chr (10) + procname (_i)
		_i++
	Enddo

Return(_sPilha)

/*
ÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜÜ
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
±±ÚÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÂÄÄÄÄÄÄÂÄÄÄÄÄÄÄÄÄÄ¿±±
±±³Fun‡…o    ³A185AtuPer³ Autor ³ Marcos V. Ferreira    ³ Data ³10/03/2005³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄ´±±
±±³Descri‡…o ³Atualiza o pergunte para chamada das funcoes A240INCLUI e   ³±±
±±³			 ³A241INCLUI												  ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Parametros³ ExpN1 - Tipo de configuracao de tecla F12	              ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³Retorno   ³ Nenhum                                                     ³±±
±±ÃÄÄÄÄÄÄÄÄÄÄÅÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄ´±±
±±³ Uso      ³ MATA185                                                    ³±±
±±ÀÄÄÄÄÄÄÄÄÄÄÁÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÄÙ±±
±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±±
ßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßßß
*/
Static Function A185AtuPer(nTipo)
Default nTipo := 0

If nTipo == 1
	Pergunte("MTA240",.F.)
	If cCusMed <> "O"
		If !l185Auto
			SetKey(VK_F12, {|| MTA185PERG()})
		EndIf
	EndIf
 ElseIf nTipo == 2
	Pergunte("MTA185",.F.)
	If cCusMed <> "O"
		If !l185Auto
			SetKey(VK_F12, {|| MTA185PERG()})
		EndIf
	EndIf
EndIf

Return

Static Function MenuDef()

Private aRotina	:=  {	{OemToAnsi("Pesquisar"),"AxPesqui"  , 0 , 1,0,.F.},;		//"Pesquisar"
						{OemToAnsi("Visualizar"),"A241Visual", 0 , 2,0,nil},;		//"Visualizar"
						{OemToAnsi("Incluir"),"A241Inclui", 0 , 3,0,nil},;		//"Incluir"
						{OemToAnsi("Estornar"),"A241Estorn", 0 , 6,0,nil},;		//"Estornar"
						{OemToAnsi("Tracker Contábil"),"CTBC662"   , 0 , 7,0,Nil},;		//"Tracker Contábil"
						{OemToAnsi("Legenda"),"A240Legenda", 0 , 2,0,.F.} }		//"Legenda"

Return (aRotina)


Static Function _A107Lib(cCodSA)

	Local aArea    := GetArea()
	Local aAreaSCW := SCW->(GetArea())
	Local aAreaSCP := SCP->(GetArea())
	Local aInfoSAI := {}
	Local lRet	   := .T.                   
	Local bWhen	   := NIL
	Local cChave   := ""  
	
	cChave := xFilial("SCP") + cCodSA
	SCP->(dbSetOrder(1))
	SCP->(dbSeek(cChave))
	bWhen  := {|| !SCP->(EOF()) .And. SCP->(CP_FILIAL+CP_NUM) == cChave}
	
	While Eval(bWhen)
	
		If lRet
			Begin Transaction
				dbSelectArea("SCP")
				RecLock("SCP",.F.)
				SCP->CP_STATSA := "L"
				MsUnlock()
				MaVldSolic(SCP->CP_PRODUTO,UsrRetGrp(),RetCodUsr(),.F.,0,,@aInfoSAI)
				If !Empty(aInfoSAI)
					AtuSalSCW(aInfoSAI[1], aInfoSAI[2], aInfoSAI[3], aInfoSAI[4], aInfoSAI[6])
				EndIf     
				
			End Transaction
		EndIf
		SCP->(dbSkip())
	End

	dbSelectArea("SCP")
	SCP->(dbSetOrder(1))

	if SCP->(MsSeek( xFilial("SCP") + cCodSA ))
		
		if SCP->CP_STATSA == "L"
			lRet := .T.
		else
			lRet := .F.
		endif

	else
		lRet := .F.
	endif
	
	RestArea(aAreaSCP)
	RestArea(aAreaSCW)
	RestArea(aArea)

Return lRet
