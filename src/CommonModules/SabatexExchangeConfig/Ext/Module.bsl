// Copyright (c) 2021-2024 by Serhiy Lakas
// https://sabatex.github.io

// Функция - Get node config
// 
// Возвращаемое значение:
//   - 
//
function GetHostConfig() export
	reg = InformationRegisters.SabatexExchangeConfig.Get(new structure("Key","HostConfig"));
	rootNode =  SabatexJSON.Deserialize(Sabatex.ValueOrDefault(reg.Value,"{}")); 
	result = new structure;
	result.Insert("clientId",Sabatex.ValueOrDefault(rootNode["clientId"],""));
	result.Insert("https",Sabatex.ValueOrDefault(rootNode["https"],true));
	result.Insert("Host",Sabatex.ValueOrDefault(rootNode["Host"],"sabatex.francecentral.cloudapp.azure.com"));
	result.Insert("Port",Sabatex.ValueOrDefault(rootNode["Port"],443));
	result.Insert("password",Sabatex.ValueOrDefault(rootNode["password"],""));
	return result;
endfunction
procedure SetHostConfig(hostConfig) export
	reg = InformationRegisters.SabatexExchangeConfig.CreateRecordManager();
	reg.Key = "HostConfig";
	reg.Value  = SabatexJSON.Serialize(hostConfig);;
	reg.Write(true);
endprocedure

//  Get config for destination node
//
// Параметры:
//  destinationNode	 - string	 - Node name
// 
// Возвращаемое значение:
//  structure - Config for Node
//
function GetConfig(destinationNode)
	config = new structure("Owner",undefined);
	config.Insert("nodeConfig",GetHostConfig());
	config.Insert("accessToken",GetAccessToken());
	config.Insert("nodeName",destinationNode.nodeName);
	config.Insert("destinationId",new UUID(destinationNode.destinationId));
	config.Insert("Take",destinationNode.Take);
	config.Insert("LogLevel",destinationNode.LogLevel);
	config.Insert("updateCatalogs",destinationNode.updateCatalogs);
	config.Insert("userDefinedModule",destinationNode.userDefinedModule);		
	config.Insert("IsQueryEnable",destinationNode.IsQueryEnable);
	config.Insert("ExchangeMode",destinationNode.ExchangeMode); 
	config.Insert("Send",Sabatex.ValueOrDefault(destinationNode.Send,false));
	config.Insert("Parse",Sabatex.ValueOrDefault(destinationNode.Parse,false));
	config.Insert("TakeOneMessageAtATime",Sabatex.ValueOrDefault(destinationNode.TakeOneMessageAtATime,false));
	config.Insert("UpdateTransacted",Sabatex.ValueOrDefault(destinationNode.UpdateTransacted,0));
	#region DefaultExchangeConfiguration
	SabatexExchange.ConfigureAutoQuerySending(config);
	
	config.Insert("IsIdenticalConfiguration",false);
	config.Insert("WriteUnresolved",false);
	config.Insert("Transact",false); 
	config.Insert("IsEnumAutoImport",false);
	// ignore missed property in incomming message
	config.Insert("ignoreMissedObject",false);
	//  Оновлювати уже існуючі обєкти
	config.Insert("IsUpdated",false);
	// заборона додавати нові обєкти
	config.Insert("UnInserted",false);
	//number - limit hours for update transacted document
	//config.Insert("UpdateTransacted",undefined); 

	
	config.Insert("senderDateStamp",undefined);

	
	#endregion
	config.Insert("IdAttributeType",Enums.SabatexExchangeIdAttributeType.UUID);
	


	config.Insert("Log","");
	
	// таблиця обєктів для запиту
	table = new ValueTable;
	table.Columns.Add("objectType");
	table.Columns.Add("objectId");
	config.Insert("queryList",table);
	
	config.Insert("objectId","");
	config.Insert("objectType","");
	config.Insert("objectDescriptor");
	config.Insert("success",true);
	config.Insert("source",new Map);
	config.Insert("objectConf");
    config.Insert("Objects",new Structure);       // підтримуємі зовнішні типи
	config.Insert("ExternalObjects",new Structure);
	config.Insert("LevelLive",0);
	

	if config.userDefinedModule <> "" then
		Execute(config.userDefinedModule+".Initialize(config)");
	endif;	
	
	return config;
