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
WsRestful Perfis Description "Trata a atualização dos perfis que usam o microblog"
    WsData pageSize         as integer optional
    WsData page             as integer optional
    WsData perfilId         as character optional

    WsMethod GET V1ALL Description "Recupera todos os perfis" Path "/microblog/v1/perfis"
    WsMethod GET V1ID Description "Recupera um perfil pelo id" Path "/microblog/v1/perfis/{perfilId}"

    WsMethod POST V1ROOT Description "Cria um perfil para o microblog" Path "/microblog/v1/perfis"
    WsMethod PUT V1ID Description "Faz a atualização de um perfil" Path "/microblog/v1/perfis/{perfilId}"
    WsMethod DELETE V1 Description "Faz a exclusão de um perfil" Path "/microblog/v1/perfis/{perfilId}"
End WsRestful

//-------------------------------------------------------------------
/*/{Protheus.doc} GET
    Recupera todos os perfis
@type    method

@author  josimar.assuncao
@since   22.11.2020
/*/
//-------------------------------------------------------------------
WsMethod GET V1ALL WsReceive page, pageSize WsService Perfis
    local lProcessed as logical
    lProcessed := .T.

    // Define o tipo de retorno do método
    ::SetContentType("application/json")

    // As propriedades da classe receberão os valores enviados por querystring
    // exemplo: http://localhost:18085/rest/microblog/v1/perfis?page=1&pageSize=5
    DEFAULT ::page := 1, ::pageSize := 5

    // exemplo de retorno de uma lista de objetos JSON
    ::SetResponse('[')
    ::SetResponse('{"id": "value1"},')
    ::SetResponse('{"id": "value2"},')
    ::SetResponse('{"id": "value3"}')
    ::SetResponse(']')
return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} GET V1ID
    Recupera um perfil pelo id
@type    method

@author  josimar.assuncao
@since   22.11.2020
/*/
//-------------------------------------------------------------------
WsMethod GET V1ID PathParam perfilId WsService Perfis
    local lProcessed as logical
    lProcessed := .T.
    ::SetContentType("application/json")
    ::SetResponse('{"id": "' + self:perfilId + '"}')
Return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} POST V1ROOT
    Cria um perfil para o microblog
@type   method

@author josimar.assuncao
@since  22.11.2020
/*/
//-------------------------------------------------------------------
WsMethod POST V1ROOT WsService Perfis
    local lProcessed as logical
    lProcessed := .T.
    ::SetContentType("application/json")
    ::SetResponse('{"id": "id_post"}')
Return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} PUT V1ID
    Faz a atualização de um perfil
@type    method

@author  josimar.assuncao
@since   22.11.2020
/*/
//-------------------------------------------------------------------
WsMethod PUT V1ID PathParam perfilId WsService Perfis
    local lProcessed as logical
    lProcessed := .T.
    ::SetContentType("application/json")
    ::SetResponse('{"id": "' + self:perfilId + '"}')
Return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} DELETE V1
    Faz a exclusão de um perfil
@type    method

@author  josimar.assuncao
@since   22.11.2020
/*/
//-------------------------------------------------------------------
WsMethod DELETE V1 PathParam perfilId WsService Perfis
    local lProcessed as logical
    lProcessed := .T.
    ::SetContentType("application/json")
    ::SetResponse('{}')
Return lProcessed
