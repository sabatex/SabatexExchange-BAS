// Copyright (c) 2021-2024 by Serhiy Lakas
// https://sabatex.github.io





#region CheckObgectType
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

function IsChartOfAccounts(objectType) export
	return Sabatex.StringStartWith(upper(objectType),Upper("ПланСчетов"));	
endfunction

function IsChartOfCharacteristicTypes(objectType) export
	return Sabatex.StringStartWith(upper(objectType),Upper("ПланВидовХарактеристик"));	
endfunction

function IsExchangePlan(objectType) export
	return Sabatex.StringStartWith(upper(objectType),Upper("ПланОбмена"));
endfunction

function IsInformationRegister(objectType) export
	return Sabatex.StringStartWith(upper(objectType),Upper("РегистрСведений"));
endfunction
function IsStructure(objectType) export
	return Sabatex.StringStartWith(upper(objectType),Upper("Structure"));
endfunction


function checkComplexType(conf,complexValue,objectId,objectType) export
	try
		objectId = complexValue.Get("#value");
		complexType = complexValue.Get("#type");
		pos = Найти(complexType,".");
		//subType = Сред(complexType,1,pos);
		typeName = Сред(complexType,pos+1);
		if StrStartsWith(complexType,"jcfg:CatalogRef") then
			objectType = SabatexExchangeConfig.GetInternalObjectType(conf,"справочник."+lower(typeName));
			return true;
		elsif StrStartsWith(complexType,"jcfg:DocumentRef") then
			objectType = SabatexExchangeConfig.GetInternalObjectType(conf,"документ."+lower(typeName));
			return  true;
		elsif StrStartsWith(complexType,"jcfg:EnumRef") then	
			objectType = SabatexExchangeConfig.GetInternalObjectType(conf,"перечисление."+lower(typeName));
			return  true;  
		elsif StrStartsWith(complexType,"jcfg:ChartOfCharacteristicTypesRef.") then	
			objectType = SabatexExchangeConfig.GetInternalObjectType(conf,"ПланВидовХарактеристик."+lower(typeName));
			return  true;
 		elsif StrStartsWith(complexType,"jxs:string") then	
			objectType = Type("string");
			return  true;
		elsif StrStartsWith(complexType,"jxs:boolean") then	
			objectType = Type("boolean");
			return  true;

		else
			 SabatexExchangeLogged.Error(conf,"Невідомий тип " + complexType);
			return false;
		endif;
	except
		SabatexExchangeLogged.Error(conf,"Перевірка комплексного типу " + complexType+ " " + ErrorDescription());
		return false;
	endtry;
endfunction	


#endregion

 #region CheckObjectState
 // methods for check object state
function IsUnserted(objectDescriptor,val recursiveLevel = 5) export
	if recursiveLevel <= 0 then
		raise "Перевищено кількість рекурсивниї звернень.";	
	endif;
	
	if objectDescriptor.Uninserted <> undefined then
		return  objectDescriptor.Uninserted;
	endif;
	
	if objectDescriptor.Owner = undefined then
		return true;
	endif;
	
	return IsUnserted(objectDescriptor.Owner,recursiveLevel-1);

endfunction

// Функция - Is deletion mark
//
// Параметры:
//  object	 - any object	 -  любий обєкт
// 
// Возвращаемое значение:
//   - boolean - 
//
function IsDeletionMark(object)
	try
		return object.DeletionMark;
	except
		return false;
	endtry;	
endfunction	



 #endregion

 #region Configuration
// Процедура - Configure auto query sending.
// By default, the system supports sending requests for unresolved objects.
// If set to unsupported, queries are handled separately for each object descriptor. 
//
// Параметры:
//  descriptor	 - structure - exchange or object descriptor
//  enable		 - boolean	 - default true
//
procedure ConfigureAutoQuerySending(descriptor,enable = undefined) export
	descriptor.Insert("AutoQuerySending",enable);	
endprocedure	