endfunction
// Функция - Get config by node name
//
// Параметры:
//  nodeName - string	 - Назва нода в системі
// 
// Возвращаемое значение:
//   structure - Конфігурація нода або undefined 
//
function GetConfigByNodeName(nodeName) export
		Query = new Query;
		Query.Text = 
			"SELECT TOP 1
			|	SabatexExchangeNodeConfig.NodeName AS NodeName,
			|	SabatexExchangeNodeConfig.destinationId AS destinationId,
			|	SabatexExchangeNodeConfig.isActive AS isActive,
			|	SabatexExchangeNodeConfig.Take AS Take,
			|	SabatexExchangeNodeConfig.LogLevel AS LogLevel,
			|	SabatexExchangeNodeConfig.updateCatalogs AS updateCatalogs,
			|	SabatexExchangeNodeConfig.userDefinedModule AS userDefinedModule,
			|	SabatexExchangeNodeConfig.IsQueryEnable AS IsQueryEnable,
			|	SabatexExchangeNodeConfig.ExchangeMode AS ExchangeMode,
			|	SabatexExchangeNodeConfig.Send AS Send,
			|	SabatexExchangeNodeConfig.Parse AS Parse,
			|	SabatexExchangeNodeConfig.TakeOneMessageAtATime AS TakeOneMessageAtATime,
			|	SabatexExchangeNodeConfig.UpdateTransacted AS UpdateTransacted
			|FROM
			|	InformationRegister.SabatexExchangeNodeConfig AS SabatexExchangeNodeConfig
			|WHERE
			|	SabatexExchangeNodeConfig.isActive = TRUE
			|	AND SabatexExchangeNodeConfig.NodeName = &NodeName";
		result = new Array;
		
		Query.Parameters.Insert("NodeName",nodeName);
		QueryResult = Query.Execute();
		SelectionDetailRecords = QueryResult.Select();
		if SelectionDetailRecords.Next() then
			return GetConfig(SelectionDetailRecords);
		endif;	
        return undefined;
endfunction	


// Функция - Get destination nodes
// 
// Возвращаемое значение:
// array node config  -  масив конфігурацій нодів
//
function GetDestinationNodes() export
		Query = new Query;
		Query.Text = 
			"SELECT
			|	SabatexExchangeNodeConfig.NodeName AS NodeName,
			|	SabatexExchangeNodeConfig.destinationId AS destinationId,
			|	SabatexExchangeNodeConfig.isActive AS isActive,
			|	SabatexExchangeNodeConfig.Take AS Take,
			|	SabatexExchangeNodeConfig.LogLevel AS LogLevel,
			|	SabatexExchangeNodeConfig.updateCatalogs AS updateCatalogs,
			|	SabatexExchangeNodeConfig.userDefinedModule AS userDefinedModule,
			|	SabatexExchangeNodeConfig.IsQueryEnable AS IsQueryEnable,
			|	SabatexExchangeNodeConfig.ExchangeMode AS ExchangeMode,
			|	SabatexExchangeNodeConfig.Send AS Send,
			|	SabatexExchangeNodeConfig.Parse AS Parse,
			|	SabatexExchangeNodeConfig.TakeOneMessageAtATime AS TakeOneMessageAtATime,
			|	SabatexExchangeNodeConfig.UpdateTransacted AS UpdateTransacted
			|FROM
			|	InformationRegister.SabatexExchangeNodeConfig AS SabatexExchangeNodeConfig
			|WHERE
			|	SabatexExchangeNodeConfig.isActive = TRUE";
		result = new Array;
			
		QueryResult = Query.Execute();
		SelectionDetailRecords = QueryResult.Select();
		While SelectionDetailRecords.Next() Do
			result.Add(GetConfig(SelectionDetailRecords));
		enddo;	
		return result;	
endfunction

function GetObjectDescription(objectType)
	pos = Найти(objectType,".");
	if pos = -1 then
		raise "Задано неправильний тип objectType=" + objectType;
	endif;
	result = new Structure;
	result.Insert("Type",Mid(objectType,1,pos-1));
	result.Insert("Name",Mid(objectType,pos+1));
	return result;
endfunction


