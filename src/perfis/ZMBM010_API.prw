#include "protheus.ch"
#include "restful.ch"
#include "fwmvcdef.ch"

#define QRY_PARAM_KEY 1
#define QRY_PARAM_VALUE 2

#define MAP_PROP 1
#define MAP_FIELD 2
#define MAP_TYPE 3

#define QRY_VAL_TYPE 1
#define QRY_VAL_VALUE 2

//-------------------------------------------------------------------
/*/{Protheus.doc} perfis
    Classe para aplicar a atualiza��o dos perfis das pessoas no microblog
@type   class

@author  josimar.assuncao
@since   22.11.2020
/*/
//-------------------------------------------------------------------
wsrestful Perfis description "Trata a atualiza��o dos perfis que usam o microblog"
    wsdata pageSize         as integer optional
    wsdata page             as integer optional
    wsdata perfilId         as character optional
    wsdata order            as character optional
    wsdata fields           as character optional

    // vers�es 1 - utilizam Seek e Reclock nos processos de grava��o
    wsmethod GET V1ALL description "Recupera todos os perfis" wssyntax "/microblog/v1/perfis" path "/microblog/v1/perfis"
    wsmethod POST V1ROOT description "Cria um perfil para o microblog" wssyntax "/microblog/v1/perfis" path "/microblog/v1/perfis"

    wsmethod GET V1ID description "Recupera um perfil pelo id" wssyntax "/microblog/v1/perfis/{perfilId}" path "/microblog/v1/perfis/{perfilId}"
    wsmethod PUT V1ID description "Faz a atualiza��o de um perfil" wssyntax "/microblog/v1/perfis/{perfilId}" path "/microblog/v1/perfis/{perfilId}"
    wsmethod DELETE V1 description "Faz a exclus�o de um perfil" wssyntax "/microblog/v1/perfis/{perfilId}" path "/microblog/v1/perfis/{perfilId}"

    // vers�es 2 - utilizam modelo nos processos de grava��o
    wsmethod POST V2ROOT description "Cria um perfil para o microblog usando modelo MVC" wssyntax "/microblog/v2/perfis" path "/microblog/v2/perfis"

    wsmethod GET V2ID description "Recupera um perfil pelo id usando modelo MVC" wssyntax "/microblog/v2/perfis/{perfilId}" path "/microblog/v2/perfis/{perfilId}"
    wsmethod PUT V2ID description "Faz a atualiza��o de um perfil usando modelo MVC" wssyntax "/microblog/v2/perfis/{perfilId}" path "/microblog/v2/perfis/{perfilId}"
    wsmethod DELETE V2 description "Faz a exclus�o de um perfil usando modelo MVC" wssyntax "/microblog/v2/perfis/{perfilId}" path "/microblog/v2/perfis/{perfilId}"

    // vers�o 2 - recupera lista com propriedade para filtros e pagina��o
    wsmethod GET V2ALL description "Recupera todos os perfis" wssyntax "/microblog/v2/perfis" path "/microblog/v2/perfis"

end wsrestful

//-------------------------------------------------------------------
/*/{Protheus.doc} GET V1ALL
    Recupera todos os perfis
@type    method

@author  josimar.assuncao
@since   22.11.2020
/*/
//-------------------------------------------------------------------
wsmethod GET V1ALL wsreceive page, pageSize wsservice Perfis
    local lProcessed as logical
    local jResponse  as object
    local jTempItem  as object
    lProcessed := .T.

    // Define o tipo de retorno do m�todo
    self:SetContentType("application/json")

    // As propriedades da classe receber�o os valores enviados por querystring
    // exemplo: http://localhost:18085/rest/microblog/v1/perfis?page=1&pageSize=5
    default self:page := 1
    default self:pageSize := 5

    DbSelectArea("ZT0")
    DbSetOrder(3) // ZT0_FILIAL+ZT0_NOME
    DbSeek(xFilial("ZT0"))

    // exemplo de retorno de uma lista de objetos JSON
    jResponse := JsonObject():New()
    jResponse['items'] := {}
    while ZT0->(!EOF())
        aAdd(jResponse['items'], JsonObject():New())
        jTempItem := aTail(jResponse['items'])

        jTempItem["email"]   := ZT0->ZT0_EMAIL
        jTempItem["user_id"] := ZT0->ZT0_USRID
        jTempItem["name"]    := ZT0->ZT0_NOME
        // jTempItem["inserted_at"] := ZT0->S_T_A_M_P_
        // jTempItem["updated_at"] := ZT0->I_N_S_D_T_
        ZT0->(DbSkip())
    enddo

    self:SetResponse(jResponse:ToJson())
