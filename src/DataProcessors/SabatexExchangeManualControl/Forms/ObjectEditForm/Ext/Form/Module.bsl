
&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	ObjectRef = Параметры.ObjectRef;
	NodeName = Parameters.NodeName;
	
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
	
	Query.SetParameter("InternalObjectRef", Параметры.ObjectRef.UUID());
	Query.SetParameter("NodeName", Lower(NodeName));
	Query.SetParameter("ObjectType", SabatexExchangeConfig.GetNormalizedObjectType(Параметры.ObjectRef.Metadata().FullName()));
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	if SelectionDetailRecords.Next() then
			SabatexExchangeId = SelectionDetailRecords.objectRef;
	Endif;
	
КонецПроцедуры

&НаСервере
procedure SaveНаСервере()
	SabatexExchangeExternalObjects.RegisterObject(ObjectRef,NodeName,SabatexExchangeId);
endprocedure

&НаКлиенте
Процедура Save(Команда)
	SaveНаСервере();
	
	Close(SabatexExchangeId);
КонецПроцедуры

&НаСервереБезКонтекста
function CleanValueAtServer(objectRef)
	obj = objectRef.GetObject(); 
	try 
		obj.SabatexExchangeId = Sabatex.GetEmptyUUID();
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
