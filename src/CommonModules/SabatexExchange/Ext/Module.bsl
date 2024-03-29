// Copyright (c) 2021-2024 by Serhiy Lakas
// https://sabatex.github.io

#region GetObjects

// Функция - Is enum
//
// Параметры:
//  objectType	 - string	 - тип обэкта "Перечисление.ВидНалога"
// 
// Возвращаемое значение:
//   -  true Enum type
//
function IsEnum(objectType) export
	return Sabatex.StringStartWith(upper(objectType),"ПЕРЕЧИСЛЕНИЕ");	
endfunction	

// Функция - Is catalog
//
// Параметры:
//  objectType	 - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function IsCatalog(objectType) export
	return Sabatex.StringStartWith(upper(objectType),"СПРАВОЧНИК");	
endfunction	
	
// Функция - Is document
//
// Параметры:
//  objectType	 - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function IsDocument(objectType) export
	return Sabatex.StringStartWith(upper(objectType),"ДОКУМЕНТ");	
endfunction	

// Функция - Get name object
//
// Параметры:
//  objectType	 - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function GetNameObject(objectType) export
	pos = Найти(objectType,".");
	if pos = -1 then
		raise "Задано неправильний тип objectType=" + objectType;
	endif;	
	return Сред(objectType,pos+1);
endfunction	

function checkComplexType(conf,complexValue,objectId,objectType)
	try
		objectId = complexValue.Get("#value");
		complexType = complexValue.Get("#type");
		pos = Найти(complexType,".");
		subType = Сред(complexType,1,pos);
		typeName = Сред(complexType,pos+1);
		if subType = "jcfg:CatalogRef." then
			objectType = SabatexExchangeConfig.GetInternalObjectType(conf,"справочник."+lower(typeName));
			return true;
		elsif subType = "jcfg:DocumentRef." then
			objectType = SabatexExchangeConfig.GetInternalObjectType(conf,"документ."+lower(typeName));
			return  true;
		else
			 SabatexExchangeLogged.Error(conf,"Невідомий тип " + complexType);
			return false;
		endif;
	except
		return false;
	endtry;
endfunction	

// Функция - Get object manager
//
// Параметры:
//  conf		 - structure	 - 
//  objectType	 - string	 - 
//  success		 - boolean	 - 
// 
// Возвращаемое значение:
//  ObjectManager - Мененеджер обьєкта.
// або генерується виключення при неправильному значенні 
//
function GetObjectManager(conf,val objectType=undefined)
	if objectType = undefined then
		objectType = conf.ObjectDescriptor.ObjectType;
	endif;
	if IsDocument(objectType) then
		try
			result = Documents[GetNameObject(objectType)];
		except
			raise "Спроба отримати локальний тип " + objectType +". Встановіть відповідність внутрішнього та зовнішнього обєктів";  
		endtry;	
	elsif IsCatalog(objectType) then
		try
			result = Catalogs[GetNameObject(objectType)];
		except
			raise "Спроба отримати локальний тип " + objectType +". Встановіть відповідність внутрішнього та зовнішнього обєктів";  
		endtry;	
	else
		raise "Обробка даних типів не передбачена objectType=" + objectType;
	endif;
	return result;
endfunction

function GetEnumValue(conf,objectType,objectId,val objectDescriptor = undefined) export
	if objectDescriptor = undefined then
		if conf.Objects.Property(SabatexExchangeConfig.GetNormalizedObjectType(objectType))then
			raise "Імпорт не підтримується";
		endif;
	endif;
	
	
	enumRelolveProc =  objectDescriptor.PostParser;
	if enumRelolveProc = undefined then
		try
			x= Enums[GetNameObject(objectType)];
		except
			SabatexExchangeLogged.Error(conf,"Помилка отримання перерахування конфігурації - "+objectType);
			return Enums.AllRefsType();
		endtry;
		if objectId = "" then
			return Enums.AllRefsType();
		endif;	
		
		try
			return x[objectId];
		except
			SabatexExchangeLogged.Error(conf,"Помилка отримання зжначення - "+objectId+" - з перерахування конфігурації - "+objectType);
			return x.EmptyRef();
		endtry;
	else
		try
			result = undefined;
			Execute(conf.userDefinedModule+"."+enumRelolveProc+"(conf,objectId,result)");
			return result;
		except
		    SabatexExchangeLogged.Error(conf,"Помилка виклику метода користувача"+enumRelolveProc+" : " +ErrorDescription());
	   endtry;
	endif;	
