#INCLUDE 'protheus.ch'
#INCLUDE 'TOPCONN.CH'


/*/{Protheus.doc} MT410TOK
Ponto de entrada para alerta quando for salvar o pedido com produtos genéricos
@type user function
@author Roberta Neukamp Guerreiro
@since 02/07/2025
/*/
User Function MT410TOK()

	Local nOpc := PARAMIXB[1]
	Local lRet := .T. // Conteúdo de retorno
	Local nPosProd   := AScan(aHeader,{|x| AllTrim(x[2]) == 'C6_PRODUTO'})
	Local nI

	IF nOpc == 3 .or. nOpc == 4

		For nI := 1 to Len(aCols)
			If "ORC" $ aCols[nI][nPosProd]
                lRet := .F.
			EndIf
		Next nI

		If !lRet

			If FwAlertYesNo("Salvar mesmo assim?", "Esta sendo utilizado produtos genericos nesse pedido. Lembre-se de ajustar!")
				lRet := .T.
			Else
				lRet := .F.
			EndIf

		EndIf

	ENDIF


Return (lRet)
