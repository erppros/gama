#INCLUDE "PROTHEUS.CH"

USER FUNCTION FB105FAT(nOpc)
	Local aArea:=GetArea()


	if nOpc == 1
		cTexto :=  "Cavidade em aço DIEVAR / DACMAGIC Temperadas com 44/46 HRC" +CRLF
		cTexto += "Buchas e colunas em aço 8620 Cementadas/Temperadas 54/56 HRC"+CRLF
		cTexto += "Porta Molde em aço 1045 TTO Superficial: NITRETAÇÃO"+CRLF
		cTexto += "Acabamento POLIDO"+CRLF
	elseif nOpc == 2

        cTexto := "Garantia: 100.000 tiros ou 2 anos."+CRLF
        ctexto += "Regiões do molde sem garantia:"+CRLF
        ctexto += "1) Região com raios pequenos menores que 1,0 mm;"+CRLF
        ctexto += "2) Região com pontos frágeis menores que 5,0 mm;"+CRLF
        ctexto += "3) Área frontal ao canal de injeção;"+CRLF
        ctexto += "4) Áreas com dificuldade de refrigeração;"+CRLF
        ctexto += "5) Áreas de vedação / assentamento sem usinagem;"+CRLF
        ctexto += "6) Regiões de dissipador / aletas."+CRLF
        ctexto += "Obs: trincas térmicas são inerentes ao processo de HPDC, por isso regiões que não possam ter"+CRLF
        ctexto += "trincas como, por exemplo, regiões aparentes ou de assentamento sem usinagem,"+CRLF
        ctexto += "devem ser mencionadas no orçamento para definição da garantia."+CRLF
        ctexto += "TRY OUT NÃO INCLUSO"+CRLF
        ctexto += "Molde será considerado pronto quando aprovado funcionalmente e as peças aprovadas dimensionalmente."+CRLF

	endif




	Restarea(aArea)
RETURN cTexto
