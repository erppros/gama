#Include 'protheus.ch'
#Include 'parmtype.ch'
#Include "RestFul.CH"
#include "TOPCONN.CH"

WSRESTFUL productionOrders DESCRIPTION "Integracao de Ordens de Produção"
    
    WSDATA CCONTENT		As String
    WSDATA CFIELDC2		As String
    WSDATA CFIELDG2		As String
    WSDATA CFIELDB1		As String

	WSMETHOD GET  findOrder DESCRIPTION "Busca as Ordens de Produção" WSSYNTAX "/findOrder" PATH "/findOrder" PRODUCES APPLICATION_JSON


END WSRESTFUL

WSMETHOD GET findOrder WSRECEIVE CCONTENT,CFIELDC2,CFIELDG2,CFIELDB1 WSSERVICE productionOrders
    Local CCONTENT	:= ''
    Local CFIELDC2	:= ''
    Local CFIELDG2	:= ''
    Local CFIELDB1	:= ''
	Local jResponse := JsonObject():New()

    Private lSuccess := .T.

    CCONTENT := UPPER(IIF(!Empty(Self:CCONTENT),Self:CCONTENT,""))
    CFIELDC2 := UPPER(IIF(!Empty(Self:CFIELDC2),Self:CFIELDC2,""))
    CFIELDG2 := UPPER(IIF(!Empty(Self:CFIELDG2),Self:CFIELDG2,""))
    CFIELDB1 := UPPER(IIF(!Empty(Self:CFIELDB1),Self:CFIELDB1,""))

    self:SetContentType('application/json')

    if !Empty(CCONTENT)

    	jResponse:=U_FB101VER(CCONTENT,CFIELDC2,CFIELDG2,CFIELDB1)
	
    ENDIF

    if jResponse <> Nil

        self:setresponse(jResponse:tojson())

    ENDIF

Return .T.
