#include 'Protheus.ch'

/*/
//adicionada variável 
/*/
#include 'protheus.ch'

User Function F240FIL()

	Local cRet := ""

	Do Case
	Case cmodpgto == '01' .OR. cmodpgto == '05'
		cRet+= " Empty(E2_CODBAR) .AND. fBuscaCpo('SA2', 1, xFilial('SA2')+E2_FORNECE+E2_LOJA, 'A2_BANCO') == cport240 "
	Case cmodpgto == '03'
		cRet+= " Empty(E2_CODBAR) .AND. E2_SALDO <= 2999.99 "
		cRet+= " .AND. (!Empty(fBuscaCpo('SA2',1, xFilial('SA2')+E2_FORNECE+E2_LOJA, 'A2_BANCO')) .and. fBuscaCpo('SA2',1, xFilial('SA2')+E2_FORNECE+E2_LOJA, 'A2_BANCO') != cport240) "
	Case cmodpgto == '11'
		cRet+= " !Empty(E2_CODBAR) .AND. Left(E2_CODBAR, 3) != '341' .AND. Len(Alltrim(E2_CODBAR)) >= 48 "
	Case cmodpgto == '13'
		cRet+= " !Empty(E2_CODBAR) .AND. Left(E2_CODBAR, 3) == '341' .AND. Len(Alltrim(E2_CODBAR)) >= 48 "
	Case cmodpgto == '30'
		cRet+= " !Empty(E2_CODBAR) .AND. Left(E2_CODBAR, 3) == cport240 .AND. Len(Alltrim(E2_CODBAR)) <= 47 "
	Case cmodpgto == '31'
		cRet+= " !Empty(E2_CODBAR) .AND. Left(E2_CODBAR, 3) != cport240 .AND. Len(Alltrim(E2_CODBAR)) <= 47 "
	Case cmodpgto == '41'
		cRet+= " Empty(E2_CODBAR) .AND. E2_SALDO >= 0 "
		cRet+= " .AND. (!Empty(fBuscaCpo('SA2',1, xFilial('SA2')+E2_FORNECE+E2_LOJA, 'A2_BANCO')) .and. fBuscaCpo('SA2',1, xFilial('SA2')+E2_FORNECE+E2_LOJA, 'A2_BANCO') != cport240 ) "
	Case cmodpgto == '43'
		cRet+= " Empty(E2_CODBAR) .AND. E2_SALDO >= 0 "
		cRet+= " .AND. (!Empty(fBuscaCpo('SA2',1, xFilial('SA2')+E2_FORNECE+E2_LOJA, 'A2_BANCO')) .and. fBuscaCpo('SA2',1, xFilial('SA2')+E2_FORNECE+E2_LOJA, 'A2_BANCO') != cport240 ) "
		cRet+= " .AND. fBuscaCpo('SA2',1, xFilial('SA2')+E2_FORNECE+E2_LOJA, 'A2_CGC') == SM0->M0_CGC "
	Case cmodpgto == '45'
		cRet+= " Empty(E2_CODBAR) .AND. E2_SALDO > 0 .AND. FBUSCACPO('F72',1,XFILIAL('F72')+E2_FORNECE+E2_LOJA,'F72_ACTIVE') == '1'.AND. FBUSCACPO('F72',1,XFILIAL('F72')+E2_FORNECE+E2_LOJA,'F72_CHVPIX') <> '' "
	Case cmodpgto == '91'
		cRet+= " !Empty(E2_ZCDDARF) .AND. !Empty(E2_CODBAR) "
	EndCase
/*
   Case cmodpgto == '47'
            cRet+= " !Empty(SE2->E2_ZPAGPIX) "
            //comentado em 05/08/2024 - Luciana
*/
	/*If __lFiltro
		cRet+= " .AND. (fBuscaCpo('SA2',1, xFilial('SA2')+E2_FORNECE+E2_LOJA, 'A2_ZTIPOFO') == '1' ) "
	ELse
		cRet+= " .AND. (fBuscaCpo('SA2',1, xFilial('SA2')+E2_FORNECE+E2_LOJA, 'A2_ZTIPOFO') <> '1' ) "	
	EndIf*/

Return cRet