return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} GET V1ID
    Recupera um perfil pelo id
@type    method

@author  josimar.assuncao
@since   22.11.2020
/*/
//-------------------------------------------------------------------
wsmethod GET V1ID pathparam perfilId wsservice Perfis
    local lProcessed as logical
    local jResponse  as object

    lProcessed := .T.
    self:SetContentType("application/json")

    DbSelectArea("ZT0")
    DbSetOrder(2) // ZT0_FILIAL+ZT0_USRID

    jResponse := JsonObject():New()

    // Id n�o ser vazio e existir como item na tabela
    lProcessed := (!(Alltrim(self:perfilId) == "") .And. ZT0->(DbSeek(xFilial("ZT0")+self:perfilId)))
    if lProcessed

        jResponse["email"]   := ZT0->ZT0_EMAIL
        jResponse["user_id"] := ZT0->ZT0_USRID
        jResponse["name"]    := ZT0->ZT0_NOME
        // jResponse["inserted_at"] := ZT0->S_T_A_M_P_
        // jResponse["updated_at"] := ZT0->I_N_S_D_T_

        self:SetResponse(jResponse:ToJson())
    else
        jResponse["error"] := "id_invalido"
        jResponse["description"] := i18n("Perfil n�o encontrado utilizando o #[id] informado", {self:perfilId})

        self:SetResponse(jResponse:ToJson())
        SetRestFault(404, jResponse:ToJson(), , 404)
        lProcessed := .F.
    endif

return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} POST V1ROOT
    Cria um perfil para o microblog
@type   method

@author josimar.assuncao
@since  22.11.2020
/*/
//-------------------------------------------------------------------
wsmethod POST V1ROOT wsservice Perfis
    local lProcessed as logical
    local jBody      as object
    local jResponse  as object

    lProcessed := .T.
    self:SetContentType("application/json")

    jBody := JsonObject():New()
    jBody:FromJson(self:GetContent())

    jResponse := JsonObject():New()

    if (jBody["email"] == Nil .Or. jBody["user_id"] == Nil .Or. jBody["name"] == Nil)
        jResponse["error"] := "body_invalido"
        jResponse["description"] := "Forne�a as propriedades 'email', 'user_id' e 'name' no body"

        self:SetResponse(jResponse:ToJson())
        SetRestFault(400, jResponse:ToJson(), , 400)
        lProcessed := .F.
    else
        DBSelectArea("ZT0")
        Reclock("ZT0", .T.)
            ZT0->ZT0_FILIAL := xFilial("ZT0")
            ZT0->ZT0_EMAIL  := jBody["email"]
            ZT0->ZT0_USRID  := jBody["user_id"]
            ZT0->ZT0_NOME   := jBody["name"]
        ZT0->(MsUnlock())

        jResponse["email"]   := ZT0->ZT0_EMAIL
        jResponse["user_id"] := ZT0->ZT0_USRID
        jResponse["name"]    := ZT0->ZT0_NOME
        // jResponse["inserted_at"] := ZT0->S_T_A_M_P_
        // jResponse["updated_at"] := ZT0->I_N_S_D_T_

        self:SetResponse(jResponse:ToJson())
    endif