// Функция - Is enable query to destination
//
// Параметры:
//  conf			 - 	 - 
//  objectDescriptor - 	 - 
// 
// Возвращаемое значение:
//  boolean - true default value
//
function IsAutoQuerySending(objectDescriptor)
	if objectDescriptor = undefined then
		return true;
	endif;
	
	if  objectDescriptor.AutoQuerySending = undefined then
		if objectDescriptor.Owner = undefined then
			return true;
		else
			return IsAutoQuerySending(objectDescriptor.Owner);
		endif;
	else
		return objectDescriptor.AutoQuerySending;
	endif;	
endfunction	



 #endregion

#region GetObjects


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

// Функция - Отримати object manager ро символьному представленню
//
// Параметры:
//  objectType	 - string	 - Тип "Справочник.номенклатура"
// 
// Возвращаемое значение:
//  ObjectManager - Мененеджер обьєкта.
//  або генерується виключення при неправильному значенні 
//
function GetObjectManager(val objectType) export
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
	elsif IsChartOfAccounts(objectType) then
		try
			result = ChartsOfAccounts[GetNameObject(objectType)];
		except
			raise "Спроба отримати локальний тип " + objectType +". Встановіть відповідність внутрішнього та зовнішнього обєктів";  
		endtry;
	elsif IsChartOfCharacteristicTypes(objectType) then
		try
			result = ChartsOfCharacteristicTypes[GetNameObject(objectType)];
		except
			raise "Спроба отримати локальний тип " + objectType +". Встановіть відповідність внутрішнього та зовнішнього обєктів";  
		endtry; 
	elsif IsExchangePlan(objectType) then
		try
			result = ExchangePlans[GetNameObject(objectType)];
		except
			raise "Спроба отримати локальний тип " + objectType +". Встановіть відповідність внутрішнього та зовнішнього обєктів";  
		endtry;
	elsif IsInformationRegister(objectType) then
		try
			result = InformationRegisters[GetNameObject(objectType)];
		except
			raise "Спроба отримати локальний тип " + objectType +". Встановіть відповідність внутрішнього та зовнішнього обєктів";  
		endtry;
	else
		raise "Обробка даних типів не передбачена objectType=" + objectType;
	endif;
	return result;
endfunction

// Функция - Get enum value
//
// Параметры:
//  conf			 - 	 - 
//  objectType		 - 	 - 
//  objectId		 - 	 - 
//  objectDescriptor - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function GetEnumValue(conf,objectType,objectId,val objectDescriptor = undefined) export
	if objectDescriptor = undefined then
		if not conf.Objects.Property(SabatexExchangeConfig.GetNormalizedObjectType(objectType),objectDescriptor) then
			if conf.IsIdenticalConfiguration or conf.IsEnumAutoImport then
				objectDescriptor = SabatexExchangeConfig.CreateObjectDescriptor(conf,objectType)
			else
				raise "Імпорт типу "+ objectType + " не підтримується";
			endif;
		endif;
	endif;

	
	enumRelolveProc =  objectDescriptor.EnumResolverProc;
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

function GetIdAttributeType(objectDescriptor)
	if objectDescriptor.IdAttributeType = undefined then
		return objectDescriptor.Owner.IdAttributeType;
	endif;
	return objectDescriptor.IdAttributeType;
endfunction



// Функция - Get object ref by id
//
// Параметры:
//  objectManager	 - ObjectManager - 
//  objectDescriptor - structure - 
//  id				 - string,number - Id обєкта (UUID,string,integer)
// 
// Возвращаемое значение:
//   - посилання на обєкт або пусте посилання
//
function GetObjectRefById(objectManager,objectDescriptor,id) export
// пошук обэкта по UUID або атрибуту SabatexExchangeId
	if objectDescriptor.UseIdAttribute then
		if GetIdAttributeType(objectDescriptor) = Enums.SabatexExchangeIdAttributeType.UUID then
			return objectManager.FindByAttribute("SabatexExchangeId",new UUID(id)); 
		else
			return objectManager.FindByAttribute("SabatexExchangeId",id);
		endif;
	endif;
	
	lO = objectManager.GetRef(new UUID(id)).GetObject();
	if lO <> undefined then
		return lO.Ref
	endif;
	return objectManager.EmptyRef();
