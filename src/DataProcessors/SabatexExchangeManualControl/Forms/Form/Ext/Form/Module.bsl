&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	nodes = SabatexExchange.GetActiveDestinationNodes();
	for each node in nodes do
		Items.NodeSelector.ChoiceList.Add(node);
		Items.NodeSelectorForSend.ChoiceList.Add(node);
		Items.NodeObjectsSelector.ChoiceList.Add(node);
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
		conf = SabatexExchange.GetConfigByNodeName(nodeName);
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
		conf = SabatexExchange.GetConfigByNodeName(nodeName);
		// The user config must include procedure ObjectPostList(conf,objectsNameList)
		Execute(conf.userDefinedModule+".ObjectPostList(conf,objectsNameList)");
	except
		Message("Помилка виконання методу користувача - .ObjectPostList(conf,items)");
	endtry;
	ObjectTypesSend.Clear();
	for each objectsName in objectsNameList do
		row = ObjectTypesSend.Add();
		row.Checked = true; 
		row.Predefined = true;
		row.Name = objectsName.ObjectType;
		row.Filter = objectsName.Filter;
	EndDo;

EndProcedure




&AtServer
Procedure SendQueryAtServer()
	conf = SabatexExchange.GetConfigByNodeName(Object.NodeSelector);
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
	conf = SabatexExchange.GetConfigByNodeName(Object.NodeSelectorForSend);
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
				if objectDescriptor.Filter <> "" then
					Query.Text = Query.Text + " AND " + objectDescriptor.Filter;
				endif;

				Query.SetParameter("DateBegin",Object.DateSelect);
				Query.SetParameter("DateEnd", Object.DateSelect);
				
				QueryResult = Query.Execute();
	            SelectionDetailRecords = QueryResult.Select();
	            While SelectionDetailRecords.Next() Do
					SabatexExchange.RegisterMessageForNode(conf.NodeName,,SelectionDetailRecords.Ref.GetObject());
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
procedure RefreshNodeObjects()
	UniversalO.Clear();
	if Object.ObjectSelector = "" then
		return;
	endif;	

	Query = New Query;
	Query.Text = 
		"SELECT
		|	"""" AS ExternalId,
		|	Object.Ref AS Ref
		|FROM
		|	" + Object.ObjectSelector + " AS Object";
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	UniversalO.Clear();
	While SelectionDetailRecords.Next() Do
		try
			if SelectionDetailRecords.Ref.IsFolder then
				continue;
			endif;
		except
		endtry;

		row = UniversalO.Add();
		row.Ref = SelectionDetailRecords.Ref;
		
	
		QueryExternals = New Query;
		QueryExternals.Text = 
			"SELECT TOP 1
			|	SabatexExchangeIds.objectRef AS objectRef
			|FROM
			|	InformationRegister.SabatexExchangeIds AS SabatexExchangeIds
			|WHERE
			|	SabatexExchangeIds.NodeName = &NodeName
			|	AND SabatexExchangeIds.ObjectType = &ObjectType
			|	AND SabatexExchangeIds.InternalObjectRef = &InternalObjectRef";
	
			QueryExternals.SetParameter("InternalObjectRef", SelectionDetailRecords.Ref.UUID() );
			QueryExternals.SetParameter("NodeName", Lower(Object.NodeObjectSelector));
			QueryExternals.SetParameter("ObjectType",SabatexExchange.GetNormalizedObjectType(Object.ObjectSelector));
	
			QueryExternalsResult = QueryExternals.Execute();
	
			ExternalsSelectionDetailRecords = QueryExternalsResult.Select();
	
			if ExternalsSelectionDetailRecords.Next() then
				row.ExternalId = ExternalsSelectionDetailRecords.objectRef;
			else
				 row.ExternalId = "";
			endif;
	EndDo;
	
endprocedure	


&AtServer
Procedure ObjectSelectorOnChangeAtServer()
	RefreshNodeObjects();
EndProcedure

&AtClient
Procedure ObjectSelectorOnChange(Item)
	ObjectSelectorOnChangeAtServer();
EndProcedure

&AtServer
Procedure NodeObjectsSelectorOnChangeAtServer(NodeName)
	conf = SabatexExchange.GetConfigByNodeName(NodeName);
	Object.ObjectSelector = "";
	Items.ObjectSelector.ChoiceList.Clear();
	for each obj in conf.Objects do
		if obj.Value.UseIdAttribute then
			Items.ObjectSelector.ChoiceList.Add(obj.Value.ObjectType);
		endif;
	enddo;
	RefreshNodeObjects();
EndProcedure

&AtClient
Procedure NodeObjectsSelectorOnChange(Item)
	NodeObjectsSelectorOnChangeAtServer(Object.NodeObjectSelector);
EndProcedure

&AtClient
Procedure UniversalOBeforeRowChange(Item, Cancel)
	obj = Items.UniversalO.CurrentData;
    obj.ExternalId = OpenFormModal("Обработка.SabatexExchangeManualControl.Форма.ObjectEditForm",new structure("ObjectRef,NodeName",obj.Ref,Object.NodeObjectSelector),ThisForm);
	Cancel=true; 
	Items.UniversalO.Refresh();

EndProcedure

&AtServer
Procedure MigrationForNodeAtServer()
	if Object.NodeObjectSelector = "" then
		return;
	endif;
	
	conf = SabatexExchange.GetConfigByNodeName(Object.NodeObjectSelector);
	for each obj in conf.Objects do
		if obj.Value.UseIdAttribute then
			Query = New Query;
			Query.Text = 
			"SELECT
			|	Object.Ref AS Ref,
			|	Object.SabatexExchangeId AS SabatexExchangeId
			|FROM
			|	" + obj.Value.ObjectType + " AS Object
			|WHERE
			|	Object.SabatexExchangeId <> &SabatexExchangeId";
			
			
			Query.SetParameter("SabatexExchangeId", SabatexExchange.GetEmptyUUID());
	
			QueryResult = Query.Execute();
	
			SelectionDetailRecords = QueryResult.Select();
	
			While SelectionDetailRecords.Next() Do
				SabatexExchange.RegisterExtrnalId(SelectionDetailRecords.Ref,Object.NodeObjectSelector,SelectionDetailRecords.SabatexExchangeId);
			EndDo;
		endif;
	enddo;

EndProcedure

&AtClient
Procedure MigrationForNode(Command)
	MigrationForNodeAtServer();
EndProcedure





