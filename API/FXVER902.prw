#Include "Protheus.ch"
#Include "Parmtype.ch"
#Include "Restful.ch"
#Include "tbiconn.ch"
#Include "fileio.ch"
#Include "FWEVENTVIEWCONSTS.CH"

/***********************************************************************************
|----------------------------------------------------------------------------------|
|* Programa   | FXVER902                                        Data | 19/09/22 | *|
|----------------------------------------------------------------------------------|
|* Autor      | Tree Space - Evolução em Negócios                                 *|
|----------------------------------------------------------------------------------|
|* Utilização | Faturamento -> Atualizações -> Diversos -> Int. Veros             *|
|----------------------------------------------------------------------------------|
|* Descricao  | Rotina genérica com funções de integração Protheus x Veros.       *|
|*            |                                                                   *|
|----------------------------------------------------------------------------------|
***********************************************************************************/

User Function FXVER902()

  Local nHdl := -1

  Private _cMsgLog := ""
  Private _cCRLF := Chr(13) + Chr(10)

  RpcSetType(3)

	PREPARE ENVIRONMENT EMPRESA '01' FILIAL '01' USER 'veros' PASSWORD 'a2gia3.1' TABLES 'SB1,SC2,SG2,CYN'
		
		CONOUT("INICIO FXVER902")
		
		nHdl := U__Sem101FAT("Integra_Veros_API_902")
		if nHdl == 0 
			RESET ENVIRONMENT
			return
		endif
		
		_cMsgLog += ">> Inicio processamento " + DtoC(Date()) + " - " + Time() + _cCRLF

    Conout('Cadastro OPs')
    intCadOP()
    
    _cMsgLog += _cCRLF + ">> Processamento concluido " + DtoC(Date()) + " - " + Time() + _cCRLF
		
		CONOUT(_cMsgLog)

    if nHdl > 0
      U__Sem101FAT(nHdl)
      nHdl := 0
    endif
    
    CONOUT("FIM FXVER902")
  
  RESET ENVIRONMENT

Return

/***********************************************************************************
|----------------------------------------------------------------------------------|
|* Função     | intCadOP                                        Data | 19/09/22 | *|
|----------------------------------------------------------------------------------|
|* Autor      | Tree Space - Evolução em Negócios                                 *|
|----------------------------------------------------------------------------------|
|* Descricao  | Serviço Veros: cadastroOrdemProducao.                             *|
|*            | POST 192.168.0.23:8090/integra_h/cadastroOrdemProducao            *|
|----------------------------------------------------------------------------------|
***********************************************************************************/

