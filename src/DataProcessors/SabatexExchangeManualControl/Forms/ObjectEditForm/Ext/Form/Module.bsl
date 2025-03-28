
&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	ObjectId = Parameters.ObjectId;
	NodeName = Parameters.NodeName;
	ObjectType = Parameters.ObjectType;
	ObjectRef = SabatexExchange.GetObjectManager(ObjectType).GetRef(new uuid(ObjectId));
	Query = New Query;
	Query.Text = 
		"SELECT TOP 1
		|	SabatexExchangeIds.objectRef AS objectRef
		|FROM
		|	InformationRegister.SabatexExchangeIds AS SabatexExchangeIds
		|WHERE
		|	SabatexExchangeIds.NodeName = &NodeName
		|	AND SabatexExchangeIds.ObjectType = &ObjectType
		|	AND SabatexExchangeIds.InternalObjectRef = &InternalObjectRef";
	
	Query.SetParameter("InternalObjectRef", ObjectId);
	Query.SetParameter("NodeName", Lower(NodeName));
	Query.SetParameter("ObjectType", SabatexExchange.GetNormalizedObjectType(ObjectType));
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	if SelectionDetailRecords.Next() then
			SabatexExchangeId = SelectionDetailRecords.objectRef;
	Endif;
	
КонецПроцедуры

&НаСервере
procedure SaveНаСервере()
	SabatexExchange.RegisterExtrnalId(ObjectRef,NodeName,SabatexExchangeId);
endprocedure

&НаКлиенте
Процедура Save(Команда)
	SaveНаСервере();
	object = new Map;
	object["ObjectId"] = ObjectId;
	object["ObjectType"] = ObjectType;
	object["NodeName"] = NodeName;
	object["SabatexExchangeId"] = SabatexExchangeId; 
	Notify("SabatexExchangeUpdateSabatexExchangeIds",object);
	Close();
КонецПроцедуры

&НаСервереБезКонтекста
function CleanValueAtServer(objectRef)
	obj = objectRef.GetObject(); 
	try 
		obj.SabatexExchangeId = SabatexExchange.GetEmptyUUID();
		obj.write();
		return undefined;
	except
		return ErrorDescription();
	endtry;
endfunction

&AtClient
Procedure CleanValue(Command)
	r = Вопрос("Ви впевнені що хочете скинути привязку даного елемента?", РежимДиалогаВопрос.ДаНет, 0, КодВозвратаДиалога.Да, Параметры.ObjectRef);	
	if r =  КодВозвратаДиалога.Да then
		CleanValueAtServer(Параметры.ObjectRef);
	endif;
	
	Close();
EndProcedure

&AtClient
Procedure CheckUUID(Command)
		
EndProcedure
