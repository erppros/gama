
/*/{Protheus.doc} User Function FB101COM
    Gatilho no campo A2_CGC para gerar código sequencial
    quando A2_TIPO = 'X'
    @type  Function
    @author Rogério Duarte
    @since 27/06/2025
    @version 1.0
    @return Character, Retorna o próximo código sequencial
/*/
User Function FB101COM()

    // Local cRet       := M->A2_CGC
    Local cCodigo    := ""
    
    // Verifica se o tipo é 'X'
    If M->A2_TIPO == 'X'

        BEGINSQL ALIAS "SA2TMP"
            SELECT MAX(A2_COD) AS MAXCOD
            FROM %TABLE:SA2% SA2
            WHERE A2_FILIAL = %xfilial:SA2%
            AND A2_TIPO = 'X'
            AND SA2.%NOTDEL%
        ENDSQL
        
               
        If SA2TMP->(!EOF())
           cCodigo := soma1(SA2TMP->(MAXCOD))
        else
           cCodigo := "00000001" // Inicia com o primeiro código sequencial
        EndIf
        
        SA2TMP->(DbCloseArea())
        
    EndIf

Return cCodigo
