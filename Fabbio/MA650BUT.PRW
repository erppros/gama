User Function MA650BUT()

     
    //Adicionando rotinas no ações relacionadas
    aAdd(aRotina, {'*Reprocessa Ordem','u_chamaexc', 0, 6 })
    AAdd( aRotina, { "Ajusta OPs e Empenhos", "U_FB100PCP()", 0, 4 } )
     
    
Return aRotina

User Function chamaexc()
    Local aArea := GetArea()
	Processa({||U_AltQuant(),"Lendo o arquivo"})
    RestArea(aArea)
Return()

User Function AltQuant()

Local _cnumop

Local _nquant
Local _item
Local _sequen
Local aSC2Y := {}
Local aSC2i := {}

Local aPegaop := {}
Local nx := 0
_cnumop := SC2->C2_NUM
_item   := SC2->C2_ITEM
_sequen := SC2->C2_SEQUEN
_nquant := SC2->C2_QUANT
_cproduto := SC2->C2_PRODUTO
_clocal   := SC2->C2_LOCAL
_cum      := SC2->C2_UM
_datapri := SC2->C2_DATPRI
_datarf := ddatabase
_demissao := SC2->C2_EMISSAO
_prior    := SC2->C2_PRIOR
_cseqpai  := SC2->C2_SEQPAI
_cexplode := "S"
_cGeraemp := "S"
_tpop     := SC2->C2_TPOP


MV_PAR02 := "2"
MV_PAR03 := " "
MV_PAR04 := "ZZ"



SC2->(DbSetOrder(1))
// Ssó deixo reprocessar se tiver no produto pai principal.
IF SC2->C2_SEQUEN <> "001"
    Msginfo("Para reprocessar a ordem de produção se faz necessario estar na ordem de produção do item pai, sequencia 001","Verifique a sequencia")
    Return(.t.)
Endif
// Gravo todas as ordens de produção daquela ordem de produção.
While !Eof() .and. SC2->C2_NUM + SC2->C2_ITEM == _cnumop+_item
     AADD(aPegaop,SC2->C2_NUM + SC2->C2_ITEM + SC2->C2_SEQUEN)
DbSkip()
Enddo

//Apago das ordens  se for a o.p do pai eu guardo em um array especifico pra depois eu incluir ela 
// de novo via msexecauto.
//Vale lembrar pro Fabbio do futuro se ele existir, que se tiver um PEDIDO DE COMPRA 
//para aquela ordem de produção eu nao consigo excluir e isso é padrão.
For nx := 1 to len(aPegaop)
IncProc("Reprocessando ordem de produção"+ cValToChar(nx) + " de " + cValToChar(Len(aPegaop)) + ", aguarde.")
    SC2->(DbSetOrder(1))
    SC2->(DbSeek(xFilial("SC2") +aPegaop[nx]))
    aSC2y := {}
    aSC2i := {}
    If Right(aPegaop[nx],3) == "001"
            aSC2i := {}
            Aadd(aSC2i ,{"C2_NUM" ,_cnumop ,NIL})
            Aadd(aSC2i ,{"C2_ITEM" ,_item ,NIL})
            Aadd(aSC2i ,{"C2_SEQUEN" ,_sequen ,NIL})
            Aadd(aSC2i ,{"C2_PRODUTO" ,_cproduto ,NIL})
            Aadd(aSC2i ,{"C2_LOCAL" ,_clocal ,NIL})
            Aadd(aSC2i ,{"C2_QUANT" ,_nquant ,NIL})
            Aadd(aSC2i ,{"C2_UM" ,_cum ,NIL})
            Aadd(aSC2i ,{"C2_DATPRI" ,_datapri ,NIL})
            Aadd(aSC2i ,{"C2_DATPRF" ,_datarf ,NIL})
            Aadd(aSC2i ,{"C2_EMISSAO" ,_demissao ,NIL})
            Aadd(aSC2i ,{"C2_PRIOR" ,_prior ,NIL})
            Aadd(aSC2i ,{"C2_SEQPAI" ,_cseqpai ,NIL})
            Aadd(aSC2i ,{"AUTEXPLODE" ,"S" ,NIL})
            Aadd(aSC2i ,{"GERAEMP" ,"S" ,NIL})
            Aadd(aSC2i ,{"C2_TPOP" ,_tpop ,NIL})
            Aadd(aSC2i ,{"C2_BATUSR " ,__cUserId  ,NIL})
    EndIF
    Aadd(aSC2y ,{"C2_NUM" ,SC2->C2_NUM ,NIL})
    Aadd(aSC2y ,{"C2_ITEM" ,SC2->C2_ITEM ,NIL})
    Aadd(aSC2y ,{"C2_SEQUEN" ,SC2->C2_SEQUEN ,NIL})
    Aadd(aSC2y ,{"C2_PRODUTO" ,SC2->C2_PRODUTO ,NIL})
    Aadd(aSC2y ,{"C2_LOCAL" ,SC2->C2_LOCAL ,NIL})
    Aadd(aSC2y ,{"C2_QUANT" ,_nquant ,NIL})
    Aadd(aSC2y ,{"C2_UM" ,SC2->C2_UM ,NIL})
    Aadd(aSC2y ,{"C2_DATPRI" ,SC2->C2_DATPRI ,NIL})
    Aadd(aSC2y ,{"C2_DATPRF" ,SC2->C2_DATPRF ,NIL})
    Aadd(aSC2y ,{"C2_EMISSAO" ,SC2->C2_EMISSAO ,NIL})
    Aadd(aSC2y ,{"C2_PRIOR" ,SC2->C2_PRIOR ,NIL})
    Aadd(aSC2y ,{"C2_SEQPAI" ,SC2->C2_SEQPAI ,NIL})
    Aadd(aSC2y ,{"AUTEXPLODE" ,"S" ,NIL})
    Aadd(aSC2y ,{"GERAEMP" ,"S" ,NIL})

    lMsErroAuto := .F.
    //Excluo as o.ps
    MSExecAuto({|x,y| Mata650(x,y)},aSC2y,5)
    If lMsErroAuto
        MostraErro()
        // parametro 10 indica se exclui também as o.ps filhas. 
        //Se ele tiver como 1 o proprio protheus já excluiu tudo.
    elseif MV_PAR10 == 1
        EXIT
    EndIf
Next
if len(aSC2i) > 0
    CriaSc7(aSC2i)
Endif

RETURN()

Static Function CriaSc7(aSC2i)
MV_PAR03 := SPACE(02)
MV_PAR04 := "ZZ"

lMsErroAuto := .F.
// Coloco de novo a SC2 com o mesmo numero reprocessando a o.p
    MSExecAuto({|x,y| Mata650(x,y)},aSC2i,3)
    If lMsErroAuto
        MostraErro()
    eNDIF

Return()
