#Include "protheus.ch"
#include "rwmake.ch"
#include "topconn.ch"

#DEFINE MAXMENLIN  100                                            // Mximo de caracteres por linha de dados adicionais
/*/{Protheus.doc} PE01NFESEFAZ
Ponto de Entrada para customização da NFe
@type user function
@author Roberta Neukamp Guerreiro  
@since 02/07/2025
/*/

User Function PE01NFESEFAZ()
	Local aArea:= GetArea()
	Local aRet:= {}
	Local aSD2:= SD2->(GetArea())
	Local aSC5:= SC5->(GetArea())
	Local aSC6:= SC6->(GetArea())
	Local aSF4:= SF4->(GetArea())
	Local aSA3:= SA3->(GetArea())
	Local aSA4:= SA4->(GetArea())
	Local aSA1:= SA1->(GetArea())

	Local aProd			:= PARAMIXB[1]
	Local cMensCli		:= PARAMIXB[2]
	Local cMensFis		:= PARAMIXB[3]
	Local aDest			:= PARAMIXB[4]
	Local aNota			:= PARAMIXB[5]
	Local aInfoItem		:= PARAMIXB[6]
	Local aDupl			:= PARAMIXB[7]
	Local aTransp		:= PARAMIXB[8]
	Local aEntrega		:= PARAMIXB[9]
	Local aRetirada		:= PARAMIXB[10]
	Local aVeiculo		:= PARAMIXB[11]
	Local aReboque		:= PARAMIXB[12]
	Local aNfVincRur	:= PARAMIXB[13]
	Local aEspVol		:= PARAMIXB[14]
	Local aNfVinc		:= PARAMIXB[15]
	Local aDetPag		:= PARAMIXB[16]
	Local aObsCont		:= PARAMIXB[17]
	Local aProcRef		:= PARAMIXB[18]
	Local _i 			:= 0
	Local _x			:= 0
	Local _aAux 		:= {}
	Local aInfoPed	    := {}

	Local _cMensAdi 	:= ""

	Local cTipo     	:= ""
    Local cPedido       := ""

	cTipo := aNota[4]
    cPedido := SD2->D2_PEDIDO

	If cTipo == "1"
		If !Empty(cMensCli)
			_aAux2 := _Msg(alltrim(cMensCli),MAXMENLIN)
			For _x := 1 to Len(_aAux2)
				aADD(_aAux,_aAux2[_x])
			Next
		Endif

		_cMensAdi := Left(Alltrim(_cMensAdi),Len(Alltrim(_cMensAdi))-1)

		_aAux2 := _Msg(alltrim(_cMensAdi),MAXMENLIN)
		For _x := 1 to Len(_aAux2)
			aADD(_aAux,_aAux2[_x])
		Next

        SC5->(DbSeek(xFilial("SC5") + cPedido))

		AADD(aInfoPed, "Pedido de Venda Gama: " + AllTrim(SC5->C5_NUM))
		AADD(aInfoPed, "Pedido Cliente: " + AllTrim(SC5->C5_ZPEDIDO))

		For _i := 1 to Len(aInfoPed)
			_aAux2 := _Msg(alltrim(aInfoPed[_i]),MAXMENLIN)
			For _x := 1 to Len(_aAux2)
				aADD(_aAux,_aAux2[_x])
			Next
		Next

		cMensCli := ""

		For _i := 1 to Len(_aAux)
			if len(_aAux)>1
				cMensCli += alltrim(_aAux[_i])+ " | "
			else
				cMensCli += alltrim(_aAux[_i])
			ENDIF
		Next

	EndIf



	AADD(aRet, aProd)
	AADD(aRet, cMensCli)
	AADD(aRet, cMensFis)
	AADD(aRet, aDest)
	AADD(aRet, aNota)
	AADD(aRet, aInfoItem)
	AADD(aRet, aDupl)
	AADD(aRet, aTransp)
	AADD(aRet, aEntrega)
	AADD(aRet, aRetirada)
	AADD(aRet, aVeiculo)
	AADD(aRet, aReboque)
	AADD(aRet, aNfVincRur)
	AADD(aRet, aEspVol)
	AADD(aRet, aNfVinc)
	AADD(aRet, aDetPag)
	AADD(aRet, aObsCont)
	AADD(aRet, aProcRef)

	RestArea(aSA4)
	RestArea(aSA3)
	RestArea(aSF4)
	RestArea(aSC6)
	RestArea(aSC5)
	RestArea(aSD2)
	RestArea(aSA1)
	RestArea(aArea)

Return aRet


/*
Função     _MSG      Autor  TOTVS Serra Gacha            Data  19/03/09 
*/

Static Function _MSG(_cObs, _nTam)

	Local _aMsg := {}
	Local _i    := 0

	_cObs := StrTran(_cObs, " ", ";")
	Do While At(";;", _cObs) != 0
		_cObs := StrTran(_cObs, ";;", ";")
	EndDo

	_aObs := {}
	Do While Len(_cObs) > 0
		If At(";", _cObs) != 0
			AADD(_aObs, SubStr(_cObs, 1, At(";", _cObs) -1))
			_cObs := Stuff(_cObs, 1, At(";", _cObs), "")
		Else
			AADD(_aObs, AllTrim(_cObs))
			_cObs := ""
		EndIf
	EndDo

	_cObs := ""
	For _i := 1 To Len(_aObs)
		If Len(_cObs + cValToChar(_aObs[_i])) > _nTam
			AADD(_aMsg, Padr(_cObs,_nTam))
			_cObs := _aObs[_i] + " "
		Else
			_cObs := _cObs + _aObs[_i] + " "
		EndIf
	Next _i

	If AllTrim(_cObs) != ""
		AADD(_aMsg, Padr(_cObs,_nTam))
	EndIf

Return _aMsg
