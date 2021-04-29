#include 'protheus.ch'

//-------------------------------------------------------------------
/*/{Protheus.doc} PerfisBaseAdapterApi
    Classe para utilizar o modelo FwBaseAdapterV2 para APIs
@type   class
@author  josimar.assuncao
@since   28.04.2021
/*/
//-------------------------------------------------------------------
class PerfisBaseAdapterApi from FWAdapterBaseV2

    method New()

    static method buildGetList()
    Static Method buildGetOne()
    // Static Method buildGetList()
    // Static Method buildGetList()

    method GetPerfisList()
    method GetPerfilId()

endclass

//-------------------------------------------------------------------
/*/{Protheus.doc} New
    Cria uma instância da classe para o processamento de algum método
@type   class
@author  josimar.assuncao
@since   28.04.2021
/*/
//-------------------------------------------------------------------
method New(cMethod, lIsList) class PerfisBaseAdapterApi
    _Super:New(cMethod, lIsList)
return

//-------------------------------------------------------------------
/*/{Protheus.doc} AddMapFields
    Monta a lista de campos para retorno e controle da API
@type   class
@author  josimar.assuncao
@since   28.04.2021
/*/
//-------------------------------------------------------------------
static function AddMapFields(oAdapter)
    oAdapter:AddMapFields('email', 'ZT0_EMAIL', .T., .T., {'ZT0_EMAIL', 'C', TamSX3('ZT0_EMAIL')[1], 0})
    oAdapter:AddMapFields('user_id', 'ZT0_USRID', .T., .T., {'ZT0_USRID', 'C', TamSX3('ZT0_USRID')[1], 0})
    oAdapter:AddMapFields('name', 'ZT0_NOME', .T., .T., {'ZT0_NOME', 'C', TamSX3('ZT0_NOME')[1], 0})
    oAdapter:AddMapFields('admin', 'ZT0_ADMIN', .T., .T., {'ZT0_ADMIN', 'C', TamSX3('ZT0_ADMIN')[1], 0})
    oAdapter:AddMapFields('inserted_at', 'ZT0_INS_AT', .T., .T., {'ZT0_INS_AT', 'C', 23, 0}, "convert(varchar(23), I_N_S_D_T_, 21)")
    oAdapter:AddMapFields('updated_at', 'ZT0_UPD_AT', .T., .T., {'ZT0_UPD_AT', 'C', 23, 0}, "convert(varchar(23), S_T_A_M_P_, 21)")
return

//-------------------------------------------------------------------
/*/{Protheus.doc} GetQuery
    Monta a query para pesquisa dos registros
@type   class
@author  josimar.assuncao
@since   28.04.2021
/*/
//-------------------------------------------------------------------
static function GetQuery()
    local cQuery as character

    //Obtem a ordem informada na requisição, a query exterior SEMPRE deve ter o id #QueryFields# ao invés dos campos fixos
    //necessáriamente não precisa ser uma subquery, desde que não contenha agregadores no retorno ( SUM, MAX... )
    //o id #QueryWhere# é onde será inserido o clausula Where informado no método SetWhere()
    cQuery := " SELECT #QueryFields#"
    cQuery +=   " FROM " + RetSqlName('ZT0') + " ZT0"
    cQuery += " WHERE #QueryWhere#"
return cQuery

//-------------------------------------------------------------------
/*/{Protheus.doc} buildGetList
    Cria uma instância da classe para o processamento do método GET para coleções
@type   class
@author  josimar.assuncao
@since   28.04.2021
/*/
//-------------------------------------------------------------------
method buildGetList() class PerfisBaseAdapterApi
    local oInstance as object

    oInstance := PerfisBaseAdapterApi():New("GET", .T.)
return oInstance

//-------------------------------------------------------------------
/*/{Protheus.doc} GetPerfisList
    Recupera uma lista de perfis conforme os parâmetros da requisição
@type   class
@author  josimar.assuncao
@since   28.04.2021
/*/
//-------------------------------------------------------------------
method GetPerfisList(oWSRest) class PerfisBaseAdapterApi
    local lProcessed as logical
    local aArea      as array
    local cWhere     as character

    lProcessed := .T.
    aArea := FwGetArea()
    // Adiciona o mapa de campos Json/ResultSet
    AddMapFields(self)

    // Informa a Query a ser utilizada pela API
    ::SetQuery(GetQuery())

    // Informa a clausula Where da Query
    cWhere := " ZT0_FILIAL = '"+ FWxFilial('ZT0') +"' AND ZT0.D_E_L_E_T_ = ' '"
    ::SetWhere(cWhere)

    // Informa a ordenação padrão a ser Utilizada pela Query
    ::SetOrder("ZT0_NOME")

    // Executa a consulta, se retornar .T. tudo ocorreu conforme esperado
    lProcessed := ::Execute()
    if lProcessed
        // Gera o arquivo Json com o retorno da Query
        ::FillGetResponse()
    endif

    FwRestArea(aArea)
return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} buildGetOne
    Cria uma instância da classe para o processamento do método GET para coleções
@type   class
@author  josimar.assuncao
@since   28.04.2021
/*/
//-------------------------------------------------------------------
method buildGetOne() class PerfisBaseAdapterApi
    local oInstance as object

    oInstance := PerfisBaseAdapterApi():New("GET", .F.)
return oInstance

//-------------------------------------------------------------------
/*/{Protheus.doc} GetPerfisList
    Recupera uma lista de perfis conforme os parâmetros da requisição
@type   class
@author  josimar.assuncao
@since   28.04.2021
/*/
//-------------------------------------------------------------------
method GetPerfilId(oWSRest) class PerfisBaseAdapterApi
    local lProcessed as logical
    local aArea      as array
    local cWhere     as character

    lProcessed := .T.
    aArea := FwGetArea()
    // Adiciona o mapa de campos Json/ResultSet
    AddMapFields(self)

    // Informa a Query a ser utilizada pela API
    ::SetQuery(GetQuery())

    // Informa a clausula Where da Query
    cWhere := " ZT0_FILIAL = '"+ FWxFilial('ZT0') +"' AND ZT0_USRID = '"+ oWSRest:perfilId +"' AND ZT0.D_E_L_E_T_ = ' '"
    ::SetWhere(cWhere)

    // Informa a ordenação padrão a ser Utilizada pela Query
    ::SetOrder("ZT0_NOME")

    // Executa a consulta, se retornar .T. tudo ocorreu conforme esperado
    lProcessed := ::Execute()
    if lProcessed
        // Gera o arquivo Json com o retorno da Query
        ::FillGetResponse()
    endif

    FwRestArea(aArea)
return lProcessed