endfunction

// Функция - Пошук обьєкта по Id
//
// Параметры:
//  conf			 - strucrure	 -
//  objectType		 - string	 - тип обєкта  "Справочник.Номенклатура"
//  objectId		 - string,Map	 - id обєкта (string UUID, for Enum Name), Map - комплексний тип
//  objectDescriptor - structure	 - описувач типа
// 
// Возвращаемое значение:
//  Ref      - посилання на обьєкт (знайдено)
//  EmptyRef - (передано дійсний тип та objectId = UUID("00000000-0000-0000-0000-000000000000") 
//
function GetObjectRef(conf,objectType,objectId,val objectDescriptor=undefined) export
	
	if typeof(objectId) = type("Map") then
		// комплексний тип
		complexObjectId = "";
		complexObjectType = "";
		if checkComplexType(conf,objectId,complexObjectId,complexObjectType) then
			return GetObjectRef(conf,complexObjectType,complexObjectId);
		endif;
		try
			objectManager = GetObjectManager(conf,objectType);
			return objectManager.EmptyRef();
		except
			SabatexExchangeLogged.Error(conf,"Помилка отримання комплексного типу "+objectType + "  з objectId ="+objectId );
			return undefined;
		endtry;	
	endif;	
	
	if objectDescriptor = undefined then
		if not conf.Objects.Property(SabatexExchangeConfig.GetNormalizedObjectType(objectType),objectDescriptor) then
			raise "Імпорт типу "+ objectType + " не підтримується";	
		endif;
	endif;	
	

	if IsEnum(objectType) then
		return GetEnumValue(conf,objectType,objectId,objectDescriptor);
	endif;	
	
	try
		objectManager = GetObjectManager(conf,objectType);
	except	
		raise "Помилка отримання типу "+objectType + "  з objectId ="+objectId + " Error:" +ErrorDescription();
	endtry;
	
	if Sabatex.IsEmptyUUID(ObjectId) then
		return objectManager.EmptyRef();	
	endif;
	
	if objectDescriptor.idAttribute = undefined then
		result = objectManager.GetRef(new UUID(objectId));
	else
		result = objectManager.FindByAttribute(objectDescriptor.idAttribute,new UUID(objectId));
	endif;	

	if result= objectManager.EmptyRef() or  result.GetObject() = undefined then
		destinationFullName = objectDescriptor.ExternalObjectDescriptor.ObjectType;
		
		conf.success = false;
		AddQueryForExchange(conf,destinationFullName,objectId);
		return objectManager.EmptyRef();
	endif;
	return result;
endfunction	

#endregion


#region ExchangeObjects
// Register object in cashe for send to destination
// params:
// 	obj        - object  or reference  (Catalog or Documrnt)
//  nodeName   - нод в якому приймає участь даний обєкт  
procedure RegisterObjectForNode(obj,nodeName) export
	reg = InformationRegisters.sabatexExchangeObject.CreateRecordManager();
   	objectRef	= obj.Ref;
	reg.ObjectId =objectRef.UUID(); 
    reg.ObjectType = objectRef.Метаданные().FullName();
	reg.NodeName  = nodeName;
	reg.dateStamp = CurrentDate();
	reg.Write(true);
endprocedure	
// Delete object from cashe
// params:
//	destinationId - 
//  dateStamp     - 
procedure DeleteObjectForExchange(objectId,objectType,destinationNodeName)
	reg = InformationRegisters.sabatexExchangeObject.CreateRecordManager();
	reg.ObjectId = objectId;
	reg.ObjectType = objectType;
	reg.NodeName = destinationNodeName;
	reg.Delete();
