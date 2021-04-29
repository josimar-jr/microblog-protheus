#include "protheus.ch"
#include "restful.ch"
#include "fwmvcdef.ch"

#define QRY_PARAM_KEY 1
#define QRY_PARAM_VALUE 2

#define MAP_PROP 1
#define MAP_FIELD 2
#define MAP_TYPE 3
#define MAP_INTERNAL_FIELD 4

#define QRY_VAL_TYPE 1
#define QRY_VAL_VALUE 2

//-------------------------------------------------------------------
/*/{Protheus.doc} perfis
    Classe para aplicar a atualização dos perfis das pessoas no microblog
@type   class

@author  josimar.assuncao
@since   22.11.2020
/*/
//-------------------------------------------------------------------
wsrestful Perfis description "Trata a atualização dos perfis que usam o microblog"
    wsdata pageSize         as integer optional
    wsdata page             as integer optional
    wsdata perfilId         as character optional
    wsdata order            as character optional
    wsdata fields           as character optional

    // versões 1 - utilizam Seek e Reclock nos processos de gravação
    wsmethod GET V1ALL description "Recupera todos os perfis" wssyntax "/microblog/v1/perfis" path "/microblog/v1/perfis"
    wsmethod POST V1ROOT description "Cria um perfil para o microblog" wssyntax "/microblog/v1/perfis" path "/microblog/v1/perfis"

    wsmethod GET V1ID description "Recupera um perfil pelo id" wssyntax "/microblog/v1/perfis/{perfilId}" path "/microblog/v1/perfis/{perfilId}"
    wsmethod PUT V1ID description "Faz a atualização de um perfil" wssyntax "/microblog/v1/perfis/{perfilId}" path "/microblog/v1/perfis/{perfilId}"
    wsmethod DELETE V1 description "Faz a exclusão de um perfil" wssyntax "/microblog/v1/perfis/{perfilId}" path "/microblog/v1/perfis/{perfilId}"

    // versões 2 - utilizam modelo nos processos de gravação
    wsmethod POST V2ROOT description "Cria um perfil para o microblog usando modelo MVC" wssyntax "/microblog/v2/perfis" path "/microblog/v2/perfis"

    wsmethod GET V2ID description "Recupera um perfil pelo id usando modelo MVC" wssyntax "/microblog/v2/perfis/{perfilId}" path "/microblog/v2/perfis/{perfilId}"
    wsmethod PUT V2ID description "Faz a atualização de um perfil usando modelo MVC" wssyntax "/microblog/v2/perfis/{perfilId}" path "/microblog/v2/perfis/{perfilId}"
    wsmethod DELETE V2 description "Faz a exclusão de um perfil usando modelo MVC" wssyntax "/microblog/v2/perfis/{perfilId}" path "/microblog/v2/perfis/{perfilId}"

    // versão 2 - recupera lista com propriedade para filtros e paginação
    wsmethod GET V2ALL description "Recupera todos os perfis" wssyntax "/microblog/v2/perfis" path "/microblog/v2/perfis"

    // versão 3 - utiliza FwBaseAdapterV2
    wsmethod GET V3ALL description "Recupera todos os perfis usando FwBaseAdapterV2" wssyntax "/microblog/v3/perfis" path "/microblog/v3/perfis"
    wsmethod GET V3ID description "Recupera um perfil pelo id usando FwBaseAdapterV2" wssyntax "/microblog/v3/perfis/{perfilId}" path "/microblog/v3/perfis/{perfilId}"

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

    // Define o tipo de retorno do método
    self:SetContentType("application/json")

    // As propriedades da classe receberão os valores enviados por querystring
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

    // Id não ser vazio e existir como item na tabela
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
        jResponse["description"] := i18n("Perfil não encontrado utilizando o #[id] informado", {self:perfilId})

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
        jResponse["description"] := "Forneça as propriedades 'email', 'user_id' e 'name' no body"

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
    Faz a atualização de um perfil
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

    // Id não ser vazio e existir como item na tabela
    lProcessed := (!(Alltrim(self:perfilId) == "") .And. ZT0->(DbSeek(xFilial("ZT0")+self:perfilId)))
    if lProcessed

        jBody := JsonObject():New()
        jBody:FromJson(self:GetContent())

        if (jBody["name"] == Nil)
            jResponse["error"] := "body_invalido"
            jResponse["description"] := "Forneça a propriedade 'name' no body"

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
        jResponse["description"] := i18n("Perfil não encontrado utilizando o #[id] informado", {self:perfilId})

        self:SetResponse(jResponse:ToJson())
        SetRestFault(404, jResponse:ToJson(), , 404)
        lProcessed := .F.
    endif

