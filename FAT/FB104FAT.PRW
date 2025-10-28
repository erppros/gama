#INCLUDE "PROTHEUS.CH"

USER FUNCTION FB104FAT()
    
    Local aArea:=GetArea()
    lOCAL cCoduSer := RetCodUsr()
    local cRetorno := ""

    DBSelectArea("SU5")
    SU5->(DBOrderNickname("CODUSER"))

    IF SU5->(MSSEEK(FWXFILIAL("SU5")+cCoduSer))
        cRetorno := SU5->U5_CODCONT
        
    ENDIF

    Restarea(aArea)
return cRetorno

AC8->(MSSEEK(FWXFILIAL("AC8")+M->CJ_CLIENTE+M->CJ_LOJA+"SA1"))    
