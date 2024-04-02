// Copyright (c) 2021-2024 by Serhiy Lakas
// https://sabatex.github.io

#region ExchangeConfig
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

// отримати конфігурацію для обміну даними
//  - destinationNode список налаштувань для віддаленого вузла обміну
function GetConfig(destinationNode)
	config = new structure;
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
	config.Insert("ObjectKey",destinationNode.ObjectKey);
	config.Insert("InternalNodeCode",destinationNode.InternalNodeCode);
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
	config.Insert("isUpdated",false);
	config.Insert("source",new Map);
	config.Insert("objectConf");
    config.Insert("Objects",new Structure);       // підтримуємі зовнішні типи
	config.Insert("ExternalObjects",new Structure);
	

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
			|	SabatexExchangeNodeConfig.ObjectKey AS ObjectKey,
			|	SabatexExchangeNodeConfig.InternalNodeCode AS InternalNodeCode
			|FROM
			|	InformationRegister.SabatexExchangeNodeConfig AS SabatexExchangeNodeConfig
			|WHERE
			|	SabatexExchangeNodeConfig.isActive = TRUE
			|	AND SabatexExchangeNodeConfig.NodeName = &NodeName";
		result = new Array;
		
		Query.Parameters.Insert("NodeName",nodeName);
		QueryResult = Query.Execute();
		SelectionDetailRecords = QueryResult.Select();
		While SelectionDetailRecords.Next() Do
			return GetConfig(SelectionDetailRecords);
		enddo;	
        return undefined;
endfunction	

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
			|	SabatexExchangeNodeConfig.ObjectKey AS ObjectKey,
			|	SabatexExchangeNodeConfig.InternalNodeCode AS InternalNodeCode
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

// Функция - Is enum
//
// Параметры:
//  objectType	 - string	 - тип обэкта "Перечисление.ВидНалога"
// 
// Возвращаемое значение:
//   -  true Enum type
//
//function StrIsEnum(value) export
//	return upper(value)="ПЕРЕЧИСЛЕНИЕ";	
//endfunction	
// Функция - Is catalog
//
// Параметры:
//  objectType	 - 	 - 
// 
// Возвращаемое значение:
//   - 
//
//function StrIsCatalog(objectType) export
//	return upper(objectType)="СПРАВОЧНИК";	
//endfunction	
	
// Функция - Is document
//
// Параметры:
//  objectType	 - 	 - 
// 
// Возвращаемое значение:
//   - 
//
//function StrIsDocument(objectType) export
//	return upper(objectType) ="ДОКУМЕНТ";	
//endfunction	

function ValidateObject(objectType)
	if SabatexExchange.IsCatalog(ObjectType) or SabatexExchange.IsDocument(ObjectType) or SabatexExchange.IsEnum(ObjectType) then
		return true;	
	endif;
	return false;
	
endfunction	


function GetNormalizedObjectType(objectType) export
	return StrReplace(objectType,".","_");
endfunction	


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
//  PostParser			 - string	 -  (необовязково) назва процедури яка буде викликана після парсингу обєкта
//  IdAttribute			 - string	 -  (необовязково) вказуэться якщо обэкт ідентифікується не через UUID обэкта а через атрибут 
//  LookObjectProc		 - string	 -  (необовязково) процендура пошуку обєкта по користувацьким алгоритмам (тільки нові) IdAttribute - обовязкове 
//  uninserted		 	 - boolean 	 -  (необовязково) Обэкт тільки синхронізується з базою 
//  transact             - boolean   -  (необовязково) Обэкт автоматично проводиься
//
// Возвращаемое значение:
//   structure - objectDescriptor
//
function CreateObjectDescriptor(Conf,ObjectType,val ExternalObjectType=undefined,PostParser=undefined,IdAttribute=undefined,LookObjectProc=undefined,uninserted=false,transact=false) export
	if ValidateObject(ObjectType) then
		normalizedObjectType = GetNormalizedObjectType(objectType);
		ExternalObjectType = ?(ExternalObjectType = undefined,ObjectType,ExternalObjectType);
		
		result = new Structure("Attributes,Tables",New Structure,New Structure);
		result.Insert("NormalizedObjectType",normalizedObjectType);
		result.Insert("ExternalObjectDescriptor",CreateExternalObjectDescriptor(conf,ExternalObjectType,,result));
		result.Insert("PostParser",PostParser);	
		result.Insert("ObjectType",ObjectType);
		result.Insert("IdAttribute",IdAttribute);
		result.Insert("UnInserted",UnInserted);
		result.Insert("Transact",transact);
		if LookObjectProc <> undefined and IdAttribute = undefined then
			raise "При встановлені LookObjectProc мусить бути вказвно IdAttribute";
		endif;	
		result.Insert("LookObjectProc",lookObjectProc);
		conf.Objects.Insert(normalizedObjectType,result);
		return result;
	endif;
	raise "Неправильний тип обьэкта - " + ObjectType;
endfunction

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
procedure AddAttributeProperty(objectConf,attrName,Ignore=false,default=undefined,destinationName=undefined,procName=undefined,postParser=undefined,ignoredIsMiss=false) export
	attr = new structure("ignore,default,destinationName,procName,postParser,ignoredIsMiss",Ignore,default,destinationName,procName,postParser,ignoredIsMiss);
	objectConf.Attributes.Insert(attrName,attr);
endprocedure

function AddTableProperty(objectConf,attrName,Ignore=true,destinationName=undefined,procName=undefined,postParser=undefined) export
	attr = new structure("ignore,destinationName,procName,postParser,attributes",Ignore,destinationName,procName,postParser,new structure);
	objectConf.Tables.Insert(attrName,attr);
	return attr;
endfunction


// Повертає назву метода пошуку елемента
function GetUserDefinedLoockObject(conf,objectType)
	return undefined;	
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
		raise "Імпорт обєктів типу - "+objectType + " не підтримується.";
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



#endregion

