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

&AtServerNoContext
function GetObjectData(ObjectSelector,NodeObjectSelector)
	result = new array;
	if ObjectSelector = "" then
		return result;
	endif;	
	Query = New Query;
		Query.Text = 
		"SELECT
		|   Object.Presentation AS Description,
		|	Object.Ref AS Ref
		|FROM
		|	" + ObjectSelector + " AS Object";
	
	items = Query.Execute().Unload();
	items.Columns.Add("Id",new TypeDescription("UUID"));
	for each item in items do
		item.Id = item.Ref.UUID();
	enddo;

	Query = New Query;
	Query.TempTablesManager = new TempTablesManager;
	Query.Text = 
		"SELECT
		|   *
		|	Поместить items
		|FROM
		|	&items AS items";

	Query.SetParameter("items",items);
	Query.Execute();
	
	QueryR = new Query;
	QueryR.TempTablesManager = Query.TempTablesManager;
	QueryR.Text = 
	"SELECT
	|	items.Id AS Id,
	|	items.Description AS  Description,	
	|	SabatexExchangeIds.objectRef AS ExternalId
	|FROM
	|	items AS items
	|		LEFT JOIN InformationRegister.SabatexExchangeIds AS SabatexExchangeIds
	|		ON items.Id = SabatexExchangeIds.InternalObjectRef  and SabatexExchangeIds.NodeName = &NodeName
    |               	AND SabatexExchangeIds.ObjectType = &ObjectType";
	QueryR.SetParameter("NodeName",NodeObjectSelector);
	QueryR.SetParameter("ObjectType",SabatexExchange.GetNormalizedObjectType(ObjectSelector));
	q = QueryR.Execute().Select();
	result = new array;
	while q.Next() do
		r = new structure("Id,Description,ExternalId");
		FillPropertyValues(r,q);
		result.Add(r);
	enddo;
	return result;
endfunction

&AtClient
procedure RefreshNodeObjects()
	UniversalO.Clear();
	if Object.ObjectSelector = "" then
		return;
	endif;	
	
	data = GetObjectData(Object.ObjectSelector,Object.NodeObjectSelector);
	
	for each item in data Do
		row = UniversalO.Add();
		FillPropertyValues(row,item);
	EndDo;
endprocedure	


&AtClient
Procedure ObjectSelectorOnChange(Item)
	RefreshNodeObjects();
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
EndProcedure

&AtClient
Procedure NodeObjectsSelectorOnChange(Item)
	NodeObjectsSelectorOnChangeAtServer(Object.NodeObjectSelector);
	RefreshNodeObjects();
EndProcedure

&AtClient
Procedure UniversalOBeforeRowChange(Item, Cancel)
	obj = Items.UniversalO.CurrentData;
    OpenForm("Обработка.SabatexExchangeManualControl.Форма.ObjectEditForm",new structure("ObjectType,objectId,NodeName",Object.ObjectSelector,obj.Id,Object.NodeObjectSelector),ThisForm);
	Cancel=true; 
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

&AtServerNoContext
function urlOnChangeAtServer(url)
	return SabatexExchange.Serialize(SabatexExchange.GetMessageHeaderFromUrl(url));
Endfunction



&AtClient
Procedure ConvertFromUrlToMessageHeader(Command)
	objectId = urlOnChangeAtServer(urlId); 
 EndProcedure

&AtServerNoContext
function ConvertFromObjectIdToUrlAtServer(objectId)
	messageHeader = SabatexExchange.Deserialize(objectId);
	return SabatexExchange.GetUrlFromMessageHeader(messageHeader);
EndFunction

&AtClient
Procedure ConvertFromObjectIdToUrl(Command)
	urlId = ConvertFromObjectIdToUrlAtServer(objectId);
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	if EventName = "SabatexExchangeUpdateSabatexExchangeIds" then
		//ObjectId,objectType,NodeName,SabatexExchangeId
		if Parameter["NodeName"] = Object.NodeObjectSelector then
			if Parameter["ObjectType"] = Object.ObjectSelector then
				r = UniversalO.FindRows(new structure("Id",Parameter["ObjectId"]));
				for each row in r do
					row.ExternalId = Parameter["SabatexExchangeId"]; 
				enddo;	
			endif;
		endif;
	endif;	
EndProcedure