Static Function intCadOP()

	Local aArea := GetArea()
	
	Local cQuant := ""
  Local cQry := ""

  Local cJsonEnv := ""
	Local cUrlAux := "192.168.0.23:8090/integra_h/cadastroOrdemProducao"

	Local nTimeOut := 120
	Local aHeadOut := {}
	Local cHeadRet := ""
	Local sPostRet := ""

	aADD(aHeadOut, "User-Agent: Mozilla/4.0 (compatible; Protheus "+GetBuild()+")")
	aADD(aHeadOut, "Content-Type: application/json")
	aADD(aHeadOut, "Accept: application/json")
  
  //*****************************************************************
  // Efetua a busca das Ordens de Produção que devem ir para o Veros
  //*****************************************************************
  
  if Select("TRB") > 0
    TRB->(dbCloseArea())
  endif
  
  cQry := " SELECT TOP 25 SC2.C2_NUM, SC2.C2_ITEM, SC2.C2_SEQUEN, SC2.C2_PRODUTO, SB1.B1_DESC, SC2.C2_QUANT, SB1.B1_UM, SC2.C2_ROTEIRO, SC2.C2_DATPRF, SC2.C2_OBS, SC2.C2_PEDIDO "
  cQry += " FROM "+RetSqlName("SC2")+" SC2 INNER JOIN "+RetSqlName("SB1")+" SB1 ON SB1.B1_COD = SC2.C2_PRODUTO "
  cQry += " WHERE SC2.D_E_L_E_T_ = ' ' "
  cQry += "   AND SB1.D_E_L_E_T_ = ' ' "
  cQry += "   AND SC2.C2_DATRF = '' "
  cQry += "   AND SC2.C2_FILIAL = '"+xFilial("SC2")+"' "
  cQry += "   AND SC2.C2_TPOP = 'F' "
	cQry += "   AND SC2.C2_EMISSAO >= '20221101' "
  cQry += "   AND SC2.C2_SCODI <> 'S' "
  //cQry += "   AND SC2.C2_NUM = 'S56920' "
  cQry += "   AND EXISTS (SELECT SG2.G2_CODIGO FROM "+RetSqlName("SG2")+" SG2 WHERE SG2.G2_FILIAL = '"+xFilial("SG2")+"' AND SG2.G2_PRODUTO = SC2.C2_PRODUTO AND SG2.G2_CODIGO = SC2.C2_ROTEIRO) "
  
  dbUseArea(.T.,"TOPCONN",TcGenQry(,,cQry),"TRB",.F.,.T.)
	
	dbSelectArea("SC2")
	SC2->(dbSetOrder(1)) // C2_FILIAL+C2_NUM+C2_ITEM+C2_SEQUEN+C2_ITEMGRD

  dbSelectArea("SG2")
  SG2->(dbSetOrder(1)) // G2_FILIAL+G2_PRODUTO+G2_CODIGO+G2_OPERAC

  dbSelectArea("SH3")
  SH3->(dbSetOrder(1)) // H3_FILIAL+H3_PRODUTO+H3_CODIGO+H3_OPERAC+H3_RECALTE

	dbSelectArea("TRB")
	TRB->(dbGoTop())
	
	if !TRB->(EoF())
    
		while !TRB->(EoF())
			
			if SC2->(MsSeek( xFilial("SC2") + TRB->C2_NUM + TRB->C2_ITEM + TRB->C2_SEQUEN ))

				cJsonEnv := '{' + _cCRLF
				cJsonEnv += '  "ordens": [' + _cCRLF
			
				cQuant := StrTran(StrTran(Alltrim(Transform(TRB->C2_QUANT,"@E 999,999,999.99")),".",""),",",".")
        cDtEnt := StrTran(DtoC(StoD(TRB->C2_DATPRF)),"/",".")

        cJsonEnv += '    {' + _cCRLF
        cJsonEnv += '      "id_ordem": "'+SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN+'",' + _cCRLF
        cJsonEnv += '      "id_item": "'+Alltrim(SC2->C2_PRODUTO)+'",' + _cCRLF
        cJsonEnv += '      "descricao_item": "'+Alltrim(TRB->B1_DESC)+'",' + _cCRLF
        cJsonEnv += '      "qtd_ordem": '+cQuant+',' + _cCRLF
        cJsonEnv += '      "data_entrega": "'+cDtEnt+'",' + _cCRLF
        cJsonEnv += '      "pedido": "'+Alltrim(TRB->C2_PEDIDO)+'",' + _cCRLF
        cJsonEnv += '      "urgente": 0,' + _cCRLF
        cJsonEnv += '      "comentario": "'+StrTran(Alltrim(TRB->C2_OBS),'"','')+'",' + _cCRLF
        cJsonEnv += '      "operacoes": [' + _cCRLF
        
        if SG2->(MsSeek( xFilial("SG2") + SC2->C2_PRODUTO ))
        
          while !SG2->(EoF()) .AND. SG2->G2_FILIAL + SG2->G2_PRODUTO == xFilial("SG2") + SC2->C2_PRODUTO
          
            cDescAux := StrTran(Alltrim(SG2->G2_DESCRI),'"','')
            
            cJsonEnv += '        {' + _cCRLF
            cJsonEnv += '          "id_operacao": '+Alltrim(str(SG2->(Recno())))+',' + _cCRLF
            cJsonEnv += '          "descricao_operacao": "'+Alltrim(cDescAux) + " " + Alltrim(SG2->G2_RECURSO) +'",' + _cCRLF
            cJsonEnv += '          "seq": "'+Alltrim(SG2->G2_OPERAC)+'",' + _cCRLF
            cJsonEnv += '          "tempo_setup": 0.0,' + _cCRLF
            cJsonEnv += '          "tempo_operacao": '+Alltrim(str(( SG2->G2_TEMPAD / SG2->G2_LOTEPAD )*60))+',' + _cCRLF
            
            if Alltrim(SG2->G2_CODIGO) == Alltrim(SC2->C2_ROTEIRO)
              cJsonEnv += '          "roteiro": "*'+Alltrim(SG2->G2_CODIGO)+'",' + _cCRLF
            else
              cJsonEnv += '          "roteiro": "'+Alltrim(SG2->G2_CODIGO)+'",' + _cCRLF
            endif
            
            cJsonEnv += '          "obs": "",' + _cCRLF
            cJsonEnv += '          "multiplicador": ' + Alltrim(str(1)) + _cCRLF
            cJsonEnv += '        },' + _cCRLF
            
            /*
            if SH3->(MsSeek( xFilial("SH3") + SG2->G2_PRODUTO + SG2->G2_CODIGO + SG2->G2_OPERAC ))

              while !SH3->(EoF()) .AND. SH3->H3_FILIAL + SH3->H3_PRODUTO + SH3->H3_CODIGO + SH3->H3_OPERAC == xFilial("SH3") + SG2->G2_PRODUTO + SG2->G2_CODIGO + SG2->G2_OPERAC

                cJsonEnv += '        {' + _cCRLF
                cJsonEnv += '          "id_operacao": '+Alltrim(str(SG2->(Recno())))+',' + _cCRLF
                cJsonEnv += '          "descricao_operacao": "'+Alltrim(SG2->G2_DESCRI) + " " + Alltrim(SH3->H3_RECALTE) +'",' + _cCRLF
                cJsonEnv += '          "seq": "'+Alltrim(SG2->G2_OPERAC)+'",' + _cCRLF
                cJsonEnv += '          "tempo_setup": 0.0,' + _cCRLF
                cJsonEnv += '          "tempo_operacao": '+Alltrim(str(( SG2->G2_TEMPAD / SH3->H3_LOTPAD )*60))+',' + _cCRLF
                cJsonEnv += '          "roteiro": "'+Alltrim(SG2->G2_CODIGO)+'",' + _cCRLF
                cJsonEnv += '          "obs": "",' + _cCRLF
                cJsonEnv += '          "multiplicador": ' + Alltrim(str(1)) + _cCRLF
                cJsonEnv += '        },' + _cCRLF

                SH3->(dbSkip())
              enddo

            endif
            */

            SG2->(dbSkip())
          enddo
        
        else

          _cMsgLog += ">>>> Ordem de Producao: " + TRB->C2_NUM + TRB->C2_ITEM + TRB->C2_SEQUEN + " erro ao exportar: " + "Produto sem roteiro de operações" + _cCRLF
          TRB->(dbSkip())
          LOOP

        endif

				cJsonEnv := Left(cJsonEnv, len(cJsonEnv) - 3) + _cCRLF
        
        cJsonEnv += '      ]' + _cCRLF
        cJsonEnv += '    }' + _cCRLF

				cJsonEnv += '  ]' + _cCRLF
				cJsonEnv += '}' + _cCRLF

				cJsonEnv := NoAcento(cJsonEnv)

        Conout('')
        Conout(cJsonEnv)
        Conout('')

				sPostRet := HttpPost(cUrlAux,,cJsonEnv,nTimeOut,aHeadOut,@cHeadRet)

				if !empty(sPostRet)

					sPostRet := NoAcento(sPostRet)

					if '"stat":"1"' $ sPostRet
						_cMsgLog += ">>>> Ordem de Producao: " + TRB->C2_NUM + TRB->C2_ITEM + TRB->C2_SEQUEN + " exportada: " + sPostRet + _cCRLF

						RecLock("SC2", .F.)
							SC2->C2_SCODI := "S"
						SC2->(MsUnLock())

					else
						
            if '"a ordem ja esta cadastrada"' $ sPostRet
              RecLock("SC2", .F.)
                SC2->C2_SCODI := "S"
              SC2->(MsUnLock())
            endif
            
            _cMsgLog += ">>>> Ordem de Producao: " + TRB->C2_NUM + TRB->C2_ITEM + TRB->C2_SEQUEN + " erro ao exportar: " + sPostRet + _cCRLF

					endif
					
				endif
				
			endif
			
			TRB->(dbSkip())
		enddo

	endif

	restArea(aArea)