// Функция - Validate object
//
// Параметры:
//  objectType	 - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function ValidateObject(objectType)
	if SabatexExchange.IsCatalog(ObjectType)
		or SabatexExchange.IsDocument(ObjectType)
		or SabatexExchange.IsEnum(ObjectType)
		or SabatexExchange.IsChartOfAccounts(objectType)
		or SabatexExchange.IsChartOfCharacteristicTypes(objectType)
		or SabatexExchange.IsExchangePlan(objectType)
		or SabatexExchange.IsInformationRegister(objectType)
		or SabatexExchange.IsStructure(objectType)  then
		return true;	
	endif;
	return false;
	
endfunction	


function GetNormalizedObjectType(objectType) export
	return StrReplace(lower(objectType),".","_");
endfunction	

#region ObjectConfigure
// Функция - Create external object descriptor
//
// Параметры:
//  conf					 - 	 - 
//  externalObjectType		 - 	 - 
//  parserProc				 - 	 - 
//  internalObjectDescriptor - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function CreateExternalObjectDescriptor(conf,externalObjectType,parserProc=undefined,internalObjectDescriptor=undefined) export
	var externalObject;
	if ValidateObject(externalObjectType) then
		normalizedObjectType = GetNormalizedObjectType(externalObjectType);
		if conf.ExternalObjects.Property(normalizedObjectType,externalObject) then
			if parserProc<>undefined then
				raise "Для обьєкта " + externalObjectType + " уже задано парсер"; 
			endif;
			if internalObjectDescriptor<>undefined then
				raise "Для обьєкта " + externalObjectType + " уже задано внутріщній обєкт"; 
			endif;
			
			return externalObject;
		endif;	
		
		externalObject = new Structure;
		externalObject.Insert("Parser",parserProc);
		externalObject.Insert("ObjectType",externalObjectType);
		externalObject.Insert("NormalizedObjectType",normalizedObjectType);
		externalObject.Insert("InternalObject",internalObjectDescriptor);
		conf.ExternalObjects.Insert(normalizedObjectType,externalObject);
		return externalObject;
	endif;
	raise "Неправильний тип обьэкта - " + externalObjectType;
endfunction	
// Функция - Configured object descriptor
//
// Параметры:
//  Conf				 - 	 - 
//  ObjectType			 - string	 -  тип обьэкта типу "Справочник.Номенклатура"
//  ExternalObjectType	 - string	 -  (необовязково якщо одинакові) тип обэкта в іншвй базі
//  ignore      		 - boolean	 -  (необовязково) ignore this object 
// Возвращаемое значение:
//   structure - objectDescriptor
//
function CreateObjectDescriptor(Conf,ObjectType,val ExternalObjectType=undefined,val ignore=false) export
	if not ValidateObject(ObjectType) then
		raise "Неправильний тип обьэкта - " + ObjectType;
	endif;
	
	normalizedObjectType = GetNormalizedObjectType(objectType);
	ExternalObjectType = ?(ExternalObjectType = undefined,ObjectType,ExternalObjectType);
		
	result = new Structure("Attributes,Tables",New Structure,New Structure);
	result.Insert("Owner",conf);
	result.Insert("NormalizedObjectType",normalizedObjectType);
	result.Insert("ExternalObjectDescriptor",CreateExternalObjectDescriptor(conf,ExternalObjectType,,result));
	result.Insert("ObjectType",ObjectType);
	result.Insert("UseIdAttribute",false); 
	result.Insert("UnInserted",false);   // true - object support only update
	result.Insert("Transact",undefined); // true - tansact document
	result.Insert("UpdateTransacted",undefined); //true - update transacted document
	
	result.Insert("ignoreMissedObject",undefined); // ignore missed property in incomming message
	result.Insert("writeUnresolved",undefined); // take global conf.writeUnresolved
	result.Insert("IsUpdated", undefined);
	result.Insert("OnAfterSave",undefined);
	result.Insert("OnBeforeSave",undefined);
	result.Insert("EnumResolverProc",undefined);
	result.Insert("Ignore",ignore); // ignore this object
	result.Insert("LookObjectProc",undefined);
    result.Insert("IdAttributeType",undefined);
    SabatexExchange.ConfigureAutoQuerySending(result);
	conf.Objects.Insert(normalizedObjectType,result);
	return result;
endfunction
// Процедура - Create enum object descriptor
//
// Параметры:
//  Conf			 - 	 - 
//  EnumName		 - 	 - 
//  EnumRelolverProc - 	 - 
//
procedure CreateEnumObjectDescriptor(Conf,EnumName,EnumRelolverProc=undefined) export
	for each value in StrSplit(EnumName,",") do
		objectDescriptor = SabatexExchangeConfig.CreateObjectDescriptor(Conf,"Перечисление."+value);
		objectDescriptor.EnumResolverProc=EnumRelolverProc;
	enddo;	
