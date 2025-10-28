#INCLUDE 'PROTHEUS.CH'


USER FUNCTION FB101VER(cOP,cCampoSC2,cCampoSG2,cCampoSB1)

	DEFAULT cOP       := ""
	DEFAULT cCampoSC2 := "C2_QUANT,C2_LOCAL"
	DEFAULT cCampoSG2 := "G2_CODIGO"
	DEFAULT cCampoSB1 := "B1_DESC,B1_UM"

	//Local aCampos := {}
	Local aCampoSB1 := {}
	Local aCampoSC2 := {}
	Local aCampoSG2 := {}
	Local cWhere    := ""
	Local cCamAuxC2 := "C2_NUM||C2_ITEM||C2_SEQUEN AS OP,"

	Local nX := 0

	Private oResponse := JsonObject():New()
	Private oJsonSG2  := JsonObject():New()
	Private oJsonSC2  := JsonObject():New()
    Private oMsgError := JsonObject():New()

    private oError      	:= NIl
	private bError      	:= {|e| oError := e, BREAK(e)}
	private bErrorBlock 	:= ErrorBlock( bError )


    BEGIN SEQUENCE

	IF !EMPTY(cCampoSC2)
        //Campos Obrigatórios para ligações com outras tabelas
		IF !"C2_PRODUTO" $ cCampoSC2
			cCampoSC2 += ",C2_PRODUTO"
		ENDIF

		if !"C2_ROTEIRO" $ cCampoSC2
			cCampoSC2 += ",C2_ROTEIRO"
		ENDIF
		aCampoSC2 := StrTokArr( "OP,"+cCampoSC2, ",|" )
	ENDIF

	IF !EMPTY(cCampoSB1)
		aCampoSB1 := StrTokArr( cCampoSB1, ",|" )
	ENDIF

	IF !EMPTY(cCampoSG2)
		aCampoSG2 := StrTokArr( cCampoSG2, ",|" )
	ENDIF

	RpcSetType(3)
	RpcSetEnv("01","0101",,,"FAT")

	//Se os campos desejados da SB1 não forem passados por parâmetro, retorno todos
	if empty(cCampoSB1)
		aCampoSB1 := FWSX3Util():GetAllFields( "SB1" , .F. )

		For nX := 1 to len(aCampoSB1)
			if nX == len(aCampoSB1)
				IF GETSX3CACHE(( aCampoSB1[nX]),"X3_TIPO") == "M"
					cCampoSB1 += "REPLACE(REPLACE(utl_raw.cast_to_varchar2(DBMS_LOB.SUBSTR("+aCampoSB1[nX]+" ,1024,1)),chr(13),''),chr(10),'') AS "+ aCampoSB1[nX]
				else
					cCampoSB1 += aCampoSB1[nX]
				ENDIF
			else
				IF GETSX3CACHE(( aCampoSB1[nX]),"X3_TIPO") == "M"
					cCampoSB1 += "REPLACE(REPLACE(utl_raw.cast_to_varchar2(DBMS_LOB.SUBSTR("+aCampoSB1[nX]+" ,1024,1)),chr(13),''),chr(10),'') AS "+ aCampoSB1[nX]+","
				else
					cCampoSB1 += aCampoSB1[nX]+","
				ENDIF
			endif

		Next nX

	ENDIF

	//Se os campos desejados da SC2 não forem passados por parâmetro, retorno todos
	if empty(cCampoSC2)
		aCampoSC2 := FWSX3Util():GetAllFields( "SC2" , .F. )
		cCampoSC2 := "%C2_NUM||C2_ITEM||C2_SEQUEN AS OP,"
		For nX := 1 to len(aCampoSC2)

			if nX == len(aCampoSC2)
				IF GETSX3CACHE(( aCampoSC2[nX]),"X3_TIPO") == "M"
					cCampoSC2 += "REPLACE(REPLACE(utl_raw.cast_to_varchar2(DBMS_LOB.SUBSTR("+aCampoSC2[nX]+" ,1024,1)),chr(13),''),chr(10),'') AS "+ aCampoSC2[nX]
				else
					cCampoSC2 += aCampoSC2[nX]
				ENDIF

			else
				IF GETSX3CACHE(( aCampoSC2[nX]),"X3_TIPO") == "M"
					cCampoSC2 += "REPLACE(REPLACE(utl_raw.cast_to_varchar2(DBMS_LOB.SUBSTR("+aCampoSC2[nX]+" ,1024,1)),chr(13),''),chr(10),'') AS "+ aCampoSC2[nX]+","
				else
					cCampoSC2 += aCampoSC2[nX]+","
				ENDIF
			endif

		Next nX
		IF !empty(cCampoSB1)
			cCampoSC2 += ","+cCampoSB1+"%"
		else
			cCampoSC2 += "%"
		endif
	else
		IF !empty(cCampoSB1)
			cCampoSC2 := "%"+cCamAuxC2+cCampoSC2+","+cCampoSB1+"%"
		else
			cCampoSC2 := "%"+cCamAuxC2+cCampoSC2+"%"
		endif
	ENDIF

	//Se os campos desejados da SG2 não forem passados por parâmetro, retorno todos
	if empty(cCampoSG2)
		aCampoSG2 := FWSX3Util():GetAllFields( "SG2" , .F. )
		cCampoSG2 := "%"
		For nX := 1 to len(aCampoSG2)
			if nX == len(aCampoSG2)
				IF GETSX3CACHE(( aCampoSG2[nX]),"X3_TIPO") == "M"
					cCampoSG2 += "REPLACE(REPLACE(utl_raw.cast_to_varchar2(DBMS_LOB.SUBSTR("+aCampoSG2[nX]+" ,1024,1)),chr(13),''),chr(10),'') AS "+ aCampoSG2[nX]
				else
					cCampoSG2 += aCampoSG2[nX]
				ENDIF
			else
				IF GETSX3CACHE(( aCampoSG2[nX]),"X3_TIPO") == "M"
					cCampoSG2 += "REPLACE(REPLACE(utl_raw.cast_to_varchar2(DBMS_LOB.SUBSTR("+aCampoSG2[nX]+" ,1024,1)),chr(13),''),chr(10),'') AS "+ aCampoSG2[nX]+","
				else
					cCampoSG2 += aCampoSG2[nX]+","
				ENDIF
			endif

		Next nX
		cCampoSG2 += "%"
	else
		cCampoSG2 := "%"+cCampoSG2+"%"
	ENDIF

	if !empty(cOP)
		cWhere += "%AND C2_NUM||C2_ITEM||C2_SEQUEN = '"+ALLTRIM(cOP)+"' "
	else
		cWhere += "%%"
	endif

	//Query
	BeginSql Alias "SC2TMP"
    
        SELECT  %EXP:cCampoSC2%
        FROM    %TABLE:SC2% SC2
        INNER JOIN %TABLE:SB1% SB1 ON B1_COD = C2_PRODUTO AND SB1.%NOTDEL%

        WHERE   SC2.%NOTDEL%
            AND C2_DATRF = '' 
            AND C2_FILIAL = %EXP:FWXFILIAL("SC2")%
            AND C2_TPOP = 'F'
            %EXP:cWhere%
            AND EXISTS ( 
                        SELECT %EXP:cCampoSG2%
                        FROM   %TABLE:SG2% SG2
                        WHERE SG2.%NOTDEL%
                            AND G2_FILIAL   = %EXP:XFILIAL("SG2")%
                            AND G2_PRODUTO  = C2_PRODUTO
                            AND G2_CODIGO   = C2_ROTEIRO
                        )
	endSQL

    oResponse['ordensProducao'] := {}

	iF SC2TMP->(EOF())
        oMsgError['FB101VER'] := "A pesquisa não retornou dados, verifique os parâmetros" 
        AADD(oResponse['ordensProducao'],oMsgError)
        lSuccess := .F.
        return oResponse
    ENDIF
	

	while !SC2TMP->(EOF())
		oJsonSC2['OP']:= SC2TMP->(OP)
		For nX:=1 to len(aCampoSC2)
			IF VALTYPE(SC2TMP->(&(aCampoSC2[nX]))) == "C"
				oJsonSC2[ aCampoSC2[nX] ]  := ALLTRIM(SC2TMP->(&(aCampoSC2[nX])))
			ELSE
				oJsonSC2[ aCampoSC2[nX] ]  := SC2TMP->(&(aCampoSC2[nX]))
			ENDIF

		Next nX
		For nX:=1 to len(aCampoSB1)
			IF VALTYPE(SC2TMP->(&(aCampoSB1[nX]))) == "C"
				oJsonSC2[ aCampoSB1[nX] ]  := ALLTRIM(SC2TMP->(&(aCampoSB1[nX])))
			ELSE
				oJsonSC2[ aCampoSB1[nX] ]  := SC2TMP->(&(aCampoSB1[nX]))
			ENDIF
		Next nX
		oJsonSC2['operacoes']:= {}

		BeginSql Alias "SG2TMP"
            SELECT %EXP:cCampoSG2%
            FROM   %TABLE:SG2% SG2
            WHERE SG2.%NOTDEL%
                  AND G2_FILIAL   = %EXP:XFILIAL("SG2")%
                  AND G2_PRODUTO  = %EXP:SC2TMP->(C2_PRODUTO)%
                
		endSQL

		IF !SG2TMP->(EOF())
			while !SG2TMP->(EoF())
				For nX:=1 to len(aCampoSG2)
					IF VALTYPE(SG2TMP->(&(aCampoSG2[nX]))) == "C"
						oJsonSG2[ aCampoSG2[nX] ]  := ALLTRIM(SG2TMP->(&(aCampoSG2[nX])))
					ELSE
						oJsonSG2[ aCampoSG2[nX] ]  := SG2TMP->(&(aCampoSG2[nX]))
					ENDIF
				Next nX
				AADD(oJsonSC2['operacoes'],oJsonSG2)
				oJsonSG2  := JsonObject():New()
				SG2TMP->(DBSKIP())
			end

		ENDIF
		SG2TMP->(DBCloseArea())

		AADD(oResponse['ordensProducao'],oJsonSC2)
		oJsonSC2  := JsonObject():New()
		SC2TMP->(DBSKIP())
	END

	SC2TMP->(DBCloseArea())

    RECOVER

    If ( Type("oError") =='O' )
        oResponse['ordensProducao'] := {}
        
        oMsgError['FB101VER'] := "Erro na aplicação, verifique o formato dos dados enviados" 
        oMsgError['Error'] := oError:Description
        
        AADD(oResponse['ordensProducao'],oMsgError)
        
        lSuccess := .F.
        return oResponse

    ENDIF

    END SEQUENCE


Return oResponse