Return

Static Function NoAcento(cString)

	Local cChar  := ""
	Local nX     := 0 
	Local nY     := 0
	Local cVogal := "aeiouAEIOU"
	Local cAgudo := "áéíóú"+"ÁÉÍÓÚ"
	Local cCircu := "âêîôû"+"ÂÊÎÔÛ"
	Local cTrema := "äëïöü"+"ÄËÏÖÜ"
	Local cCrase := "àèìòù"+"ÀÈÌÒÙ" 
	Local cTio   := "ãõÃÕ"
	Local cCecid := "çÇ"
	Local cMaior := "&lt;"
	Local cMenor := "&gt;"
	
	For nX:= 1 To Len(cString)
		cChar:=SubStr(cString, nX, 1)
		IF cChar$cAgudo+cCircu+cTrema+cCecid+cTio+cCrase
			nY:= At(cChar,cAgudo)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCircu)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cTrema)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf
			nY:= At(cChar,cCrase)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr(cVogal,nY,1))
			EndIf		
			nY:= At(cChar,cTio)
			If nY > 0          
				cString := StrTran(cString,cChar,SubStr("aoAO",nY,1))
			EndIf		
			nY:= At(cChar,cCecid)
			If nY > 0
				cString := StrTran(cString,cChar,SubStr("cC",nY,1))
			EndIf
		Endif
	Next
	
	If cMaior$ cString 
		cString := strTran( cString, cMaior, "" ) 
	EndIf
	If cMenor$ cString 
		cString := strTran( cString, cMenor, "" )
	EndIf
	
	cString := StrTran( cString, CRLF, " " )

Return cString
