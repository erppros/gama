User function MA415MNU()
	Local FndClass:= FindClass('BudgetReport')

	aadd(aRotina,{'Altera Vers�o Or�amento','U_FB001FAT()' , 0 , 3,0,NIL})
    
	if FndClass
		BudgetReport():New()
		aadd(aRotina,{'Imprimir Or�amento','BudgetReport():PrintReport()' , 0 , 3,0,NIL})

	endif
return
