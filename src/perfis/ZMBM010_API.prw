#include "protheus.ch"
#include "restful.ch"

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

    wsmethod GET V1ALL description "Recupera todos os perfis" wssyntax "/microblog/v1/perfis" path "/microblog/v1/perfis"
    wsmethod POST V1ROOT description "Cria um perfil para o microblog" wssyntax "/microblog/v1/perfis" path "/microblog/v1/perfis"

    wsmethod GET V1ID description "Recupera um perfil pelo id" wssyntax "/microblog/v1/perfis/{perfilId}" path "/microblog/v1/perfis/{perfilId}"
    wsmethod PUT V1ID description "Faz a atualização de um perfil" wssyntax "/microblog/v1/perfis/{perfilId}" path "/microblog/v1/perfis/{perfilId}"
    wsmethod DELETE V1 description "Faz a exclusão de um perfil" wssyntax "/microblog/v1/perfis/{perfilId}" path "/microblog/v1/perfis/{perfilId}"
end wsrestful

//-------------------------------------------------------------------
/*/{Protheus.doc} GET
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