return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} PUT V1ID
    Faz a atualiza��o de um perfil
@type    method

@author  josimar.assuncao
@since   22.11.2020
/*/
//-------------------------------------------------------------------
wsmethod PUT V1ID pathparam perfilId wsservice Perfis
    local lProcessed as logical
    local jResponse  as object

    lProcessed := .T.
    self:SetContentType("application/json")

    DbSelectArea("ZT0")
    DbSetOrder(2) // ZT0_FILIAL+ZT0_USRID

    jResponse := JsonObject():New()

    // Id n�o ser vazio e existir como item na tabela
    lProcessed := (!(Alltrim(self:perfilId) == "") .And. ZT0->(DbSeek(xFilial("ZT0")+self:perfilId)))
    if lProcessed

        jBody := JsonObject():New()
        jBody:FromJson(self:GetContent())

        if (jBody["name"] == Nil)
            jResponse["error"] := "body_invalido"
            jResponse["description"] := "Forne�a a propriedade 'name' no body"

            self:SetResponse(jResponse:ToJson())
            SetRestFault(400, jResponse:ToJson(), , 400)
            lProcessed := .F.
        else

            Reclock("ZT0", .F.)
                ZT0->ZT0_NOME   := jBody["name"]
            ZT0->(MsUnlock())

            jResponse["email"]   := ZT0->ZT0_EMAIL
            jResponse["user_id"] := ZT0->ZT0_USRID
            jResponse["name"]    := ZT0->ZT0_NOME
            // jResponse["inserted_at"] := ZT0->S_T_A_M_P_
            // jResponse["updated_at"] := ZT0->I_N_S_D_T_

            self:SetResponse(jResponse:ToJson())
        endif
    else
        jResponse["error"] := "id_invalido"
        jResponse["description"] := i18n("Perfil n�o encontrado utilizando o #[id] informado", {self:perfilId})

        self:SetResponse(jResponse:ToJson())
        SetRestFault(404, jResponse:ToJson(), , 404)
        lProcessed := .F.
    endif

return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} DELETE V1
    Faz a exclus�o de um perfil
@type    method

@author  josimar.assuncao
@since   22.11.2020
/*/
//-------------------------------------------------------------------
wsmethod DELETE V1 pathparam perfilId wsservice Perfis
    local lProcessed as logical
    local lDelete    as logical
    local jResponse  as object

    lProcessed := .T.
    self:SetContentType("application/json")

    DbSelectArea("ZT0")
    DbSetOrder(2) // ZT0_FILIAL+ZT0_USRID

    jResponse := JsonObject():New()

    // Id n�o ser vazio e existir como item na tabela
    varinfo("id", self:perfilId)
    lProcessed := !(Alltrim(self:perfilId) == "")
    if lProcessed

        // Se n�o encontrar o registro, n�o faz nada e retorna verdadeiro
        lDelete := ZT0->(DbSeek(xFilial("ZT0")+self:perfilId))
        if lDelete
            Reclock("ZT0", .F.)
                DbDelete()
            ZT0->(MsUnlock())
        endif

        self:SetResponse("{}")
    else
        jResponse["error"] := "id_invalido"
        jResponse["description"] := i18n("Perfil n�o encontrado utilizando o #[id] informado", {self:perfilId})

        self:SetResponse(jResponse:ToJson())
        SetRestFault(404, jResponse:ToJson(), , 404)
        lProcessed := .F.
    endif

return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} GET V2ID
    Recupera um perfil pelo id usando modelo MVC
@type    method

