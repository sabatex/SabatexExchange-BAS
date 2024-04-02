
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
		//{{QUERY_BUILDER_WITH_RESULT_PROCESSING
	// Даний фрагмент побудований конструктором.
	// При повторному використанні конструктора, внесені вручну зміни будуть втрачені!!!
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	SabatexExchangeNodeConfig.NodeName AS NodeName
		|FROM
		|	InformationRegister.SabatexExchangeNodeConfig AS SabatexExchangeNodeConfig
		|WHERE
		|	SabatexExchangeNodeConfig.isActive = TRUE";
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		Items.NodeSelector.ChoiceList.Add(SelectionDetailRecords.NodeName);
	EndDo;
	
	//}}QUERY_BUILDER_WITH_RESULT_PROCESSING

EndProcedure

&AtServer
Procedure SendQueryAtServer()
	SabatexExchange.RegisterQueryObjectsForNode(Object.NodeSelector,"all",Object.DateQuery);
EndProcedure

&AtClient
Procedure SendQuery(Command)
	SendQueryAtServer();
	Items.SendQuery.Enabled = false;
EndProcedure

&AtClient
Procedure DateQueryOnChange(Item)
	Items.SendQuery.Enabled = true;
EndProcedure