endfunction	

function GetQueryHeader(query)
	return SabatexJSON.Serialize(new Structure("query",query));
endfunction

function GetObjectHeader(type,id)
	return SabatexJSON.Serialize(new structure("type,id",type,id));
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
function GetObjectRef(conf,val objectType,val objectId,val objectDescriptor=undefined) export
	
	if typeof(objectId) = type("Map") then
		// комплексний тип
		complexObjectId = "";
		complexObjectType = "";
		if checkComplexType(conf,objectId,complexObjectId,complexObjectType) then
			return GetObjectRef(conf,complexObjectType,complexObjectId);
		endif;
		try
			objectManager = GetObjectManager(objectType);
			return objectManager.EmptyRef();
		except
			SabatexExchangeLogged.Error(conf,"Помилка отримання комплексного типу "+objectType + "  з objectId ="+objectId );
			return undefined;
		endtry;	
	endif;	
	
	if IsEnum(objectType) then
		return GetEnumValue(conf,objectType,objectId,objectDescriptor);
	endif;	
	
	if objectDescriptor = undefined then
		if not conf.Objects.Property(SabatexExchangeConfig.GetNormalizedObjectType(objectType),objectDescriptor) then
			if conf.IsIdenticalConfiguration then
				objectDescriptor = SabatexExchangeConfig.CreateObjectDescriptor(conf,objectType)
			else
				raise "Імпорт типу "+ objectType + " не підтримується";
			endif;
		endif;
	endif;	

	try
		objectManager = GetObjectManager(objectType);
	except	
		raise "Помилка отримання типу "+objectType + "  з objectId ="+objectId + " Error:" +ErrorDescription();
	endtry;
	
	if Sabatex.IsEmptyUUID(ObjectId) then
		return objectManager.EmptyRef();	
	endif;
	
	if objectDescriptor.Ignore then
		return objectManager.EmptyRef();
	endif;	
	
	result = GetObjectRefById(objectManager,objectDescriptor,objectId);

	if result= objectManager.EmptyRef() or  result.GetObject() = undefined then
		conf.success = false;
		if IsAutoQuerySending(objectDescriptor) then
			destinationFullName = objectDescriptor.ExternalObjectDescriptor.ObjectType;
		    AddQueryForExchange(conf,destinationFullName,objectId);
		else
			SabatexExchangeLogged.Information(conf,"Відправка запиту на отримання "+ objectType + " з Id=" + objectId +" заборонена.");	
		endif;
		
		return objectManager.EmptyRef();
	endif;
	return result;
endfunction	

#endregion


#region ExchangeObjects


// Процедура - Реэстрація повідомлення до відправлення
//
// Параметры:
//  nodeName		 - string 		- назва ноду  node name as SabatexExchangeNodeConfig.NodeName
//  messageHeader	 - structure	- заголовок повідомлення, udefined (default) - auto serialize id and type object
//  object			 - object 		- Object
//  serializeNow     - boolean      - серіалізувати зразу (для обєктів які помічені до видалення серіалізуються зразу) 
procedure RegisterMessageForNode(nodeName,messageHeader=undefined,object=undefined,serializeNow=false) export
	if messageHeader = undefined and object = undefined then
    	raise "Параметри messageHeader та object не можуть бути оночасно undefined!";
	endif;
	
	reg = InformationRegisters.sabatexExchangeObject.CreateRecordManager();
	reg.NodeName  = nodeName;
	reg.dateStamp = CurrentDate();
	
	if messageHeader = undefined then
		reg.MessageHeader =	SabatexJSON.Serialize(new structure("type,id",object.Ref.Метаданные().FullName(),XMLString(object.Ref.UUID())));	
	else
		reg.MessageHeader =	SabatexJSON.Serialize(messageHeader);	
	endif;
	
	if object <> undefined then
		if serializeNow or IsDeletionMark(object) then
	       reg.JSONText = SabatexJSON.Serialize(object);
	   endif;
	endif;
 	reg.Write(true);
endprocedure	

