&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	nodes = SabatexExchangeConfig.GetDestinationNodes();
	for each node in nodes do
		Items.NodeSelector.ChoiceList.Add(node.NodeName);
	EndDo;
	
	If Object.NodeSelector <> "" then
		NodeSelectorOnChangeAtServer(Object.NodeSelector)
	endif;
	
	
	
EndProcedure

&AtServer
Procedure SendQueryAtServer()
	conf = SabatexExchangeConfig.GetConfigByNodeName(Object.NodeSelector);
	for each node in  ObjectTypes do
		if node.Checked then
			SabatexExchange.RegisterQueryObjectsForNode(conf,node.Name,Object.DateQuery);
		endif;
	enddo;
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

&AtServer
Procedure NodeSelectorOnChangeAtServer(nodeName)
	objectsNameList = new Array;
	try
		conf = SabatexExchangeConfig.GetConfigByNodeName(nodeName);
		Execute(conf.userDefinedModule+".ObjectQueriesList(conf,objectsNameList)");
	except
		Message("Помилка виконання методу користувача - .ObjectQueriesList(conf,items)");
	endtry;
	ObjectTypes.Clear();
	for each objectsName in objectsNameList do
		row = ObjectTypes.Add();
		row.Checked = true;
		row.Name = objectsName;
	EndDo;
EndProcedure


&AtClient
Procedure NodeSelectorOnChange(Item)
	NodeSelectorOnChangeAtServer(Object.NodeSelector);
EndProcedure


&AtClient
Procedure UnSelectAll(Command)
	for each row in ObjectTypes do
		row.Checked = false;
	enddo;
EndProcedure


&AtClient
Procedure SelectAll(Command)
	for each row in ObjectTypes do
		row.Checked = true;
	enddo;
EndProcedure

