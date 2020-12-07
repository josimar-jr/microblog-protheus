#include "protheus.ch"
#include "restful.ch"
#include "fwmvcdef.ch"

static _oModelDef := Nil

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
    wsdata filter           as character optional

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
    end

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

    oModel := GetMyModel()
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
        // Chama uma fun��o que garante um �nico do modelo
        oModel := GetMyModel()

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
            // Chama uma fun��o que garante um �nico do modelo
            oModel := GetMyModel()

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
            oModel := GetMyModel()

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
/*/{Protheus.doc} GetMyModel
    Fun��o para carregar uma vez na thread o modelo de dados
@type    method

@author  josimar.assuncao
@since   04.12.2020
/*/
//-------------------------------------------------------------------
static function GetMyModel()

    if _oModelDef == nil
        _oModelDef := FwLoadModel("ZMBA010")
    endif
return _oModelDef

//-------------------------------------------------------------------
/*/{Protheus.doc} GET V2ALL
    Recupera todos os perfis permite pagina��o, ordena��o e filtro
constru�dos exclusivamente para este m�todo
@type    method

@author  josimar.assuncao
@since   22.11.2020
/*/
//-------------------------------------------------------------------
wsmethod GET V2ALL wsreceive page, pageSize, order, filter, fields wsservice Perfis
    local lProcessed as logical
    local jResponse  as object
    local jTempItem  as object
    lProcessed := .T.

    // Define o tipo de retorno do m�todo
    self:SetContentType("application/json")

    // As propriedades da classe receber�o os valores enviados por querystring
    // exemplo: /rest/microblog/v1/perfis?page=1&pageSize=5&order=-user_id&fields=user_id,email
    default self:page := 1
    default self:pageSize := 5
    default self:order := ""
    default self:fields := ""
    default self:filter := ""

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
    end

    self:SetResponse(jResponse:ToJson())
return lProcessed