// Add query for exchange
// params:
// 		conf 		Configuration structure
//      objectType  Queried object type (50) as (Справочник.Контрагенты)
//      objectId    destination objectId or object code
procedure AddQueryForExchange(conf,objectType,objectId) export
	query = SabatexJSON.Serialize(new Structure("type,id",objectType,objectId));
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"SELECT TOP 1
		|	sabatexExchangeUnresolvedObjects.messageHeader AS messageHeader
		|FROM
		|	InformationRegister.sabatexExchangeUnresolvedObjects AS sabatexExchangeUnresolvedObjects
		|WHERE
		|	sabatexExchangeUnresolvedObjects.messageHeader = &query
		|	AND sabatexExchangeUnresolvedObjects.nodeName = &sender";
	
	Запрос.УстановитьПараметр("query", query);
	Запрос.УстановитьПараметр("sender", conf.NodeName);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	
	Пока ВыборкаДетальныеЗаписи.Следующий() Цикл
		SabatexExchangeLogged.Information(conf,"обєкт " + query+" в черзі чекає обробки.");
		// miss unresolved object
		return;
	КонецЦикла;
	RegisterQueryObjectForNode(conf,objectId,objectType);	
	SabatexExchangeLogged.Information(conf,"Відправлено запит на отримання "+ objectType + " з Id=" + objectId);
endprocedure	


// Register object in cashe for send to destination
// params:
// 	obj        - object  or reference  (Catalog or Documrnt)
//  nodeName   - нод в якому приймає участь даний обєкт  
procedure RegisterObjectForNode(conf,obj) export
	try
		RegisterMessageForNode(conf.NodeName,,obj);
	except
		SabatexExchangeLogged.Error(conf,"Помилка реэстрації обєкта для обміну");
	endtry;
endprocedure
procedure RegisterQueryForNode(conf,query) export
	try 
		RegisterMessageForNode(conf.NodeName,new Structure("query",query));
	except
		SabatexExchangeLogged.Error(conf,"Помилка реэстрації запиту обєкта.");
	endtry;
	
endprocedure	

procedure RegisterQueryObjectForNode(conf,objectId,objectType) export
	try
		RegisterQueryForNode(conf,New Structure("id,type",Lower(XMLString(objectId)),Lower(objectType)));
	except
		SabatexExchangeLogged.Error(conf,"Помилка реэстрації запиту обєкта.");
	endtry;
endprocedure	

procedure RegisterQueryObjectsForNode(conf,ObjectTypes,day) export
	for each objectType in StrSplit(ObjectTypes,",") do
		query = New Structure("type,day",Lower(objectType),Lower(Format(day,"DF=yyyyMMdd")));
		RegisterQueryForNode(conf,query);
	enddo;	
endprocedure

// Delete object from cashe
// params:
//	destinationId - 
//  dateStamp     - 
procedure DeleteObjectForExchange(messageHeader,destinationNodeName)
	reg = InformationRegisters.sabatexExchangeObject.CreateRecordManager();
	reg.MessageHeader = messageHeader;
	reg.NodeName = destinationNodeName;
	reg.Delete();
endprocedure	

// Процедура - Add unresolved object
//
// Параметры:
//  conf		 - struct    - 
//  item		 - map	     - 
//  newObject	 - boolean	 - 
//
procedure AddUnresolvedObject(conf,item,newObject = true) 
	reg = InformationRegisters.sabatexExchangeUnresolvedObjects.CreateRecordManager();
	//reg.sender = new UUID(item["sender"]);
	reg.MessageHeader = item["messageHeader"];

	reg.dateStamp = CurrentDate();
	reg.serverDateStamp= XMLValue(Type("Date"),item["senderDateStamp"]);
	reg.senderDateStamp =XMLValue(Type("Date"),item["dateStamp"]);
	reg.objectAsText = item["message"];
	reg.NodeName = conf.NodeName;
	reg.Log = ?(newObject,"",conf.Log);
	reg.Write();
endprocedure