endprocedure	
// завантаження обєктів в систему
// conf - конфігурація
procedure ReciveObjects(conf)
		// read incoming objects 
		incoming = SabatexExchangeWebApi.GetObjectsExchange(conf);
		for each item in incoming do
			objectId = "";
			objectType = "";
			BeginTransaction();
			try
				SabatexExchangeObjectAnalizer.AddUnresolvedObject(conf,item);
				SabatexExchangeWebApi.DeleteExchangeObject(conf,item["id"]);
				CommitTransaction();
			except
				SabatexExchangeLogged.Error(conf,"Do not load objectId=" + objectId + ";objectType="+ objectType + " Error Message: " + ОписаниеОшибки());
				RollbackTransaction();
			endtry;
		enddo;
endprocedure
procedure PostObjects(conf)
	// post queries
	conf.queryList.GroupBy("objectType,objectId");
	for each query in conf.queryList do 
		SabatexExchangeWebApi.PostQueries(conf,query.objectId,query.objectType);
	enddo;	
	
	Query = Новый Запрос;
	Query.Текст = 
		"SELECT TOP 200
		|	sabatexExchangeObject.dateStamp AS dateStamp,
		|	sabatexExchangeObject.ObjectType AS ObjectType,
		|	sabatexExchangeObject.ObjectId AS ObjectId
		|FROM
		|	InformationRegister.sabatexExchangeObject AS sabatexExchangeObject
		|WHERE
		|	sabatexExchangeObject.NodeName = &nodeName";
	
	Query.SetParameter("nodeName",conf.nodeName);
	РезультатЗапроса = Query.Выполнить();
	
	items = РезультатЗапроса.Выбрать();
	
	while items.Next() do
		try
			objectType = items.ObjectType; 
			objectId = items.ObjectId;
			objectManager = GetObjectManager(conf,objectType);	
			object	= objectManager.GetRef(objectId).GetObject();
			if object <> undefined then
				objectJSON =SabatexJSON.Serialize(object);
				SabatexExchangeWebApi.POSTExchangeObject(conf,objectType,string(objectId),items.dateStamp,objectJSON);
			endif;
			DeleteObjectForExchange(objectId,objectType,conf.nodeName);
		except
			
		endtry;
	enddo;
endprocedure	
#endregion


#region queriedObject
// Перевірка доступності відповіді на запит
// - conf структура з параметрами
function IsQueryEnable(conf)
	result =false;
	if conf.Property("IsQueryEnable",result) then
		return result;
	endif;
	return false;
endfunction	

// Отримати підтипДокумента
function GetObjectTypeKind(conf,objectType)
	result = StrSplit(objectType,".",false);
	if result.Count() < 2 then
		return undefined;
	endif;
	return result[1];
endfunction	

// Отримати документ по UUID
function GetDocumentById(conf,objectName,objectId)
	if Sabatex.IsEmptyUUID(objectId) then
		return undefined;
	endif;	
	objRef = Documents[objectName].GetRef(new UUID(objectId));
	if objRef.GetObject() = undefined then
		SabatexExchangeLogged.Error(conf,"Помилка отримання обєкта документа "+objectName + " з ID="+objectId);
		return undefined;
	endif;
	return objRef;
endfunction

function GetCatalogById(conf,objectName,objectId)
	if Sabatex.IsEmptyUUID(objectId) then
		return undefined;
	endif;	

	objRef = Catalogs[objectName].GetRef(new UUID(objectId));
	if objRef.GetObject() = undefined then
		SabatexExchangeLogged.Error(conf,"Помилка отримання обєкта Довідника "+objectName + " з ID="+objectId);
		return undefined;
	endif;
	return objRef;