return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} DELETE V1
    Faz a exclusão de um perfil
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

    // Id não ser vazio e existir como item na tabela
    varinfo("id", self:perfilId)
    lProcessed := !(Alltrim(self:perfilId) == "")
    if lProcessed

        // Se não encontrar o registro, não faz nada e retorna verdadeiro
        lDelete := ZT0->(DbSeek(xFilial("ZT0")+self:perfilId))
        if lDelete
            Reclock("ZT0", .F.)
                DbDelete()
            ZT0->(MsUnlock())
        endif

        self:SetResponse("{}")
    else
        jResponse["error"] := "id_invalido"
        jResponse["description"] := i18n("Perfil não encontrado utilizando o #[id] informado", {self:perfilId})

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

    // Id não ser vazio e existir como item na tabela
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
        jResponse["description"] := i18n("Perfil não encontrado utilizando o #[id] informado", {self:perfilId})

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
        jResponse["description"] := "Forneça as propriedades 'email', 'user_id' e 'name' no body"

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
    Faz a atualização de um perfil usando MVC
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

    // Id não ser vazio e existir como item na tabela
    lProcessed := (!(Alltrim(self:perfilId) == "") .And. ZT0->(DbSeek(xFilial("ZT0")+self:perfilId)))
    if lProcessed

        jBody := JsonObject():New()
        jBody:FromJson(self:GetContent())

        if (jBody["name"] == Nil)
            jResponse["error"] := "body_invalido"
            jResponse["description"] := "Forneça a propriedade 'name' no body"

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
        jResponse["description"] := i18n("Perfil não encontrado utilizando o #[id] informado", {self:perfilId})

        self:SetResponse(jResponse:ToJson())
        SetRestFault(404, jResponse:ToJson(), , 404)
        lProcessed := .F.
    endif

return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} DELETE V2
    Faz a exclusão de um perfil usando MVC
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

    // Id não ser vazio e existir como item na tabela
    lProcessed := !(Alltrim(self:perfilId) == "")
    if lProcessed

        lDelete := ZT0->(DbSeek(xFilial("ZT0")+self:perfilId))
        if lDelete
            oModel := FwLoadModel("ZMBA010")

            oModel:SetOperation(MODEL_OPERATION_DELETE)
            lProcessed := oModel:Activate()

            // Se não encontrar o registro, não faz nada e retorna verdadeiro
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
        jResponse["description"] := i18n("Perfil não encontrado utilizando o #[id] informado", {self:perfilId})

        self:SetResponse(jResponse:ToJson())
        SetRestFault(404, jResponse:ToJson(), , 404)
        lProcessed := .F.
    endif

return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} GET V2ALL
    Recupera todos os perfis permite paginação, ordenação e filtro
