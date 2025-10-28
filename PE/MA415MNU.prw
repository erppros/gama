User function MA415MNU()
	Local FndClass:= FindClass('BudgetReport')

	aadd(aRotina,{'Altera Versão Orçamento','U_FB001FAT()' , 0 , 3,0,NIL})
    
	if FndClass
		BudgetReport():New()
		aadd(aRotina,{'Imprimir Orçamento','BudgetReport():PrintReport()' , 0 , 3,0,NIL})

	endif
return