endfunction
// Add query for exchange
// params:
// 		conf 		Configuration structure
//      objectType  Queried object type (50) as (Справочник.Контрагенты)
//      objectId    destination objectId or object code
procedure AddQueryForExchange(conf,objectType,objectId) export
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"SELECT TOP 1
		|	sabatexExchangeUnresolvedObjects.objectId AS objectId
		|FROM
		|	InformationRegister.sabatexExchangeUnresolvedObjects AS sabatexExchangeUnresolvedObjects
		|WHERE
		|	sabatexExchangeUnresolvedObjects.objectId = &objectId
		|	AND sabatexExchangeUnresolvedObjects.sender = &sender
		|	AND sabatexExchangeUnresolvedObjects.objectType = &objectType";
	
	Запрос.УстановитьПараметр("objectId", objectId);
	Запрос.УстановитьПараметр("objectType", objectType);
	Запрос.УстановитьПараметр("sender", new UUID(conf.destinationId));
	
	РезультатЗапроса = Запрос.Выполнить();
	
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	
	Пока ВыборкаДетальныеЗаписи.Следующий() Цикл
		SabatexExchangeLogged.Information(conf,""+objectType + " з Id=" + objectId+" в черзі чекає обробки.");
		// miss unresolved object
		return;
	КонецЦикла;
	
	query = conf.queryList.Add();
	query.objectType = objectType;
	query.objectId = objectId;
	SabatexExchangeLogged.Information(conf,"Відправлено запит на отримання "+ objectType + " з Id=" + objectId);
endprocedure	

// Обробка запитів до системи
procedure DoQueriedObjects(conf)

	queries = SabatexExchangeWebApi.GetQueriedObjects(conf);
	
	for each item in queries do
		if IsQueryEnable(conf) then
			objectId = item["objectId"];
			objectType = Upper(item["objectType"]);
			object = undefined;
			if Sabatex.StringStartWith(objectType,upper("справочник")) then
				object = GetCatalogById(conf,GetObjectTypeKind(conf,objectType),objectId);
			elsif Sabatex.StringStartWith(objectType,upper("документ")) then
				object = GetDocumentById(conf,GetObjectTypeKind(conf,objectType),objectId);
			else
				// get extended query
				
				try
					Execute(conf.userDefinedModule+".QueryObject(conf,objectType,objectId,object)");
				except
					SabatexExchangeLogged.Error(conf,"Помилка виконання розширеного запиту до бази:"+ОписаниеОшибки() );
				endtry;
			endif;
			if object <> undefined then
				RegisterObjectForNode(object,conf.NodeName);		
			endif;
		endif;
		SabatexExchangeWebApi.DeleteQueriesObject(conf,item["id"]);
	enddo;	    
endprocedure	

#endregion


// Процедура - процесс обміну
//
// Параметры:
//  exchangeMode - enum	 - exchange take node by mode (auto/manual) 
// 
// Возвращаемое значение:
//  string - Result log 
//
function ExchangeProcess(exchangeMode) export
	resultMessage = "";
	try
	    destinationNodes = SabatexExchangeConfig.GetDestinationNodes();
	except	
		resultMessage = "Помилка зчитування налаштувань обміну:"+ОписаниеОшибки();
		SabatexExchangeLogged.SystemLogError(resultMessage);
		return resultMessage;
	endtry;
		
	for each conf in destinationNodes do
		start = CurrentDate();
		skip = false;
		if exchangeMode =  conf.ExchangeMode then
			try
				// ansver the query and set to queue
				DoQueriedObjects(conf);
				
				// read  input objects
				ReciveObjects(conf);
				
				// Аналіз поступивших обєктів
				SabatexExchangeObjectAnalizer.AnalizeUnresolvedObjects(conf);
				
				// Відправка на сервер
				PostObjects(conf);
			except
				message = string(conf.nodeConfig.clientId) + " - Програмна помилка -" + ErrorDescription();
				SabatexExchangeLogged.Error(conf,message,true);
				resultMessage = resultMessage  + message+ Chars.CR;
			endtry;
		else
			skip = true;	
		endif;	
		
		end = ТекущаяДата();
		if skip then
			message = "Обміну  з вузлом "+conf.nodeName + " - пропущено";
		else	
			message = "Тривалість обміну  з вузлом "+conf.nodeName + " - " + string(end - start)+ " сек.";
		endif;
		SabatexExchangeLogged.Note(conf,message,true);
		resultMessage = resultMessage  + message+ Chars.CR;
	enddo;
	return resultMessage;
endfunction