construídos exclusivamente para este método
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
    local cDataQuery    as character
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
    local aRetProps     as array
    local nRetProps     as numeric
    local xPropValue
    local nCount        as numeric
    local cCountQuery   as character
    local cProjQuery    as character
    local cSubQuery     as character
    lProcessed := .T.

    // Define o tipo de retorno do método
    self:SetContentType("application/json")

    // As propriedades da classe receberão os valores enviados por querystring
    // exemplo: /rest/microblog/v1/perfis?page=1&pageSize=5&order=-name&fields=name,email
    default self:page := 1
    default self:pageSize := 10
    default self:order := ""
    default self:fields := ""
    // Mapeia os campos da query com as propriedades
    aFieldsMap := {;
        {"email", "ZT0_EMAIL", "C", "ZT0_EMAIL"},;
        {"user_id", "ZT0_USRID", "C", "ZT0_USRID"},;
        {"name", "ZT0_NOME", "C", "ZT0_NOME"},;
        {"admin", "ZT0_ADMIN", "L", "ZT0_ADMIN"},;
        {"inserted_at", "ZT0_INS_AT", "D", "I_N_S_D_T_"},;
        {"updated_at", "ZT0_UPD_AT", "D", "S_T_A_M_P_"} ;
    }
    // montagem da paginação
    nItemFrom := (self:page - 1) * self:pageSize + 1
    nItemTo := (self:page) * self:pageSize

    // montagem da ordem
    if !Empty(Alltrim(self:order))
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
                cOrderBy += aFieldsMap[nTemp, MAP_INTERNAL_FIELD] + cOrdDirection + ","
            endif
        next nI
        // Remove a última vírgula (,)
        cOrderBy := SubStr(cOrderBy, 1, Len(cOrderBy)-1)
    endif

    if Empty(cOrderBy)
        cOrderBy := "ZT0_NOME asc"
    endif

    // monta a condição para a query
    //  suporta filtros simples com operador LIKE -> campo like %valor%
    cCondition := "ZT0.D_E_L_E_T_ = ' ' "
    aQryValues := {}
    for nI := 1 To Len(self:aQueryString)
        cTempField := Lower(self:aQueryString[nI, QRY_PARAM_KEY])
        nTemp := aScan(aFieldsMap, {|x| x[MAP_PROP] == cTempField})
        // quando encontra cria a expressão e guarda o valor para atribuir
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

    // campos mapeados
    cProjQuery := "select ZT0_EMAIL, ZT0_USRID, ZT0_NOME, ZT0_ADMIN,"
    cProjQuery += "convert(varchar(23), I_N_S_D_T_, 21) ZT0_INS_AT,"
    cProjQuery += "convert(varchar(23), S_T_A_M_P_, 21) ZT0_UPD_AT,"
    cProjQuery += "ROW_NUMBER() OVER (order by "+ cOrderBy +") SEQITEM "

    // tabela e condições
    cSubQuery := "from " + RetSqlName("ZT0") + " ZT0 "
    cSubQuery += "where " + cCondition

    // query para os dados
    cDataQuery := "select * "
    cDataQuery += "from ( " + cProjQuery + cSubQuery + " ) QUERYDATA "
    cDataQuery += "where SEQITEM >= "+ cValToChar(nItemFrom) +" and SEQITEM <= "+ cValToChar(nItemTo) +" "

    oPrepStat := FwPreparedStatement():New(cDataQuery)
    for nI := 1 to Len(aQryValues)
        // atribui os valores de string com operador like
        if aQryValues[nI, QRY_VAL_TYPE] == "C"
            oPrepStat:SetLike(nI, aQryValues[nI, QRY_VAL_VALUE])

        // propriedade admin está com tipo lógico então faz igualdade 1=sim;2=não
        elseif aQryValues[nI, QRY_VAL_TYPE] == "L"
            if (Alltrim(aQryValues[nI, QRY_VAL_VALUE]) == "1" .Or. Alltrim(aQryValues[nI, QRY_VAL_VALUE]) == "true")
                cTemp := "1"
            else
                cTemp := "2"
            endif
            oPrepStat:SetString(nI, cTemp)
        endif
    next nI

    cDataQuery := oPrepStat:getFixQuery()

    cTempAlias := GetNextAlias()
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cDataQuery), cTempAlias, .F., .F.)

    jResponse := JsonObject():New()
    jResponse["items"] := {}

    // monta as propriedades escolhidas para retorno
    aRetProps := StrTokArr(self:fields, ",")
    nRetProps := Len(aRetProps)

    if nRetProps == 0
        aRetProps := {"email", "user_id", "name", "admin", "inserted_at", "updated_at"}
        nRetProps := Len(aRetProps)
    endif

    while (cTempAlias)->(!EOF())
        aAdd(jResponse["items"], JsonObject():New())
        jTempItem := aTail(jResponse["items"])

        for nI := 1 to nRetProps
            // recupera o nome da propriedade
            cTemp := aRetProps[nI]

            // recupera o mapa propriedade x campo
            nTemp := aScan(aFieldsMap, {|x| x[MAP_PROP] == cTemp})

            if nTemp > 0
                // recupera o valor para a propriedade
                xPropValue := (cTempAlias)->(FieldGet(FieldPos(aFieldsMap[nTemp, MAP_FIELD])))

                // atribui o valor na propriedade
                if aFieldsMap[nTemp, MAP_TYPE] == "C"
                    jTempItem[cTemp] := RTrim(xPropValue)
                elseif aFieldsMap[nTemp, MAP_TYPE] == "L"
                    jTempItem[cTemp] := xPropValue == "1"
                else
                    jTempItem[cTemp] := xPropValue
                endif
            endif
        next nI
        (cTempAlias)->(DbSkip())
    enddo

    (cTempAlias)->(DbCloseArea())

    // Recupera a quantidade de registros
    cCountQuery := "select count(*) ROWS_QT " + cSubQuery

    oPrepStat := FwPreparedStatement():New(cCountQuery)
    for nI := 1 to Len(aQryValues)
        // atribui os valores de string com operador like
        if aQryValues[nI, QRY_VAL_TYPE] == "C"
            oPrepStat:SetLike(nI, aQryValues[nI, QRY_VAL_VALUE])

        // propriedade admin está com tipo lógico então faz igualdade 1=sim;2=não
        elseif aQryValues[nI, QRY_VAL_TYPE] == "L"
            if (Alltrim(aQryValues[nI, QRY_VAL_VALUE]) == "1" .Or. Alltrim(aQryValues[nI, QRY_VAL_VALUE]) == "true")
                cTemp := "1"
            else
                cTemp := "2"
            endif
            oPrepStat:SetString(nI, cTemp)
        endif
    next nI

    cCountQuery := oPrepStat:getFixQuery()
    DbUseArea(.T., "TOPCONN", TcGenQry(,, cCountQuery), cTempAlias, .F., .F.)

    if (cTempAlias)->(EOF())
        nCount := 0
    else
        nCount := (cTempAlias)->ROWS_QT
    endif
    jResponse["size"] := nCount

    self:SetResponse(jResponse:ToJson())
