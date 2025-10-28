#INCLUDE 'TOTVS.CH'
#INCLUDE 'PROTHEUS.CH'
#INCLUDE 'PARMTYPE.CH'
#INCLUDE "RWMAKE.CH"

/*/{Protheus.doc} User Function MA650EMP
    P.E. que irá alimentar os campos das tabelas SC1, SC2 e SD4 dos produtos empenhados da OP.
    @type  Function
    @author Roberta Neukamp Guerreiro
    @since 30/04/2025
/*/
USER FUNCTION MA650EMP()
	Local aItems := aCols //aCols contém as linhas da grid de empenhos que foram processados no momento.
	Local cOp    := SD4->D4_OP //SD4 está posicionada na ultima op gerada
	Local nQuant := Posicione("SC2",1,xFilial("SC2") + cOp,"C2_QUANT")
	Local nX
	Local cAliasSC1 := GetNextAlias()
	Local aArea := GetArea()
	Local cInfo

	dbSelectArea("SG1")

	dbSelectArea("SC2")
	dbSetOrder(9)

	dbSelectArea("SD4")
	dbSetOrder(2)

	dbSelectArea("SC1")
	dbSetOrder(1)

	For nX := 1 to Len(aItems)

		SD4->(MsSeek(xFilial("SD4")+cOp+AllTrim(aItems[nX][1])))

		// SG1->(dbGoTop())
		// SG1->(dbSetOrder(2))
		// If SG1->(MsSeek(xFilial("SG1")+SD4->D4_PRODUTO))
		// 	cInfo := SG1->G1_OBSERV
		// EndIf

		SG1->(dbGoTop())
		SG1->(dbSetOrder(1))
		If SG1->(MsSeek(xFilial("SG1")+SD4->D4_PRODUTO+SD4->D4_COD))
			RecLock("SD4",.F.)
			SD4->D4_ZUNMED := nQuant * SG1->G1_ZUNMED
			MsunLock()
			cInfo := SG1->G1_OBSERV

			//Alimenta o campo C2_ZUNMED através do valor encontrado na SG1
			If SC2->(MsSeek(xFilial("SC2")+Left(cOp,8)+SD4->D4_PRODUTO))
				If SC2->C2_ZUNMED == 0
					RecLock("SC2",.F.)
					SC2->C2_ZUNMED := nQuant * SG1->G1_ZUNMED
					MsunLock()
				EndIf
			EndIf

			// Busca solicitações de compras geradas a partir da OP
			BeginSql Alias cAliasSC1
            SELECT C1_NUM, C1_ITEM, C1_PRODUTO, C1_QUANT, C1_DESCRI
            FROM %Table:SC1% SC1
            WHERE SC1.%NotDel%
            AND SC1.C1_OP = %Exp:cOp%
			AND SC1.C1_PRODUTO = %Exp:SD4->D4_COD%
			EndSql

			// Busco o registro e alimento o campo C1_ZUNMED com o cálculo
			While (cAliasSC1)->(!EOF())
				If SC1->(MsSeek(xFilial("SC1")+(cAliasSC1)->C1_NUM+(cAliasSC1)->C1_ITEM))
					RecLock("SC1",.F.)
					SC1->C1_ZUNMED := nQuant * SG1->G1_ZUNMED
					If !EMPTY(cInfo)
						SC1->C1_DESCRI := AllTrim(SC1->C1_DESCRI) + " - " + AllTrim(cInfo)
					EndIf
					MsunLock()

				EndIf
				(cAliasSC1)->(DbSkip())
			End While
		EndIf

		If SELECT(cAliasSC1) > 0
			(cAliasSC1)->(DbCloseArea())
		EndIf

	Next nX

	SG1->(DbCloseArea())
	SD4->(DbCloseArea())
	SC2->(DbCloseArea())
	SC1->(DbCloseArea())
	RestArea(aArea)

Return