// завантаження обєктів в систему
// conf - конфігурація
procedure ReciveObjects(conf)
		// read incoming objects
		if conf.TakeOneMessageAtATime then
			counter = conf.take;
		else
			counter =1;
		endif;
		
		while counter > 0 do
			counter = counter -1;
			
			incoming = SabatexExchangeWebApi.GetObjectsExchange(conf);
			for each item in incoming do
				BeginTransaction();
				try
					AddUnresolvedObject(conf,item);
					SabatexExchangeWebApi.DeleteExchangeObject(conf,item["id"]);
					CommitTransaction();
				except
					RollbackTransaction();
					SabatexExchangeLogged.Error(conf,"Do not load message Error Message: " + ОписаниеОшибки());
				endtry;
			enddo;
		enddo;
endprocedure
procedure PostObjects(conf)
	// post queries
	Query = Новый Запрос;
	Query.Текст = 
		"SELECT TOP " + XMLString(conf.take) + "
		|	sabatexExchangeObject.dateStamp AS dateStamp,
		|	sabatexExchangeObject.MessageHeader AS MessageHeader,
		|	sabatexExchangeObject.JSONText AS JSONText
		|FROM
		|	InformationRegister.sabatexExchangeObject AS sabatexExchangeObject
		|WHERE
		|	sabatexExchangeObject.NodeName = &nodeName
		|
		|ORDER BY
		|	dateStamp";
	
	Query.SetParameter("nodeName",conf.nodeName);
	РезультатЗапроса = Query.Выполнить();
	
	items = РезультатЗапроса.Выбрать();
	
	while items.Next() do
		try
			if TrimAll(items.JSONText) = "" then
				// серыалізація обєкта під час відправлення
				messageHeader = SabatexJSON.Deserialize(items.MessageHeader);
				message = undefined;
				if messageHeader["query"] = undefined then
					objectType = messageHeader["type"]; 
					objectId = messageHeader["id"];
					objectManager = GetObjectManager(objectType);	
					object	= objectManager.GetRef(new UUID(objectId)).GetObject();
					if object <> undefined then
						message =SabatexJSON.Serialize(object);
					endif;
				endif;
			else
				message =items.JSONText;
			endif;
			
			SabatexExchangeWebApi.POSTExchangeMessage(conf,items.MessageHeader,items.dateStamp,message);
			
			DeleteObjectForExchange(items.MessageHeader,conf.nodeName);
		except
			SabatexExchangeLogged.Error(conf,ErrorDescription());	
		endtry;
	enddo;
endprocedure	
#endregion

#region Actions
procedure BeforeSend(conf)
	if conf.userDefinedModule <> "" then
		try
			Execute(conf.userDefinedModule+".BeforeSend(conf)");
		except
			SabatexExchangeLogged.Information(conf,"Не встановлено обробник користувача BeforeSend(conf)");
		endtry;	
	endif;	
	
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
	    activeDestinationNodes = SabatexExchangeConfig.GetActiveDestinationNodes();
	except	
		resultMessage = "Помилка зчитування налаштувань обміну:"+ОписаниеОшибки();
		SabatexExchangeLogged.SystemLogError(resultMessage);
		return resultMessage;
	endtry;
		
	for each nodeName in activeDestinationNodes do
		start = CurrentDate();
		try
			conf = SabatexExchangeConfig.GetConfigByNodeName(nodeName);
		except	
			resultMessage = "Помилка зчитування налаштувань обміну:"+ОписаниеОшибки();
			SabatexExchangeLogged.SystemLogError(resultMessage);
			continue;
		endtry;

		skip = false;
		if exchangeMode =  conf.ExchangeMode then
			try
				// read  input objects
				ReciveObjects(conf);
				
				// Аналіз поступивших обєктів
				SabatexExchangeObjectAnalizer.AnalizeUnresolvedObjects(conf);
				
                BeforeSend(conf);
				
				// Відправка на сервер
				if conf.Send then
					PostObjects(conf);
				endif;	
			except
				message = string(conf.nodeName) + " - Програмна помилка -" + ErrorDescription();
				SabatexExchangeLogged.ErrorJournaled(conf,message);
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