return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} GET V3ALL
    Recupera todos os perfis permite paginação, ordenação e filtro
utilizando os recursos da classe FwBaseAdapterV2
@type    method

@author  josimar.assuncao
@since   28.04.2021
/*/
//-------------------------------------------------------------------
wsmethod GET V3ALL wsreceive page, pageSize, order, fields wsservice Perfis
    local oApiAdapter as object
    local lRet  as logical

    default self:Page      := 1
    default self:PageSize  := 10
    default self:Fields    := ""

    //PerfisBaseAdapterApi será a classe que implementa fornecer os dados para o WS
    // O primeiro parametro indica que iremos tratar o método GET
    oApiAdapter := PerfisBaseAdapterApi():buildGetList()

    //o método setPage indica qual página deveremos retornar
    //ex.: nossa consulta tem como resultado 100 produtos, e retornamos sempre uma listagem de 10 itens por página.
    // a página 1 retorna os itens de 1 a 10
    // a página 2 retorna os itens de 11 a 20
    // e assim até chegar ao final de nossa listagem de 100 produtos
    oApiAdapter:SetPage(self:Page)

    // setPageSize indica que nossa página terá no máximo n itens
    oApiAdapter:SetPageSize(self:PageSize)

    // SetOrderQuery indica a ordem definida por querystring
    oApiAdapter:SetOrderQuery(self:Order)

    // SetUrlFilter indica o filtro querystring recebido (pode se utilizar um filtro oData)
    oApiAdapter:SetUrlFilter(self:aQueryString)

    // SetFields indica os campos que serão retornados via querystring
    oApiAdapter:SetFields(self:Fields)

    // Esse método irá processar as informações
    lRet := oApiAdapter:GetPerfisList(self)

    //Se tudo ocorreu bem, retorna os dados via Json
    if lRet
        self:SetResponse(oApiAdapter:GetJSONResponse())
    else
        //Ou retorna o erro encontrado durante o processamento
        SetRestFault(oApiAdapter:GetCode(), oApiAdapter:GetMessage())
        lRet := .F.
   endif
   //faz a desalocação de objetos e arrays utilizados
   oApiAdapter:DeActivate()
   oApiAdapter := nil
return lRet

//-------------------------------------------------------------------
/*/{Protheus.doc} GET V3ID
    Recupera um perfil pelo id usando FwBaseAdapterV2
@type    method

@author  josimar.assuncao
@since   28.04.2021
/*/
//-------------------------------------------------------------------
wsmethod GET V3ID wsreceive fields wsservice Perfis
    local oApiAdapter as object
    local lRet  as logical

    default self:fields    := ""

    //PerfisBaseAdapterApi será a classe que implementa fornecer os dados para o WS
    // O primeiro parametro indica que iremos tratar o método GET
    oApiAdapter := PerfisBaseAdapterApi():buildGetOne()

    // SetFields indica os campos que serão retornados via querystring
    oApiAdapter:SetFields(self:Fields)

    // Esse método irá processar as informações
    lRet := oApiAdapter:GetPerfilId(self)

    //Se tudo ocorreu bem, retorna os dados via Json
    if lRet
        self:SetResponse(oApiAdapter:GetJSONResponse())
    else
        //Ou retorna o erro encontrado durante o processamento
        SetRestFault(oApiAdapter:GetCode(), oApiAdapter:GetMessage())
        lRet := .F.
   endif
   //faz a desalocação de objetos e arrays utilizados
   oApiAdapter:DeActivate()
   oApiAdapter := nil
return lRet
