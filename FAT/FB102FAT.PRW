#INCLUDE "PROTHEUS.CH"

User function FB102FAT()
    Local cRegTrib := "1"

    dbSelectArea("SA1")
    SA1->(DBSETORDER(1))

    IF SA1->(MSSEEK(FWXFILIAL("SA1")+M->CJ_CLIENTE+M->CJ_LOJA))

        IF SA1->A1_ZTXPIS == 0.65 .AND. SA1->A1_ZTXCOF == 3
            cRegTrib := "2"
        ELSE
            cRegTrib := "1"
        EndIf

    EndIf

Return cRegTrib