@author  josimar.assuncao
@since   04.12.2020
/*/
//-------------------------------------------------------------------
wsmethod GET V2ID pathparam perfilId wsservice Perfis
    local lProcessed as logical
    local jResponse  as object
    local oModel     as object
    local oZT0Header as object

    lProcessed := .T.
    self:SetContentType("application/json")

    DbSelectArea("ZT0")
    DbSetOrder(2) // ZT0_FILIAL+ZT0_USRID

    jResponse := JsonObject():New()

    // Id n�o ser vazio e existir como item na tabela
    lProcessed := (!(Alltrim(self:perfilId) == "") .And. ZT0->(DbSeek(xFilial("ZT0")+self:perfilId)))

    oModel := FwLoadModel("ZMBA010")
    oModel:SetOperation(MODEL_OPERATION_VIEW)

    lProcessed := oModel:Activate()

    if lProcessed
        oZT0Header := oModel:GetModel("ZT0_FIELDS")

        jResponse["email"]   := oZT0Header:GetValue("ZT0_EMAIL")
        jResponse["user_id"] := oZT0Header:GetValue("ZT0_USRID")
        jResponse["name"]    := oZT0Header:GetValue("ZT0_NOME")
        // jResponse["inserted_at"] := ZT0->S_T_A_M_P_
        // jResponse["updated_at"] := ZT0->I_N_S_D_T_

        self:SetResponse(jResponse:ToJson())
    else
        jResponse["error"] := "id_invalido"
        jResponse["description"] := i18n("Perfil n�o encontrado utilizando o #[id] informado", {self:perfilId})

        self:SetResponse(jResponse:ToJson())
        SetRestFault(404, jResponse:ToJson(), , 404)
        lProcessed := .F.
    endif

    oModel:DeActivate()

return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} POST V2ROOT
    Cria um perfil para o microblog usando MVC
@type   method

@author josimar.assuncao
@since  04.12.2020
/*/
//-------------------------------------------------------------------
wsmethod POST V2ROOT wsservice Perfis
    local lProcessed as logical
    local jBody      as object
    local jResponse  as object
    local oModel     as object
    Local oZT0Header as object
    local aError     as array

    lProcessed := .T.
    self:SetContentType("application/json")

    jBody := JsonObject():New()
    jBody:FromJson(self:GetContent())

    jResponse := JsonObject():New()

    if (jBody["email"] == Nil .Or. jBody["user_id"] == Nil .Or. jBody["name"] == Nil)
        jResponse["error"] := "body_invalido"
        jResponse["description"] := "Forne�a as propriedades 'email', 'user_id' e 'name' no body"

        self:SetResponse(jResponse:ToJson())
        SetRestFault(400, jResponse:ToJson(), , 400)
        lProcessed := .F.
    else
        oModel := FwLoadModel("ZMBA010")

        oModel:SetOperation(MODEL_OPERATION_INSERT)

        lProcessed := oModel:Activate()
        oZT0Header := oModel:GetModel("ZT0_FIELDS")

        lProcessed := lProcessed .And. oZT0Header:SetValue("ZT0_EMAIL" , jBody["email"])
        lProcessed := lProcessed .And. oZT0Header:SetValue("ZT0_USRID" , jBody["user_id"])
        lProcessed := lProcessed .And. oZT0Header:SetValue("ZT0_NOME"  , jBody["name"])

        lProcessed := lProcessed .And. oModel:VldData() .And. oModel:CommitData()

        if lProcessed
            jResponse["email"]   := oZT0Header:GetValue("ZT0_EMAIL")
            jResponse["user_id"] := oZT0Header:GetValue("ZT0_USRID")
            jResponse["name"]    := oZT0Header:GetValue("ZT0_NOME")
            // jResponse["inserted_at"] := ZT0->S_T_A_M_P_
            // jResponse["updated_at"] := ZT0->I_N_S_D_T_

            self:SetResponse(jResponse:ToJson())
        else
            aError := oModel:GetErrorMessage()
            jResponse["error"] := "creation_failed"
            jResponse["description"] := aError[MODEL_MSGERR_MESSAGE]
            self:SetResponse(jResponse:ToJson())
            SetRestFault(400, jResponse:ToJson(), , 400)
        endif

        oModel:DeActivate()
    endif

