#include "protheus.ch"
#include "parmtype.ch"
#INCLUDE "FWMVCDEF.CH"

User Function CUSTOMERVENDOR()
    Local aArea  := GetArea()
	Local aParam := PARAMIXB
	Local xRet := .T.
	Local oObj := ""
	Local cIdPonto := ""
	Local cIdModel := ""

	If aParam <> NIL
		oObj := aParam[1]
		cIdPonto := aParam[2]
		cIdModel := aParam[3]
        nOperation := oObj:GetOperation()

		
		If nOperation == MODEL_OPERATION_INSERT .AND. cIdPonto == "FORMPOS"
            
			xRet := U_FB102COM()
            if xRet
                RecLock("SA2", .F.)
				SA2->A2_ITEMCON := 'F' + SA2->A2_COD + SA2->A2_LOJA
				SA2->(MsUnLock())
            EndIf
		EndIf

        
	ENDIF
    RestArea(aArea)
Return xRet

