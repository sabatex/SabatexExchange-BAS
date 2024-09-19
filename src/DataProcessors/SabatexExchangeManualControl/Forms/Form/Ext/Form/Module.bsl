&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	nodes = SabatexExchangeConfig.GetDestinationNodes();
	for each node in nodes do
		Items.NodeSelector.ChoiceList.Add(node.NodeName);
		Items.NodeSelectorForSend.ChoiceList.Add(node.NodeName);
		Items.NodeObjectsSelector.ChoiceList.Add(node.NodeName);
	EndDo;
	
	If Object.NodeSelector <> "" then
		NodeSelectorOnChangeAtServer(Object.NodeSelector)
	endif;
	
	If Object.NodeSelectorForSend <> "" then
		NodeSelectorForSendOnChangeAtServer(Object.NodeSelectorForSend);
	endif;
	
	
	
	
	
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

&AtServer
Procedure NodeSelectorForSendOnChangeAtServer(nodeName)
	objectsNameList = new Array;
	try
		conf = SabatexExchangeConfig.GetConfigByNodeName(nodeName);
		// The user config must include procedure ObjectPostList(conf,objectsNameList)
		Execute(conf.userDefinedModule+".ObjectPostList(conf,objectsNameList)");
	except
		Message("Помилка виконання методу користувача - .ObjectPostList(conf,items)");
	endtry;
	ObjectTypesSend.Clear();
	for each objectsName in objectsNameList do
		row = ObjectTypesSend.Add();
		row.Checked = true;
		row.Name = objectsName;
	EndDo;

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



&AtClient
Procedure NodeSelectorOnChange(Item)
	NodeSelectorOnChangeAtServer(Object.NodeSelector);
EndProcedure

&AtClient
Procedure NodeSelectorForSendOnChange(Item)
	NodeSelectorForSendOnChangeAtServer(Object.NodeSelectorForSend);
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
&AtClient
Procedure SelectAllSend(Command)
	for each row in ObjectTypesSend do
		row.Checked = true;
	enddo;
EndProcedure
&AtClient
Procedure UnSelectAllSend(Command)
	for each row in ObjectTypesSend do
		row.Checked = false;
	enddo;
EndProcedure




&AtServer
Procedure SendDataAtServer()
	conf = SabatexExchangeConfig.GetConfigByNodeName(Object.NodeSelectorForSend);
	for each objectDescriptor in  ObjectTypesSend do
		if objectDescriptor.Checked then
			try
	        	Query = New Query;
				Query.Text = 
				"SELECT
				|	Objects.Ref AS Ref
				|FROM
				|	"+objectDescriptor.Name+ " AS Objects
				|WHERE
				|	Objects.date  BETWEEN BEGINOFPERIOD(&DateBegin, DAY) AND ENDOFPERIOD(&DateEnd, DAY)
				|	AND Objects.DeletionMark = FALSE";
				
				Query.SetParameter("DateBegin",Object.DateSelect);
				Query.SetParameter("DateEnd", Object.DateSelect);
				
				QueryResult = Query.Execute();
	            SelectionDetailRecords = QueryResult.Select();
	            While SelectionDetailRecords.Next() Do
					SabatexExchange.RegisterMessageForNode(conf.NodeName,,SelectionDetailRecords.Ref.GetObject(),true);
				EndDo;
			except
				Message("Помилка реэстрації повідомлень: " + ErrorDescription());
			endtry;
		endif;
	enddo;
EndProcedure


&AtClient
Procedure SendData(Command)
	SendDataAtServer();
EndProcedure

&AtServer
Procedure ObjectSelectorOnChangeAtServer()
	if Object.ObjectSelector = "" then
		Object.ObjectSelector = "Справочник.SabatexExchangeObjectSinchro"
	endif;	
    UniversalO.QueryText = 
	"SELECT
	|	Obj.Ref AS Ref,
	|	Obj.SabatexExchangeId AS SabatexExchangeId
	|FROM
	|	" + Object.ObjectSelector + " AS Obj";
	Items.UniversalO.Refresh();

EndProcedure

&AtClient
Procedure ObjectSelectorOnChange(Item)
	ObjectSelectorOnChangeAtServer();
EndProcedure

&AtServer
Procedure NodeObjectsSelectorOnChangeAtServer(NodeName)
	conf = SabatexExchangeConfig.GetConfigByNodeName(NodeName);
	for each obj in conf.Objects do
		if obj.Value.UseIdAttribute then
			Items.ObjectSelector.ChoiceList.Add(obj.Value.ObjectType);
		endif;
	enddo;	
EndProcedure

&AtClient
Procedure NodeObjectsSelectorOnChange(Item)
	NodeObjectsSelectorOnChangeAtServer(Object.NodeObjectSelector);
EndProcedure

&AtClient
Procedure UniversalOBeforeRowChange(Item, Cancel)
	obj = Items.UniversalO.CurrentData;
    OpenForm("Обработка.SabatexExchangeManualControl.Форма.ObjectEditForm",new structure("ObjectRef",obj.Ref),ThisForm);
	Cancel=true; 
	Items.UniversalO.Refresh();

EndProcedure