return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} PUT V2ID
    Faz a atualiza��o de um perfil usando MVC
@type    method

@author  josimar.assuncao
@since   04.12.2020
/*/
//-------------------------------------------------------------------
wsmethod PUT V2ID pathparam perfilId wsservice Perfis
    local lProcessed as logical
    local jResponse  as object
    local oModel     as object
    local oZT0Header as object
    local aError     as array

    lProcessed := .T.
    self:SetContentType("application/json")

    DbSelectArea("ZT0")
    DbSetOrder(2) // ZT0_FILIAL+ZT0_USRID

    jResponse := JsonObject():New()

    // Id n�o ser vazio e existir como item na tabela
    lProcessed := (!(Alltrim(self:perfilId) == "") .And. ZT0->(DbSeek(xFilial("ZT0")+self:perfilId)))
    if lProcessed

        jBody := JsonObject():New()
        jBody:FromJson(self:GetContent())

        if (jBody["name"] == Nil)
            jResponse["error"] := "body_invalido"
            jResponse["description"] := "Forne�a a propriedade 'name' no body"

            self:SetResponse(jResponse:ToJson())
            SetRestFault(400, jResponse:ToJson(), , 400)
            lProcessed := .F.
        else
            oModel := FwLoadModel("ZMBA010")

            oModel:SetOperation(MODEL_OPERATION_UPDATE)

            lProcessed := oModel:Activate()
            oZT0Header := oModel:GetModel("ZT0_FIELDS")

            // Somente atualiza o campo ZT0_NOME
            lProcessed := lProcessed .And. oZT0Header:SetValue("ZT0_NOME"  , jBody["name"])

            lProcessed := lProcessed .And. oModel:VldData() .And. oModel:CommitData()
            if lProcessed

                jResponse["email"]   := oZT0Header:GetValue("ZT0_EMAIL")
                jResponse["user_id"] := oZT0Header:GetValue("ZT0_USRID")
                jResponse["name"]    := oZT0Header:GetValue("ZT0_NOME")
                // jResponse["inserted_at"] := ZT0->S_T_A_M_P_
                // jResponse["updated_at"] := ZT0->I_N_S_D_T_

                self:SetResponse(jResponse:ToJson())
            else
                aError := oModel:GetErrorMessage()
                jResponse["error"] := "creation_failed"
                jResponse["description"] := aError[MODEL_MSGERR_MESSAGE]
                self:SetResponse(jResponse:ToJson())
                SetRestFault(400, jResponse:ToJson(), , 400)
            endif

            oModel:DeActivate()
        endif
    else
        jResponse["error"] := "id_invalido"
        jResponse["description"] := i18n("Perfil n�o encontrado utilizando o #[id] informado", {self:perfilId})

        self:SetResponse(jResponse:ToJson())
        SetRestFault(404, jResponse:ToJson(), , 404)
        lProcessed := .F.
    endif

return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} DELETE V2
    Faz a exclus�o de um perfil usando MVC
@type    method

@author  josimar.assuncao
@since   04.12.2020
/*/
//-------------------------------------------------------------------
wsmethod DELETE V2 pathparam perfilId wsservice Perfis
    local lProcessed as logical
    local lDelete    as logical
    local jResponse  as object
    local oModel     as object
    local aError     as array

    lProcessed := .T.
    self:SetContentType("application/json")

    DbSelectArea("ZT0")
    DbSetOrder(2) // ZT0_FILIAL+ZT0_USRID

    jResponse := JsonObject():New()

    // Id n�o ser vazio e existir como item na tabela
    lProcessed := !(Alltrim(self:perfilId) == "")
    if lProcessed

        lDelete := ZT0->(DbSeek(xFilial("ZT0")+self:perfilId))
        if lDelete
            oModel := FwLoadModel("ZMBA010")

            oModel:SetOperation(MODEL_OPERATION_DELETE)
            lProcessed := oModel:Activate()

            // Se n�o encontrar o registro, n�o faz nada e retorna verdadeiro
            lProcessed := lProcessed .And. oModel:VldData() .And. oModel:CommitData()

            oModel:DeActivate()
        endif

        if lProcessed
            self:SetResponse("{}")
        else
            aError := oModel:GetErrorMessage()
            jResponse["error"] := "deletion_failed"
            jResponse["description"] := aError[MODEL_MSGERR_MESSAGE]
            self:SetResponse(jResponse:ToJson())
            SetRestFault(400, jResponse:ToJson(), , 400)
        endif
    else
        jResponse["error"] := "id_invalido"
        jResponse["description"] := i18n("Perfil n�o encontrado utilizando o #[id] informado", {self:perfilId})

        self:SetResponse(jResponse:ToJson())
        SetRestFault(404, jResponse:ToJson(), , 404)
        lProcessed := .F.
    endif

