#include 'totvs.ch'

/*/{Protheus.doc} Converte DTC anterior a versão em banco de dados para um compátivel
 Converte DTC anterior a versão em banco de dados para um compativel
@author  Lucas Briesemeister
@since   08/2020
@version 12.1.27
/*/
User Function X3Converter(cEmp, cFil, cFolder, cOriginal, cConverted)

    Local cAliasOriginal := "SX3CTREE"
    Local cAliasConverted := "SX3CTREE_CONVERTED"
    Local cExt := ".dtc"

    Default cFolder := "\dcl_ctree\"
    Default cOriginal :=  "sx3_dcl"
    Default cEmp := "18"
    Default cFil := "D MG 01"
    Default cConverted := cOriginal + "_converted"

    cOriginal += cExt
    cConverted += cExt

    RpcSetEnv(cEmp, cFil)

    DBUseArea(.T.,/*cDriver*/,cFolder + cOriginal, cAliasOriginal,.T.,.T.)

    DBCreate(cFolder + cConverted , AdjustStruct(DBStruct()), "CTREECDX")

    DBUseArea(.T.,/*cDriver*/,cFolder + cConverted, cAliasConverted,.T.,.F.)

    (cAliasOriginal)->(DBGoTop())

    While !(cAliasOriginal)->(EoF())
        InsertLine(cAliasOriginal, cAliasConverted)
        (cAliasOriginal)->(DbSKip())
    End
    
    (cAliasConverted)->(DBCloseArea())
    (cAliasOriginal)->(DBCloseArea())

    //__CopyFile(cDirLocal+cArquivo, cDirServ+cArquivo+"2")

Return

//-------------------------------------------------------------------
/*/{Protheus.doc} AdjustStruct(aStruct)
Compatibiliza SX3 com a atual do banco
@author  Lucas Briesemeister
@since   08/2020
@version 12.1.27
/*/
//-------------------------------------------------------------------
Static Function AdjustStruct(aStruct)
    Local aNewStruct as array 
    Local nX         as numeric
    Local aSizes     as array

    aNewStruct := AClone(aStruct)

    For nX := 1 To Len(aNewStruct)
        aSizes := GetSX3Field(aNewStruct[nX][1])

        If !Empty(aSizes)
            aNewStruct[nX][3] := aSizes[3]
            aNewStruct[nX][4] := aSizes[4]
        EndIf
    Next nX

Return aNewStruct
//-------------------------------------------------------------------
/*/{Protheus.doc} InsertLine(cAliasOriginal, cAliasConverted)
Insere uma linha no alias novo, com base no antigo
@author  Lucas Briesemeister
@since   08/2020
@version 12.1.27
/*/
//-------------------------------------------------------------------
Static Function InsertLine(cAliasOriginal, cAliasConverted)
    
    Local aStruct := (cAliasOriginal)->(DBStruct())
    Local nX      := 1
    Local cField := ""
    
    If Reclock(cAliasConverted, .T.)
        (cAliasConverted)->X3_USADO := X3TreatUso((cAliasOriginal)->X3_USADO)
        (cAliasConverted)->X3_OBRIGAT := X3TreatUso((cAliasOriginal)->X3_OBRIGAT)
        (cAliasConverted)->X3_RESERV := Bin2Str((cAliasOriginal)->X3_RESERV)

        For nX := 1 To Len(aStruct)
            cField := aStruct[nX][1] 
            If !cField $ "X3_USADO;X3_OBRIGAT;X3_RESERV"
                (cAliasConverted)->(&(cField)) := (cAliasOriginal)->(&(cField))
            EndIf
        Next nX
        (cAliasConverted)->(MsUnlock())
    EndIf
Return
//-------------------------------------------------------------------
/*/{Protheus.doc} GetSX3Field(cField)
Retorna tamanho do campo da SX3
@author  Lucas Briesemeister
@since   08/2020
@version 12.1.27
/*/
//-------------------------------------------------------------------
Static Function GetSX3Field(cField)

    Local aField  := {}
    Local cAlias  := GetNextAlias()
    Local aStruct := {}
    Local nPos    := 0

    BeginSql Alias cAlias
        SELECT TOP 1 *
        FROM %table:SX3%
        WHERE %notDel%
    EndSql

    if !Empty(cField) .and. !(cAlias)->(EoF())
        aStruct := (cAlias)->(DBStruct())
        nPos := AScan(aStruct,{|x| x[1] == cField})
        aField := AClone(aStruct[nPos])
    EndIf   

    (cAlias)->(DBCloseArea())

Return aField
