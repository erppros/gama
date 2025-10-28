#INCLUDE "PROTHEUS.CH"

USER FUNCTION FB103FAT()
    Local aArea:=GetArea()

    local lRet:=.T.

    Local cArquivo  := ""    // Variável que armazenará o caminho do arquivo
    Local cMascara  := "Arquivo JPG | *.jpg"        // Máscara apenas para JPG/JPEG
    Local cTitulo   := "Selecione a Imagem JPG"     // Título da janela
    Local cDiret    := "C:\"                        // Diretório inicial
    Local nOpcoes   := GETF_LOCALHARD               // Opção para buscar apenas no disco local
    
    // Chama a função cGetFile
    cArquivo := cGetFile(cMascara, cTitulo, , cDiret, .T., nOpcoes)
    
    // Verifica se um arquivo foi selecionado
    If !Empty(cArquivo)
        TMP1->CK_ZIMPIMG := cArquivo
        lRet := .T.
    Else
        MsgAlert("Nenhum arquivo foi selecionado!", "Atenção")
    EndIf
    Restarea(aArea)

Return lRet
