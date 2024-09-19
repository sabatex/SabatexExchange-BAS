
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Query = New Query;
	Query.Text = 
		"SELECT
		|	COUNT(sabatexExchangeObject.Id) AS CountItems
		|FROM
		|	InformationRegister.sabatexExchangeUnresolvedObjects AS sabatexExchangeObject";
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	if SelectionDetailRecords.Next() then
		recordCount = SelectionDetailRecords.CountItems;	
	endif;
EndProcedure
