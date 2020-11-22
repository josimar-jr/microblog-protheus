#include "protheus.ch"

//-------------------------------------------------------------------
/*/{Protheus.doc} m010Stamp
    Assegura que as tabelas do projeto possuem a estrutura com
    os campos de timestamp habilitado
@type    function

@author  josimar.assuncao
@since   22.11.2020
/*/
//-------------------------------------------------------------------
user function m010Stamp()
    local aBase as array
    local aAliases as array

    aBase := {"ZT0", "ZT1", "ZT2"}
    aAliases := GetNoStampTables(aBase)

    if Len(aAliases) > 0
        // Isso vai habilitar dois novos campos S_T_A_M_P_ e I_N_S_D_T_ na tabela
        FWEnableStamp(aAliases, .T.)
    endif
return

//-------------------------------------------------------------------
/*/{Protheus.doc} GetNoStampTables
    Identifica quais tabelas da lista informada não tem os campos de
    timestamp habilitados
@type    function

@author  josimar.assuncao
@since   22.11.2020
/*/
//-------------------------------------------------------------------
static function GetNoStampTables(aAliases)
    local aNoStamps as array
    local aTempStruct as array
    local nTables as numeric
    local cRealName as character
    local lInsDate as logical
    local lStmpDate as logical

    aNoStamps := {}

    for nTables := 1 to Len(aAliases)
        cRealName := RetSqlName(aAliases[nTables])
        aTempStruct := FWSQLStruct(cRealName)

        lStmpDate := aScan(aTempStruct, {|x| x[1] == 'S_T_A_M_P_'}) > 0
        lInsDate := aScan(aTempStruct, {|x| x[1] == 'I_N_S_D_T_'}) > 0

        // Quando algum dos campos não foi criado, deveria fazer a criação
        if !(lStmpDate .And. lInsDate)
            aAdd(aNoStamps, aAliases[nTables])
        endif
    next nTables

return aNoStamps