return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} GET V2ALL
    Recupera todos os perfis permite pagina��o, ordena��o e filtro
constru�dos exclusivamente para este m�todo
@type    method

@author  josimar.assuncao
@since   22.11.2020
/*/
//-------------------------------------------------------------------
wsmethod GET V2ALL wsreceive page, pageSize, order, fields wsservice Perfis
    local lProcessed    as logical
    local jResponse     as object
    local jTempItem     as object
    local cTempAlias    as character
    local cQuery        as character
    local aFieldsMap    as object
    local nItemFrom     as numeric
    local nItemTo       as numeric
    local cOrderBy      as character
    local cOrdDirection as character
    local lDesc         as logical
    local aTemp         as array
    local cTempField    as character
    local nTemp         as numeric
    local nI            as numeric
    local nMax          as numeric
    local cCondition    as character
    local aQryValues    as array
    local oPrepStat     as object
    lProcessed := .T.

    // Define o tipo de retorno do m�todo
    self:SetContentType("application/json")

    // As propriedades da classe receber�o os valores enviados por querystring
    // exemplo: /rest/microblog/v1/perfis?page=1&pageSize=5&order=-name&fields=name,email
    default self:page := 1
    default self:pageSize := 10
    default self:order := ""
    default self:fields := ""
    // Mapeia os campos da query com as propriedades
    aFieldsMap := {;
        {"email", "ZT0_EMAIL", "C"},;
        {"user_id", "ZT0_USRID", "C"},;
        {"name", "ZT0_NOME", "C"},;
        {"admin", "ZT0_ADMIN", "L"},;
        {"inserted_at", "ZT0_INS_AT", "C"},;
        {"updated_at", "ZT0_UPD_AT", "C"} ;
    }
    // montagem da pagina��o
    nItemFrom := (self:page - 1) * self:pageSize + 1
    nItemTo := (self:page) * self:pageSize

    // montagem da ordem
    if Empty(Alltrim(self:order))
        cOrderBy := "ZT0_NOME asc"
    else
        aTemp := StrTokArr(self:order, ",")
        nMax := Len(aTemp)

        cOrderBy := ""
        for nI := 1 to nMax

            lDesc := (SubStr(aTemp[nI], 1, 1) == "-")
            if lDesc
                cTempField := SubStr(aTemp[nI], 2)
                cOrdDirection := " desc"
            else
                cTempField := aTemp[nI]
                cOrdDirection := " asc"
            endif

            nTemp := aScan(aFieldsMap, {|x| x[MAP_PROP] == cTempField})
            if nTemp > 0
                cOrderBy += aFieldsMap[nTemp, MAP_FIELD] + cOrdDirection + ","
            endif
        next nI
        // Remove a �ltima ,
        cOrderBy := SubStr(cOrderBy, 1, Len(cOrderBy)-1)
    endif

    // monta a condi��o para a query
    //  suporta filtros simples com operador LIKE -> campo like %valor%
    cCondition := "ZT0.D_E_L_E_T_ = ' ' "
    aQryValues := {}
    for nI := 1 To Len(self:aQueryString)
        cTempField := Lower(self:aQueryString[nI, QRY_PARAM_KEY])
        nTemp := aScan(aFieldsMap, {|x| x[MAP_PROP] == cTempField})
        // quando encontra cria a express�o e guarda o valor para atribuir
        if nTemp > 0
            if aFieldsMap[nTemp, MAP_TYPE] == "C"
                cCondition += "and ZT0." + aFieldsMap[nTemp, MAP_FIELD] + " like ? "
            else
                cCondition += "and ZT0." + aFieldsMap[nTemp, MAP_FIELD] + " = ? "
            endif
            // mantem par com tipo [QRY_VAL_TYPE] e valor [QRY_VAL_VALUE]
            aAdd(aQryValues, {aFieldsMap[nTemp, MAP_TYPE], self:aQueryString[nI, QRY_PARAM_VALUE]} )
        endif
    next nI

    cQuery := "select * "
    cQuery += "from ("
    cQuery +=       " select ZT0_EMAIL, ZT0_USRID, ZT0_NOME, ZT0_ADMIN,"
    cQuery +=           "convert(varchar(23), I_N_S_D_T_, 21) ZT0_INS_AT,"
    cQuery +=           "convert(varchar(23), S_T_A_M_P_, 21) ZT0_UPD_AT,"
    cQuery +=           "ROW_NUMBER() OVER (order by "+ cOrderBy +") SEQITEM "
    cQuery +=       "from " + RetSqlName("ZT0") + " ZT0 "
    cQuery +=       "where " + cCondition
    cQuery +=    ") QUERYDATA "
    cQuery += "where SEQITEM >= "+ cValToChar(nItemFrom) +" and SEQITEM <= "+ cValToChar(nItemTo) +" "
    cQuery += "order by " + cOrderBy

    oPrepStat := FwPreparedStatement():New(cQuery)
    for nI := 1 to Len(aQryValues)
        // atribui os valores de string com operador like
        if aQryValues[nI, QRY_VAL_TYPE] == "C"
            oPrepStat:SetLike(nI, aQryValues[nI, QRY_VAL_VALUE])

        // propriedade admin est� com tipo l�gico ent�o faz igualdade 1=sim;2=n�o
        elseif aQryValues[nI, QRY_VAL_TYPE] == "L"
            if (Alltrim(aQryValues[nI, QRY_VAL_VALUE]) == "1" .Or. Alltrim(aQryValues[nI, QRY_VAL_VALUE]) == "true")
                cTemp := "1"
            else
                cTemp := "2"
            endif
            oPrepStat:SetString(nI, cTemp)
        endif
    next nI

    cQuery := oPrepStat:getFixQuery()

    cTempAlias := GetNextAlias()
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cQuery), cTempAlias, .F., .F.)

    jResponse := JsonObject():New()
    jResponse["items"] := {}

    while (cTempAlias)->(!EOF())
        aAdd(jResponse["items"], JsonObject():New())
        jTempItem := aTail(jResponse["items"])

        jTempItem["email"]       := RTrim((cTempAlias)->ZT0_EMAIL)
        jTempItem["user_id"]     := RTrim((cTempAlias)->ZT0_USRID)
        jTempItem["name"]        := RTrim((cTempAlias)->ZT0_NOME)
        jTempItem["admin"]       := (cTempAlias)->ZT0_ADMIN == "1"
        jTempItem["inserted_at"] := (cTempAlias)->ZT0_INS_AT
        jTempItem["updated_at"]  := (cTempAlias)->ZT0_UPD_AT
        (cTempAlias)->(DbSkip())
    enddo

    (cTempAlias)->(DbCloseArea())

    self:SetResponse(jResponse:ToJson())
return lProcessed
