#include 'protheus.ch'
#include 'fwmvcdef.ch'

//-------------------------------------------------------------------
/*/{Protheus.doc} PerfisBaseAdapterApi
    Classe para utilizar o modelo FwBaseAdapterV2 para APIs
@type   class
@author  josimar.assuncao
@since   28.04.2021
/*/
//-------------------------------------------------------------------
class PerfisBaseAdapterApi from FWAdapterBaseV2
    data jPostResponse as object
    method New()

    static method buildGetList()
    static method buildGetOne()
    static method buildPostOne()
    // static method buildGetList()

    method GetPerfisList()
    method GetPerfilId()
    method PostPerfil()

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
method GetPerfisList() class PerfisBaseAdapterApi
    local lProcessed as logical
    local aArea      as array
    local cWhere     as character

    lProcessed := .T.
    aArea := FwGetArea()
    // Adiciona o mapa de campos Json/ResultSet
    AddMapFields(self)

    // Informa a Query a ser utilizada pela API
    self:SetQuery(GetQuery())

    // Informa a clausula Where da Query
    cWhere := " ZT0_FILIAL = '"+ FWxFilial('ZT0') +"' AND ZT0.D_E_L_E_T_ = ' '"
    self:SetWhere(cWhere)

    // Informa a ordenação padrão a ser Utilizada pela Query
    self:SetOrder("ZT0_NOME")

    // Executa a consulta, se retornar .T. tudo ocorreu conforme esperado
    lProcessed := self:Execute()
    if lProcessed
        // Gera o Json com o retorno da query
        self:FillGetResponse()
    endif

    FwRestArea(aArea)
return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} buildGetOne
    Cria uma instância da classe para o processamento do método GET para id
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
method GetPerfilId(cPerfilId) class PerfisBaseAdapterApi
    local lProcessed as logical
    local aArea      as array
    local cWhere     as character

    lProcessed := .T.
    aArea := FwGetArea()
    // Adiciona o mapa de campos Json/ResultSet
    AddMapFields(self)

    // Informa a Query a ser utilizada pela API
    self:SetQuery(GetQuery())

    // Informa a clausula Where da Query
    cWhere := " ZT0_FILIAL = '"+ FWxFilial('ZT0') +"' AND ZT0_USRID = ? AND ZT0.D_E_L_E_T_ = ' '"
    cWhere := FwStateSql(cWhere, { cPerfilId })
    self:SetWhere(cWhere)

    // Informa a ordenação padrão a ser Utilizada pela Query
    self:SetOrder("ZT0_NOME")

    // Executa a consulta, se retornar .T. tudo ocorreu conforme esperado
    lProcessed := self:Execute()
    if lProcessed
        // Gera o Json com o retorno da query
        self:FillGetResponse()
    endif

    FwRestArea(aArea)
return lProcessed

//-------------------------------------------------------------------
/*/{Protheus.doc} buildPostOne
    Cria uma instância da classe para o processamento do método POST
@type   class
@author  josimar.assuncao
@since   28.04.2021
/*/
//-------------------------------------------------------------------
method buildPostOne() class PerfisBaseAdapterApi
    local oInstance as object

    oInstance := PerfisBaseAdapterApi():New("POST")
return oInstance

//-------------------------------------------------------------------
/*/{Protheus.doc} PostPerfil
    Faz a inclusão de um perfil utilizando a leitura pela FwBaseAdapterV2
@type   class
@author  josimar.assuncao
@since   28.04.2021
/*/
//-------------------------------------------------------------------
method PostPerfil() class PerfisBaseAdapterApi
    local lProcessed as logical
    local oModel as object
    local aError as array

    AddMapFields(self)
    lProcessed := self:ValidContent()

    if lProcessed
        oModel := FwLoadModel("ZMBA010")

        oModel:SetOperation(MODEL_OPERATION_INSERT)

        lProcessed := oModel:Activate()
        oZT0Header := oModel:GetModel("ZT0_FIELDS")

        lProcessed := lProcessed .And. oZT0Header:SetValue("ZT0_EMAIL" , self:GetERPValue('ZT0_EMAIL'))
        lProcessed := lProcessed .And. oZT0Header:SetValue("ZT0_USRID" , self:GetERPValue('ZT0_USRID'))
        lProcessed := lProcessed .And. oZT0Header:SetValue("ZT0_NOME"  , self:GetERPValue('ZT0_NOME'))

        lProcessed := lProcessed .And. oModel:VldData() .And. oModel:CommitData()

        self:jPostResponse := JsonObject():New()
        if lProcessed
            self:jPostResponse["email"]   := oZT0Header:GetValue("ZT0_EMAIL")
            self:jPostResponse["user_id"] := oZT0Header:GetValue("ZT0_USRID")
            self:jPostResponse["name"]    := oZT0Header:GetValue("ZT0_NOME")
            // self:jPostResponse["inserted_at"] := ZT0->S_T_A_M_P_
            // self:jPostResponse["updated_at"] := ZT0->I_N_S_D_T_
        else
            aError := oModel:GetErrorMessage()
            self:jPostResponse["error"] := "creation_failed"
            self:jPostResponse["description"] := aError[MODEL_MSGERR_MESSAGE]
        endif
    endif
return lProcessed
