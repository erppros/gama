#INCLUDE "PROTHEUS.CH"

/*/{Protheus.doc} MT416FIM
Ponto de entrada executado após o termino da efetivação do Orçamento de Venda.
@type user function
@author user
@since 02/06/2025
/*/
User Function MTA416PV()
	Local aArea := GetArea()

    dbSelectArea("SA1")
	dbSetOrder(1)

    If SA1->(MsSeek(xFilial("SA1")+M->C5_CLIENTE+M->C5_LOJACLI))

        M->C5_NATUREZ := AllTrim(SA1->A1_NATUREZ)
        M->C5_ZNOME := AllTrim(SA1->A1_NOME)

    EndIf

	RestArea(aArea)

Return