endprocedure	



// Процедура - Add attribute property
//
// Параметры:
//  objectConf		 - 	 - 
//  attrName		 - string	 - 
//  Ignore			 - boolean	 - 
//  default			 - object	 - 
//  destinationName	 - string	 - 
//  procName		 - string	 - 
//  postParser		 - string	 - 
//  ignoredIsMiss	 - boolean	 - 
//
function AddAttributeProperty(objectConf,attrName,Ignore=false,default=undefined,destinationName=undefined,procName=undefined,postParser=undefined) export
	attr = new structure("ignore,default,destinationName,procName,postParser",Ignore,default,destinationName,procName,postParser);
	
	attr.Insert("Owner",objectConf);
	attr.Insert("ignoreMissedObject",undefined);

	objectConf.Attributes.Insert(attrName,attr);
	return attr;
endfunction


// Функция - Add table property
//
// Параметры:
//  objectConf		 - 	 - 
//  attrName		 - 	 - 
//  Ignore			 - 	 - 
//  destinationName	 - 	 - 
//  procName		 - 	 - 
//  postParser		 - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function AddTableProperty(objectConf,attrName,Ignore=true,destinationName=undefined,procName=undefined,postParser=undefined) export
	attr = new structure("ignore,destinationName,procName,postParser,attributes",Ignore,destinationName,procName,postParser,new structure);
	objectConf.Tables.Insert(attrName,attr);
	attr.Insert("Owner",objectConf);
	attr.Insert("ignoreMissedObject",undefined);
	return attr;
endfunction

// Процедура - Configure update startegy
//
// Параметры:
//  objectDescriptor - structure - 
//  update			 - boolean	 - (необовязково) true/false Оновлювати обэкт. (Обєкт може мінятись клієнтом і мати інші властивості в порівнянні destination)
//
procedure ConfigureUpdateStartegy(objectDescriptor,IsUpdated) export
	objectDescriptor.IsUpdated=IsUpdated	
endprocedure	

// Процедура - Configure store unresolved startegy
//
// Параметры:
//  objectDescriptor - 	 - 
//  writeUnresolved	 - 	 - 
//
procedure ConfigureStoreUnresolvedStartegy(objectDescriptor,writeUnresolved) export
	objectDescriptor.writeUnresolved = writeUnresolved;
endprocedure	

// Процедура - Configure inserting object
//
// Параметры:
//  objectDescriptor - 	 - 
//  uninserted		 - 	 - 
//
procedure ConfigureInsertingStartegy(objectDescriptor,uninserted) export
	objectDescriptor.uninserted = uninserted;
endprocedure	

// Процедура - Configure missing data startegy
//
// Параметры:
//  objectDescriptor	 - structure - globalConf,objectDescriptor,FieldDescriptor,TableDescriptor,TableDescriptor 
//  ignoreMissedObject	 - 	 - 
//
procedure ConfigureMissingDataStartegy(objectDescriptor,ignoreMissedObject) export
	objectDescriptor.ignoreMissedObject = ignoreMissedObject;
endprocedure	

// Процедура - Configure transact document startegy (default false)
//
// Параметры:
//  objectDescriptor - 	 - 
//  transact		 - boolean	 -   Обэкт автоматично проводиься   

procedure ConfigureTransactDocumentStartegy(objectDescriptor,transact,updateTransacted=undefined) export
	objectDescriptor.transact = transact;
	objectDescriptor.UpdateTransacted = updateTransacted; //true - update transacted document
endprocedure	


procedure ConfigureSearchObject(objectDescriptor,UseIdAttribute=false,LookObjectProc=undefined) export
	objectDescriptor.UseIdAttribute = UseIdAttribute;
	if LookObjectProc <> undefined and not UseIdAttribute then
		raise "При встановлені LookObjectProc мусить бути вказвно IdAttribute";
	endif;	
	objectDescriptor.LookObjectProc =lookObjectProc;
endprocedure


procedure ConfigureParserActions(conf,objectDescriptor,OnBeforeSave=false,OnAfterSave=undefined) export
	objectDescriptor.OnAfterSave = OnAfterSave;
	objectDescriptor.OnBeforeSave = OnBeforeSave;
