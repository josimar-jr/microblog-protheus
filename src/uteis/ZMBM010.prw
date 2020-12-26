#include "protheus.ch"

static oStmpIdx := FWPreparedStatement():New("CREATE INDEX ? ON ? (S_T_A_M_P_,R_E_C_N_O_,D_E_L_E_T_) ")
static oInsDtIdx := FWPreparedStatement():New("CREATE INDEX ? ON ? (I_N_S_D_T_,R_E_C_N_O_,D_E_L_E_T_) ")

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
        EnableStamp(aAliases, .T.)
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

/*/{Protheus.doc} EnableStamp
    Adiciona os campos que representam o timestamp nos registros na tabela
@type   function
@author josimar.assuncao
@since  26.12.2020
/*/
static function EnableStamp(xTable, lIndex)
    local nX        as numeric
    local aTables   as array
    local aStruct   as array
    local cTable    as character
    local cSqlTable as character
    local cTCConfig as character

    cTCConfig := "TCCONFIG"

    if ValType( xTable ) == "C"
        aTables := { xTable }
    else
        aTables := AClone( xTable )
    endif

    &cTCConfig.("SETUSEROWSTAMP=ON") // Liga o UseRowStamp para a conexao atual
    &cTCConfig.("SETAUTOSTAMP=ON")   // Liga o AutoStamp para  conexao atual
    &cTCConfig.("SETUSEROWINSDT=ON") // Liga o UseInsDt para  conexao atual
    &cTCConfig.("SETAUTOINSDT=ON")   // Liga o AutoInsDt para  conexao atual

    for nX := 1 to Len(aTables)
        cTable := aTables[nX]

        DBSelectArea(cTable)
        (cTable) -> (DbCloseArea())

        cSqlTable := RetSqlName(cTable)
        TCRefresh(cSqlTable)

        DBSelectArea(cTable)
        aStruct := TcStruct(cSqlTable)

        // campos foram criados?
        if AScan(aStruct, {|field| field[1] == "S_T_A_M_P_" }) == 0 .Or. ;
            AScan(aStruct, {|field| field[1] == "I_N_S_D_T_"}) == 0

            UserException("Não foi possível criar algum dos campos 'I_N_S_D_T_' ou 'S_T_A_M_P_' verifique o dbaccess")
        else
            EnableStmpIdx(cSqlTable)
            EnableInsDtIdx(cSqlTable)
        endif
    next

    // Desliga as propriedades para não afetar outras tabelas do ERP
    &cTCConfig.("SETUSEROWSTAMP=OFF")
    &cTCConfig.("SETAUTOSTAMP=OFF")
    &cTCConfig.("SETUSEROWINSDT=OFF")
    &cTCConfig.("SETAUTOINSDT=OFF")
return

/*/{Protheus.doc} EnableStmpIdx
    Cria o índice para o campo que representa a modificação
@type   function
@author josimar.assuncao
@since  26.12.2020
/*/
static function EnableStmpIdx(cSqlTable)
    local cIndex as character
    cIndex := cSqlTable + "_STAMP"

    if !TcCanOpen(cSqlTable, cIndex)
        oStmpIdx:SetUnsafe(1,cIndex)
        oStmpIdx:SetUnsafe(2,cSqlTable)
        if TcSqlExec(oStmpIdx:GetFixQuery()) < 0
            UserException("Não foi possível criar o índice para o campo 'S_T_A_M_P_'")
        else
            TCRefresh( cSqlTable )
        endif
    endif
return

/*/{Protheus.doc} EnableInsDtIdx
    Cria o índice para o campo que representa a criação do registro
@type   function
@author josimar.assuncao
@since  26.12.2020
/*/
static function EnableInsDtIdx(cSqlTable)
    local cIndex as character
    cIndex := cSqlTable + "_INSDT"

    if !TcCanOpen(cSqlTable, cIndex)
        oInsDtIdx:SetUnsafe(1,cIndex)
        oInsDtIdx:SetUnsafe(2,cSqlTable)
        if TcSqlExec(oInsDtIdx:GetFixQuery()) < 0
            UserException("Não foi possível criar o índice para o campo 'I_N_S_D_T_'")
        else
            TCRefresh( cSqlTable )
        endif
    endif
return
