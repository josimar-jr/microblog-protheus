#include "protheus.ch"
#include "fwmvcdef.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} ZMBA010
    Browse simples para exibir os dados da tabela ZT0 - Perfis
@type    function

@author  josimar.assuncao
@since   22.11.2020
/*/
//-------------------------------------------------------------------
user function ZMBA010()
    u_m010Stamp()
    AxCadastro("ZT0")
return

//-------------------------------------------------------------------
/*/{Protheus.doc} ZMBA010
    Browse simples para exibir os dados da tabela ZT0 - Perfis
@type    function

@author  josimar.assuncao
@since   22.11.2020
/*/
//-------------------------------------------------------------------
static function ModelDef()
    local oModel   as object
    local oStrZT0  as object

    oStrZT0 := FWFormStruct(1, "ZT0")
    oModel := MpFormModel():New("ZMBMODEL")

    oModel:AddFields("ZT0_FIELDS", , oStrZT0)
    oModel:SetDescription("Cadastro de perfis")
    oModel:GetModel("ZT0_FIELDS"):SetDescription("Perfis")

return oModel

// http://localhost:18085/rest/fwmodel/Perfis/
PUBLISH USER MODEL REST NAME Perfis SOURCE ZMBA010

// http://localhost:18085/rest/fwmodel/ZMBA010/
PUBLISH USER MODEL REST NAME ZMBA010 SOURCE ZMBA010