endprocedure




// Процедура - Додати парсер зовнішнього обєкта
//
// Параметры:
//  conf				 - 	 - 
//  externalObjectType	 - string	 -  тип обьєкта (Справочник.Номенклатура)
//  parserProc			 - string	 -  назва проседури
//
// пример:
// ConfiguredUserDefinedObjectParser(conf,"Справочник.Номенклатура","ПарсерНоменклатури")
// приклад процедури
// procedure ПарсерНоменклатури(conf) export
// 		SabatexExchange.Error(conf,"Даний обробник ще не реалызовано." );
// endprocedure
procedure ConfiguredUserDefinedObjectParser(conf,externalObjectType,parserProc) export
	CreateExternalObjectDescriptor(conf,externalObjectType,parserProc);	
endprocedure	


// Процедура - Add attribute mapped
//
// Параметры:
//  objectDescriptor - 	 - 
//  attrName		 - 	 - 
//  destinationName	 - 	 - 
//  ignoredIsMiss	 - 	 - 
//
function AddAttributeMapped(objectDescriptor,attrName,destinationName) export
	return AddAttributeProperty(objectDescriptor,attrName,,,destinationName);	
endfunction


#endregion

// Повертає назву метода пошуку елемента
function GetUserDefinedLoockObject(conf,objectType)
	return undefined;	
endfunction

function IsAutoGenerateType(conf, val objectType)
	if conf.IsIdenticalConfiguration then
		return true;
	endif;
	if SabatexExchange.IsEnum(objectType) then
		if conf.IsEnumAutoImport then
			return true;
		endif;
	endif;
	return false;
endfunction


// Функция - Отримати внутрішній тип по зовнішньому
//
// Параметры:
//  conf					 - structure	 - 
//  objectType          	 - string	     - зовнішній тип обєкта, по замовчуванню поточний обробляемий тип обьєкта
// 
// Возвращаемое значение:
//   -  string - внутрішній тип обєкта
//
function GetInternalObjectType(conf, val objectType=undefined) export
	var result;
	if not conf.Objects.Property(?(objectType=undefined,conf.NormalizedObjectType,GetNormalizedObjectType(objectType)),result) then
		if IsAutoGenerateType(conf,objectType)  then
			ot= CreateObjectDescriptor(conf,?(objectType=undefined,conf.ObjectType,objectType));
			return ot.ObjectType;
		else
			raise "Імпорт обєктів типу - "+objectType + " не підтримується."; 
		endif;	
	endif;	
	return result.ObjectType;
endfunction




function GetAccessToken()
	reg =  InformationRegisters.SabatexExchangeConfig.Get(new structure("Key","AccessToken"));
	token =  SabatexJSON.Deserialize(Sabatex.ValueOrDefault(reg.Value,"{}"));
	if TypeOf(token) <> Type("Map") then
		token = new Map;
	endif;	
	result = new Structure;
	result.Insert("access_token",Sabatex.ValueOrDefault(token["access_token"],"undefined"));
	result.Insert("token_type",Sabatex.ValueOrDefault(token["token_type"],""));
	result.Insert("refresh_token",Sabatex.ValueOrDefault(token["refresh_token"],"undefined"));
	result.Insert("expires_in",Sabatex.ValueOrDefault(token["expires_in"],CurrentDate()));
	return result;
endfunction
// Процедура - Sabatex set access token
//
// Параметры:
//  conf		 - 	 - 
//  accessToken	 - 	 - 
//
procedure SetAccessToken(conf,accessToken) export
    expires_in = CurrentDate()+ Number(accessToken["expires_in"]);
    result = new Structure;
	result.Insert("access_token",Sabatex.ValueOrDefault(accessToken["access_token"],"undefined"));
	result.Insert("token_type",Sabatex.ValueOrDefault(accessToken["token_type"],""));
	result.Insert("refresh_token",Sabatex.ValueOrDefault(accessToken["refresh_token"],"undefined"));
	result.Insert("expires_in",Sabatex.ValueOrDefault(accessToken["expires_in"],CurrentDate()));
	reg = InformationRegisters.SabatexExchangeConfig.CreateRecordManager();
	reg.Key = "AccessToken";
	reg.Value  = SabatexJSON.Serialize(result);
	reg.Write(true);
	conf["accessToken"]=GetAccessToken();
endprocedure




