#INCLUDE 'TOTVS.CH'
#INCLUDE 'PROTHEUS.CH'

/*/{Protheus.doc} User Function MT120ISC
    P.E. Atualiza P. Compra Com dados da Solicitacao de Compra
    @type  Function
    @author Roberta Neukamp Guerreiro
    @since 02/05/2025
/*/
User Function MT120ISC()
	Local _aArea     := GetArea()

	GdFieldPut("C7_ZUNMED",SC1->C1_ZUNMED)

	RestArea(_aArea)
Return

