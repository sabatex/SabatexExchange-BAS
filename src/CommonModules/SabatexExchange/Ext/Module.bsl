#region SabatexExchange
// Copyright (c) 2021 by Serhiy Lakas
// https://sabatex.github.io
// 1C 8.2.16 compatible
// version 3.0.0-rc6

#region CommonMethods
// Функция - Value or default
//
// Параметры:
//  value	 - any type	 - 
//  default	 - any type	 - 
// 
// Возвращаемое значение:
//   -  as value
//
function ValueOrDefault(value,default) export
	if typeof(default)=type("Number") then
		return ?(value=undefined or value="",default,Number(value));
	elsif  typeof(default)=type("Boolean") then
		return ?(value=undefined or value="",default,value);
	elsif  typeof(default)=type("String") then
		return ?(value=undefined or value="",default,value);
	else
		return ?(value=undefined,default,value);
	endif;	
endfunction


procedure SetSenderValueIfDestinationEmpty(valueName,sender,destination)
	var propValue;
	if sender.Property(valueName,propValue) then
		if not destination.Property(valueName) then
			destination.Insert(valueName,sender[ValueName]);
		endif;	
	endif	
endprocedure
procedure FillStructFromSenderIsEmpty(sender,destination)
	for each item in sender do
		SetSenderValueIfDestinationEmpty(string(item.key),sender,destination);
	enddo;	
endprocedure

function StringStartWith(value,searchString) export
	return StrFind(value,searchString)=1;
endfunction

function DateAddDay(value,count = 1) export
	return value + count*86400;
endfunction

function DateAddHour(value,count = 1) export
	return value + count*3600;
endfunction	

function DateAddMinute(value,count = 1) export
	return value + count*60;
endfunction	
function DigitStrCompare(str1,str2)
	val1 = Число(str1);
	val2 = Число(str2);
	if val1 > val2 then
		return 1;
	elsif val1< val2 then
		return -1;
	else
		return 0;
	endif;	
endfunction

function GetEmptyUUID() export
	return new UUID("00000000-0000-0000-0000-000000000000");
endfunction

// Перевірка на пустий UUID
//  - value (UUID or string)
function IsEmptyUUID(value) export
	if TypeOf(value) = type("UUID") then
		return value = GetEmptyUUID();
	elsif TypeOf(value) = type("string") then
		return new UUID(value) = GetEmptyUUID();
	else
		raise("Неправильний тип value");
	endif;	
endfunction	

function ConvertQueriesToTable(queryList)
	table = new ValueTable;
	table.Columns.Add("nodeName");
	table.Columns.Add("objectType");
	table.Columns.Add("objectId");
	for each query in queryList do
		row = table.Add();
		row.nodeName = query.nodeName;
		row.objectType = query.objectType;
		row.objectId = query.objectId;
	enddo;
	table.GroupBy("nodeName,objectType,objectId");
endfunction

//function StringSplit(value,delimiter=";",includeEmpty=true) export
//	
//	if StrLen(delimiter) <> 1 then
//		raise "Роздільник має бути тільки 1 символ.";
//	endif;	
//	
//	result = new array;
//	position = 1;
//	success = true;
//	while success do
//		nextPosition =  StrFind(value,delimiter,position);
//		if nextPosition = 0 then
//			success = false;
//			continue;
//		endif;
//		count =  nextPosition - position;
//		if count = 0 then
//			if includeEmpty then
//				result.Add("");
//			endif;	
//			position = position + 1;
//			continue;
//		endif;
//		result.Add(Mid(value,position,count));
//		position = position + count +1;
//	enddo;
//	return result;
//endfunction

// порівняння двох версій шаблону 0.0.0
//	- ver1 
//  - ver2
//result
//	- 0   ver1 = ver2
//  - 1   ver1 > ver2
//  - -1  ver1 < ver2
//function VersionCompare(ver1,ver2) export
//	ver1arr = StringSplit(ver1,".",false);
//	ver2arr = StringSplit(ver2,".",false);
//	if ver1arr.Количество() <> 3 then
//		raise "Арнумент 1 не того формату ver1=" + ver1 + " шаблон 0.0.0";
//	endif;	
//	if ver1arr.Количество() <> 3 then
//		raise "Арнумент 2 не того формату ver2=" + ver1 + " шаблон 0.0.0";
//	endif;	
//	for i=0 to 2 do
//		r = DigitStrCompare(ver1arr[i],ver2arr[i]);
//		if r <> 0 then
//			return r;
//		endif;
//	enddo;
//	return 0;
//endfunction

//function ItemOrDefault(items,itemName,default) export
//	return ValueOrDefault(items[itemName],default);	
//endfunction	

#endregion

#region Logged
procedure SystemLog(logLevel,message)
	WriteLogEvent("SabatexExchange",logLevel,,,message);
endprocedure	
procedure SystemLogError(message) export
	WriteLogEvent("SabatexExchange",EventLogLevel.Error,,,message);
endprocedure	

// Процедура - Логування 
//
// Параметры:
//  conf			 - structure	 - 
//  level			 - integer	 -  0 Error,1 Warning,2 Information,3-9 Note
//  sourceName		 - string	 - 
//  message			 - string	 -  Повідомлення
//  isJournalWrite	 - boolean	 -  Чи проводити запис в загальний лог
//
procedure Logged(conf,level,sourceName,message,isJournalWrite)
	if level <= conf.LogLevel then
		conf.Log = conf.Log + message + Символы.ПС;
		if isJournalWrite then
			if level = 0 then
				logLevel = EventLogLevel.Error;
			elsif level=1 then
				logLevel = EventLogLevel.Warning;
			elsif level=2 then
				logLevel = EventLogLevel.Information;
			else
				logLevel = EventLogLevel.Note;
			endif;	
			
			WriteLogEvent("SabatexExchange",logLevel,sourceName,,message);
		endif;
	endif;
endprocedure
// Процедура - Sabatex log error
//
// Параметры:
//  conf	 - structure - LogLevel - рівень логування, Log - додаэться поточний лог 
//  message	 - 	 - 
//
procedure Error(conf,message,isJournalWrite=false) export
	conf.success = false;
	Logged(conf,0,"",message,isJournalWrite);		
endprocedure	
// Процедура - Sabatex log warning
//
// Параметры:
//  conf	 - 	 - 
//  message	 - 	 - 
//
procedure Warning(conf,message,isJournalWrite=false) export
	Logged(conf,1,"",message,isJournalWrite);		
endprocedure
// Процедура - Sabatex log information
//
// Параметры:
//  conf	 - 	 - 
//  message	 - 	 - 
//
procedure Information(conf,message,isJournalWrite=false) export
	Logged(conf,2,"",message,isJournalWrite);		
endprocedure
// Процедура - Sabatex log note
//
// Параметры:
//  conf	 - 	 - 
//  message	 - 	 - 
//
procedure Note(conf,message,isJournalWrite=false) export
	Logged(conf,3,"",message,isJournalWrite);		
endprocedure
#endregion


#region ExchangeWebApi
function CreateHTTPSConnection(conf)
	nodeConfig = conf.nodeConfig;
	ssl = ?(nodeConfig.https,new ЗащищенноеСоединениеOpenSSL( undefined, undefined ),undefined);
	host = nodeConfig.host;
	port = nodeConfig.port;
	result = new HTTPConnection(host,port,,,,,ssl);

	return result;
	
endfunction	
function BuildUrl(url,queries=null)
	result  = url;
		if queries <> null then
			result  = result +"?";
			last = false;
			for each item in queries do
				if last then
					result = result + "&";
				endif;
				last=true;
				result = result + item.Ключ +"="+item.Значение;
			enddo;
		endif;
	return result;
endfunction	
// Ідентифікація на сервері обміну
// - nodeConfig параметри зєднання
// result:
//  accessToken
function Login(conf)
	connection = CreateHTTPSConnection(conf);
	request = new HTTPRequest(BuildUrl("api/v0/login"));
	request.Headers.Insert("accept","*/*");
	request.Headers.Insert("Content-Type","application/json; charset=utf-8");
	jsonString = Serialize(new structure("clientId,password",string(conf.nodeConfig.clientId),conf.nodeConfig.password));
	request.SetBodyFromString(jsonString,"UTF-8",ИспользованиеByteOrderMark.НеИспользовать);
	response = connection.Post(request);
		
	if response.StatusCode <> 200 then
		raise "Login error with StatusCode="+ response.StatusCode;
	endif;
		
	apiToken = response.GetBodyAsString();
	
	if apiToken = "" then
		raise "Не отримано токен";
	endif;	
	return Deserialize(apiToken);
endfunction
// отримати новий токен за допомогою  refresh_token
function RefreshToken(conf)
	connection = CreateHTTPSConnection(conf);
	request = new HTTPRequest(BuildUrl("api/v0/refresh_token"));
	request.Headers.Insert("accept","*/*");
	request.Headers.Insert("Content-Type","application/json; charset=utf-8");
	jsonString = Serialize(new structure("clientId,password",string(conf.nodeConfig.clientId),conf.accessToken.refresh_token));
	request.SetBodyFromString(jsonString,"UTF-8",ИспользованиеByteOrderMark.НеИспользовать);
	response = connection.Post(request);
	
		if response.StatusCode <> 200 then
			raise "Login error request with StatusCode="+ response.StatusCode;
		endif;

	apiToken = response.GetBodyAsString();
	
	if apiToken = "" then
			raise "Не отримано токен";
	endif;
	return Deserialize(apiToken);
endfunction
// оновити токен (при неуспішному обміні)
function updateToken(conf)
	// 1. спроба оновити токен за допомогою рефреш токена
	try
		token = RefreshToken(conf);
		InformationRegisters.SabatexExchangeNodeConfig.SetAccessToken(conf,token);
		return true;
	except
	endtry;	
	
	// 2. спроба оновити токен за допомогою login
	try
		token = Login(conf);
		SetAccessToken(conf,token);
	except
	endtry;	
	return false;
endfunction
// download objects from server bay sender nodeName
function GetObjectsExchange(conf,first=true)
	connection = CreateHTTPSConnection(conf);
	request = new HTTPRequest(BuildUrl("api/v0/objects",new structure("take",conf.take)));
	request.Headers.Insert("accept","*/*");
	request.Headers.Insert("clientId",conf.nodeConfig.clientId);
	request.Headers.Insert("destinationId",conf.destinationId);
	request.Headers.Insert("apiToken",conf.accessToken.access_token);
	request.Headers.Insert("Content-Type","application/json; charset=utf-8");
	try
		response = connection.Get(request);
		if response.StatusCode = 401 then
			if first then
				if updateToken(conf) then
					return GetObjectsExchange(conf,false);
				endif;
			endif;
		endif;
			

		if response.StatusCode <> 200 then
			raise "GetObjectsExchange error request with StatusCode="+ response.StatusCode;
		endif;
		datefields = new array;
		datefields.Add("dateStamp");
		return Deserialize(response.GetBodyAsString(),datefields);	
	except
		raise "GetObjectsExchange error request with error:"+ОписаниеОшибки();
	endtry;	
endfunction
procedure DeleteExchangeObject(conf,id,first=true)
	connection = CreateHTTPSConnection(conf);
	request = new HTTPRequest(BuildUrl("/api/v0/objects/"+XMLString(id)));
	request.Headers.Insert("accept","*/*");
	request.Headers.Insert("clientId",conf.nodeConfig.clientId);
	request.Headers.Insert("apiToken",conf.accessToken.access_token);
	try
		response = connection.Delete(request);
		if response.StatusCode = 401 then
			if first then
				if updateToken(conf) then
					DeleteExchangeObject(conf,id,false);
					return;
				endif;
			endif;
		endif;
		
		if response.StatusCode <> 200 then
			raise "Помилка запиту /api/v0/objects with id=" +XMLString(id)+ " with StatusCode: "+ response.StatusCode;	
		endif;
	except
		raise "DeleteExchangeObject error request with error:"+ОписаниеОшибки();
	endtry;	

endprocedure
// POST Object to exchange service
// params:
//	 conf 			- structure (configuration)
//   destinationId  - string destination node id
//   objectType     - string(50) object type
//   objectId		- string(50) object Id
//   dateStamp      - DateTime The registered moment
//   textJSON       - The serialized object to JSON 
procedure POSTExchangeObject(conf, objectType, objectId, dateStamp,textJSON,first=true)
	connection = CreateHTTPSConnection(conf);
	request = new HTTPRequest(BuildUrl("api/v0/objects"));
	request.Headers.Insert("accept","*/*");
	request.Headers.Insert("Content-Type","application/json; charset=utf-8");
	request.Headers.Insert("clientId",XMLСтрока(conf.nodeConfig.clientId));
	request.Headers.Insert("apiToken",XMLСтрока(conf.accessToken.access_token));
	request.Headers.Insert("destinationId",XMLСтрока(conf.destinationId));
	try			  
		jsonString = Serialize(new structure("objectType,objectId,dateStamp,text",objectType,XMLСтрока(objectId),dateStamp,textJSON));
		request.SetBodyFromString(jsonString,"UTF-8",ИспользованиеByteOrderMark.НеИспользовать);
		response = connection.Post(request);
		if response.StatusCode = 401 then
			if first then
				if updateToken(conf) then
					POSTExchangeObject(conf,objectType,objectId,dateStamp,textJSON,false);
					return;
				endif;
			endif;
		endif;

		if response.StatusCode <> 200 then
			raise "Помилка POST /api/v0/objects  with StatusCode: "+ response.StatusCode;	
		endif;
	except
		error = "Помилка ідентифікації на сервері! Error:"+ОписаниеОшибки();
		raise error;
	endtry;	
endprocedure	
// get queried objects
function GetQueriedObjects(conf,first=true)
	connection = CreateHTTPSConnection(conf);
	request = new HTTPRequest(BuildUrl("/api/v0/queries",new structure("take",conf.take)));
	request.Headers.Insert("accept","*/*");
	request.Headers.Insert("clientId",string(conf.nodeConfig.clientId));
	request.Headers.Insert("destinationId",string(conf.destinationId));
	request.Headers.Insert("apiToken",string(conf.accessToken.access_token));
	try
		response = connection.Get(request);
		if response.StatusCode = 401 then
			if first then
				if updateToken(conf) then
					return GetQueriedObjects(conf,false);
				endif;
			endif;
		endif;
			
		if response.StatusCode <> 200 then
			raise "Помилка запиту /api/v0/queries " + response.StatusCode;		
		endif;
		return Deserialize(response.GetBodyAsString());
	except  
		raise "Error GetQueriedObjects: "+ ОписаниеОшибки();	
	endtry;
endfunction
// Видалення запиту з сервера.
//
// Параметры:
//    conf  - налаштування зэднання
//    id    - внутрышнэ id обэкта
//    first - true(за замовчуванням), false - при повторному виклику.
procedure DeleteQueriesObject(conf,id,first=true)
	connection = CreateHTTPSConnection(conf);
	request = new HTTPRequest(BuildUrl("/api/v0/queries/"+XMLСтрока(id)));
	request.Headers.Insert("accept","*/*");
	request.Headers.Insert("clientId",string(conf.nodeConfig.clientId));
	request.Headers.Insert("apiToken",string(conf.accessToken.access_token));
	try
 		response = connection.Delete(request);
		
		if response.StatusCode = 401 then
			if first then
				if updateToken(conf) then
					DeleteQueriesObject(conf,id,false);
					return;
				endif;
			endif;
		endif;

	if response.StatusCode <> 200 then
		raise "Помилка запиту /api/v0/queries with id=" +id+ " with StatusCode: "+ response.StatusCode;	
	endif;
	except  
		raise "Error DeleteQueriesObject: "+ ОписаниеОшибки();	
	endtry;

endprocedure	
// реєструє запит на сервері та повертає ід запита
procedure PostQueries(conf,ObjectId,ObjectType,first=true)
	connection = CreateHTTPSConnection(conf);
	request = new HTTPRequest(BuildUrl("api/v0/queries"));
	request.Headers.Insert("accept","*/*");
	request.Headers.Insert("Content-Type","application/json; charset=utf-8");
	request.Headers.Insert("clientId",string(conf.nodeConfig.clientId));
	request.Headers.Insert("destinationId",string(conf.destinationId));
	request.Headers.Insert("apiToken",string(conf.accessToken.access_token));
	
	try			  
		jsonString = Serialize(new structure("objectType,objectId",objectType,objectId));
		request.SetBodyFromString(jsonString,"UTF-8",ИспользованиеByteOrderMark.НеИспользовать);
		response = connection.Post(request);
		
		if response.StatusCode = 401 then
			if first then
				if updateToken(conf) then
					PostQueries(conf,ObjectId,ObjectType,false);
					return;
				endif;
			endif;
		endif;
		if response.StatusCode <> 200 then
			raise "Помилка POST /api/v0/queries  with StatusCode: "+ response.StatusCode;	
		endif;

	except
		error = "Помилка ідентифікації на сервері! Error:"+ОписаниеОшибки();
		raise error;
	endtry;	
endprocedure
function GetAccessToken()
	reg =  InformationRegisters.SabatexExchangeConfig.Get(new structure("Key","AccessToken"));
	token =  Deserialize(ValueOrDefault(reg.Value,"{}"));
	if TypeOf(token) <> Type("Map") then
		token = new Map;
	endif;	
	result = new Structure;
	result.Insert("access_token",ValueOrDefault(token["access_token"],"undefined"));
	result.Insert("token_type",ValueOrDefault(token["token_type"],""));
	result.Insert("refresh_token",ValueOrDefault(token["refresh_token"],"undefined"));
	result.Insert("expires_in",ValueOrDefault(token["expires_in"],CurrentDate()));
	return result;
endfunction
// Процедура - Sabatex set access token
//
// Параметры:
//  conf		 - 	 - 
//  accessToken	 - 	 - 
//
procedure SetAccessToken(conf,accessToken)
    expires_in = CurrentDate()+ Number(accessToken["expires_in"]);
    result = new Structure;
	result.Insert("access_token",ValueOrDefault(accessToken["access_token"],"undefined"));
	result.Insert("token_type",ValueOrDefault(accessToken["token_type"],""));
	result.Insert("refresh_token",ValueOrDefault(accessToken["refresh_token"],"undefined"));
	result.Insert("expires_in",ValueOrDefault(accessToken["expires_in"],CurrentDate()));
	reg = InformationRegisters.SabatexExchangeConfig.CreateRecordManager();
	reg.Key = "AccessToken";
	reg.Value  = Serialize(result);
	reg.Write(true);
	conf["accessToken"]=GetAccessToken();
endprocedure


#endregion


#region JSON
// Функция - Sabatex JSONSerialize
//
// Параметры:
//  object	 - 	 - 
// 
// Возвращаемое значение:
//   -  Серіалізований в строку обєкт 
//
function Serialize(object)
	jsonWriter = new JSONWriter;
	jsonParams = new JSONWriterSettings(ПереносСтрокJSON.Нет,,,,,,true);
	jsonWriter.SetString(jsonParams);
	if TypeOf(object) = Type("Structure")or TypeOf(object) = Type("Array")  then
		WriteJSON(jsonWriter,object);
	else
		СериализаторXDTO.WriteJSON(jsonWriter,object,НазначениеТипаXML.Неявное);
	endif;
	return jsonWriter.Close();
endfunction

// Функция - Sabatex JSONDeserialize
//
// Параметры:
//  txt			 - string	 - JSON текст
//  datefields	 - array	 - список полів з типом Date
// 
// Возвращаемое значение:
//   - десеріалызований обєкт в Map
//
function Deserialize(txt,datefields = undefined)
	if datefields = undefined then
		datefields = new array;
	endif;	
	
	jsonReader=Новый JSONReader;	
	jsonReader.SetString(txt);
	result = ReadJSON(jsonReader,true,datefields);
	if typeof(result) = type("Map") then
		objectXDTO = result.Get("#value");
		if objectXDTO <> undefined then
			return objectXDTO;
		endif;
	endif;
	return result;
endfunction	
#endregion


#region ExchangeConfig
// Функция - Get node config
// 
// Возвращаемое значение:
//   - 
//
function GetHostConfig() export
	reg = InformationRegisters.SabatexExchangeConfig.Get(new structure("Key","HostConfig"));
	rootNode =  Deserialize(ValueOrDefault(reg.Value,"{}")); 
	result = new structure;
	result.Insert("clientId",ValueOrDefault(rootNode["clientId"],""));
	result.Insert("https",ValueOrDefault(rootNode["https"],true));
	result.Insert("Host",ValueOrDefault(rootNode["Host"],"sabatex.francecentral.cloudapp.azure.com"));
	result.Insert("Port",ValueOrDefault(rootNode["Port"],443));
	result.Insert("password",ValueOrDefault(rootNode["password"],""));
	return result;
endfunction
procedure SetHostConfig(hostConfig) export
	reg = InformationRegisters.SabatexExchangeConfig.CreateRecordManager();
	reg.Key = "HostConfig";
	reg.Value  = Serialize(hostConfig);;
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
	config.Insert("QueryParser","SabatexExchange.defaultQueryParser");
	config.Insert("IsQueryEnable",destinationNode.IsQueryEnable);
	config.Insert("ExchangeMode",destinationNode.ExchangeMode);
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
			|	SabatexExchangeNodeConfig.ExchangeMode AS ExchangeMode
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
function StrIsEnum(value) export
	return upper(value)="ПЕРЕЧИСЛЕНИЕ";	
endfunction	
// Функция - Is catalog
//
// Параметры:
//  objectType	 - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function StrIsCatalog(objectType) export
	return upper(objectType)="СПРАВОЧНИК";	
endfunction	
	
// Функция - Is document
//
// Параметры:
//  objectType	 - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function StrIsDocument(objectType) export
	return upper(objectType) ="ДОКУМЕНТ";	
endfunction	

function ValidateObject(objectType)
	if IsCatalog(ObjectType) or IsDocument(ObjectType) or IsEnum(ObjectType) then
		return true;	
	endif;
	return false;
	
endfunction	


function GetNormalizedObjectType(objectType)
	return StrReplace(objectType,".","_");
endfunction	


function CreateExternalObjectDescriptor(conf,externalObjectType,parserProc=undefined,internalObjectDescriptor=undefined)
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
//  uninserted		 	 - bool 	 -  (необовязково) Обэкт тільки синхронізується з базою 
// 
// Возвращаемое значение:
//   structure - objectDescriptor
//
function CreateObjectDescriptor(Conf,ObjectType,val ExternalObjectType=undefined,PostParser=undefined,IdAttribute=undefined,LookObjectProc=undefined,uninserted=false) export
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
	




procedure AddAttributeProperty(objectConf,attrName,Ignore=true,default=undefined,destinationName=undefined,procName=undefined,postParser=undefined) export
	attr = new structure("ignore,default,destinationName,procName,postParser",Ignore,default,destinationName,procName,postParser);
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
	return result.InternalObjectType;
endfunction




#endregion

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
	return StringStartWith(upper(objectType),"ПЕРЕЧИСЛЕНИЕ");	
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
	return StringStartWith(upper(objectType),"СПРАВОЧНИК");	
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
	return StringStartWith(upper(objectType),"ДОКУМЕНТ");	
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
			objectType = GetInternalObjectType(conf,"справочник."+lower(typeName));
			return true;
		elsif subType = "jcfg:DocumentRef." then
			objectType = GetInternalObjectType(conf,"документ."+lower(typeName));
			return  true;
		else
			Error(conf,"Невідомий тип " + complexType);
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
		if conf.Objects.Property(GetNormalizedObjectType(objectType))then
			raise "Імпорт не підтримується";
		endif;
	endif;
	
	
	enumRelolveProc =  objectDescriptor.PostParser;
	if enumRelolveProc = undefined then
		try
			x= Enums[GetNameObject(objectType)];
		except
			Error(conf,"Помилка отримання перерахування конфігурації - "+objectType);
			return Enums.AllRefsType();
		endtry;
		if objectId = "" then
			return Enums.AllRefsType();
		endif;	
		
		try
			return x[objectId];
		except
			Error(conf,"Помилка отримання зжначення - "+objectId+" - з перерахування конфігурації - "+objectType);
			return x.EmptyRef();
		endtry;
	else
		try
			result = undefined;
			Execute(conf.userDefinedModule+"."+enumRelolveProc+"(conf,objectId,result)");
			return result;
		except
		    Error(conf,"Помилка виклику метода користувача"+enumRelolveProc+" : " +ErrorDescription());
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
			Error(conf,"Помилка отримання комплексного типу "+objectType + "  з objectId ="+objectId );
			return undefined;
		endtry;	
	endif;	
	
	if objectDescriptor = undefined then
		if not conf.Objects.Property(GetNormalizedObjectType(objectType),objectDescriptor) then
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
	
	if IsEmptyUUID(ObjectId) then
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
		incoming = GetObjectsExchange(conf);
		for each item in incoming do
			objectId = "";
			objectType = "";
			BeginTransaction();
			try
				AddUnresolvedObject(conf,item);
				DeleteExchangeObject(conf,item["id"]);
				CommitTransaction();
			except
				Error(conf,"Do not load objectId=" + objectId + ";objectType="+ objectType + " Error Message: " + ОписаниеОшибки());
				RollbackTransaction();
			endtry;
		enddo;
endprocedure
procedure PostObjects(conf)
	// post queries
	conf.queryList.GroupBy("objectType,objectId");
	for each query in conf.queryList do 
		PostQueries(conf,query.objectId,query.objectType);
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
				objectJSON =Serialize(object);
				POSTExchangeObject(conf,objectType,string(objectId),items.dateStamp,objectJSON);
			endif;
			DeleteObjectForExchange(objectId,objectType,conf.nodeName);
		except
			
		endtry;
	enddo;
endprocedure	
#endregion

#region AnalizeObjects

procedure AddUnresolvedObject(conf,item,newObject = true)
	reg = InformationRegisters.sabatexExchangeUnresolvedObjects.CreateRecordManager();
	reg.Id = item["id"];
	reg.sender = new UUID(item["sender"]);
	reg.destination = new UUID(item["destination"]);
	reg.objectId = Upper(item["objectId"]);
	reg.objectType = Upper(item["objectType"]);
	reg.dateStamp = CurrentDate();
	reg.serverDateStamp = item["dateStamp"];
	reg.objectAsText = item["objectAsText"];
	reg.Log = ?(newObject,"",conf.Log);
	reg.Write();
endprocedure
procedure LevelUpUnresolvedObject(conf,item)
	reg = InformationRegisters.sabatexExchangeUnresolvedObjects.CreateRecordManager();
	reg.sender = item.sender;
	reg.Id = item.id;
	reg.Read();
	reg.levelLive = reg.levelLive +1;
	reg.Log = conf.Log;
	reg.Write();
endprocedure
procedure DeleteUnresolvedObject(conf,item)
	reg = InformationRegisters.sabatexExchangeUnresolvedObjects.CreateRecordManager();;
	reg.sender = item.sender;
	reg.Id = item.Id;
	reg.dateStamp = item.dateStamp;
	reg.Delete();
endprocedure	
// Процедура - Set attribute
//
// Параметры:
//  conf		 - structure	 - 
//  source		 - 	 - 
//  destination	 - 	 - 
//  attr		 - 	 - 
//  success		 - 	 - 
//
procedure SetAttribute(conf,objectConf,source,destination,attr,tableName=undefined)
	var attrConf;
	sourceAttrName = attr.Name;
	if objectConf <> undefined and  objectConf.Attributes.Property(attr.Name,attrConf) then
		// check ignore
		if attrConf.Ignore then
			return;
		endif;
		
		// default attribute
		if attrConf.default <> undefined then
			destination[attr.Name] = attrConf.default;
			return;
		endif;
		
		if attrConf.procName <> undefined then
			methodName = conf.userDefinedModule+"."+attrConf.procName;
			try
				Execute(methodname+ "(conf,source,destination,attr)");
			except
				Error(conf,"Помилка виконання методу визначено користувачем - "+methodName+" Error:"+ErrorDescription());
			endtry;	
	    	return;
		endif;
	

		sourceAttrName = ValueOrDefault(attrConf.destinationName,attr.Name);
	endif;
	    	
	types = attr.Type.Типы();
	if types.Count() =1 then
		attrType = types[0];
		//typeName = destination.Metadata().FullName();
		
		importValue = source[sourceAttrName];
		if importValue = undefined then
			raise "Атрибут "+ sourceAttrName + " відсутній в файлі імпорта.";
		endif;	
		
		
		if attrType = Type("string") or attrType = Type("Boolean") or attrType = Type("Number")  then
			destination[attr.name] = importValue;
		elsif attrType = Type("Date") then
			destination[attr.name] = XMLValue(attrType,importValue);
    	else
			mtype = Metadata.FindByType(attrType);
			
			try
				destination[attr.Name] = GetObjectRef(conf,mtype.FullName(),importValue);
			except
				Error(conf,"Помилка отримання атрибуту - "+attr.name+" Error:"+ErrorDescription());
				return;
			endtry;
		endif;
	else
		Error(conf,"Помилка встановлення комплексного значення для атрибуту "+attr.Name);
	endif;
	
	if attrConf <> undefined then
		if attrConf.postParser <> undefined then
			methodName = conf.userDefinedModule+"."+attrConf.postParser;
			try
				Execute(methodname+ "(conf,source,destination,attr)");
			except
				Error(conf,"Помилка виконання методу визначено користувачем - "+methodName+" Error:"+ErrorDescription());
			endtry;	
	    	return;
		endif;
	endif;

endprocedure	

// Процедура - Resolve attributes and tabular sections
//
// Параметры:
//  conf		 - 	 - 
//  localobject	 - 	 - 
//  mdata		 - 	 - 
//
procedure ResolveAttributesAndTabularSections(conf,localobject,mdata)
	// set attributes
	for each attr in mdata.Attributes do
		try
			SetAttribute(conf,conf.objectDescriptor ,conf.source,localObject,attr);
		except
			Error(conf,"Помилка встановлення атрибуту "+ attr.Name+ " Error:"+ErrorDescription());  
		endtry;
		
	enddo;	
	// set tab
	for each table in mdata.TabularSections do
		sourceAttrName = table.Name;
		tableAttribute = undefined;
		if conf.objectDescriptor.Tables.Property(table.Name,tableAttribute) then
			// check ignore
			if tableAttribute.Ignore then
				continue;
			endif;
			
			// default attribute (not exist)
			
			if tableAttribute.procName <> undefined then
				methodName = conf.userDefinedModule+"."+tableAttribute.procName;
				try
					Execute(methodname+ "(conf,source,destination,table)");
				except
					Error(conf,"Помилка виконання методу визначено користувачем - "+methodName+" Error:"+ErrorDescription());
				endtry;	
				continue;
			endif;
			sourceAttrName = ValueOrDefault(tableAttribute.destinationName,table.Name);
		endif;
	
		ts = conf.source[sourceAttrName];
		if ts <> undefined then
			for each line in ts do
				row = localObject[table.Name].Add();
				for each attr in table.Attributes do
					try
						SetAttribute(conf,tableAttribute,line,row,attr,table.Name);
					except
						Error(conf,"Помилка встановлення атрибуту "+ attr.Name+ " для табличної частини "+ table.Name+" Error:"+ErrorDescription());  
					endtry;
						
				enddo;
				
				if tableAttribute <> undefined then
					if tableAttribute.postParser <> undefined then
						methodName = conf.userDefinedModule+"."+tableAttribute.postParser;
						try
							Execute(methodname+ "(conf,line,row)");
						except
							Error(conf,"Помилка виконання методу визначено користувачем - "+methodName+" Error:"+ErrorDescription());
						endtry;	
					endif;
				endif;

			enddo;
			
		endif;

	enddo;	
endprocedure	

// Процедура - Resolve object catalog
//
// Параметры:
//  conf		 - structure	 - параметри нода
//  localObject  - object        - існуючий обьєкт який обробляється або undefined 
// 
// Возвращаемое значение:
//   -  Object - Ще не записаний обэкт
//
procedure ResolveObjectCatalog(conf,localObject)
	if localObject = undefined then
		// new object
		if Metadata.Catalogs[GetNameObject(conf.ObjectDescriptor.ObjectType)].Hierarchical  then
			isFolder = conf.source["IsFolder"];
			if ?(isFolder = undefined,false,isFolder) then
				localObject = Catalogs[GetNameObject(conf.ObjectDescriptor.ObjectType)].CreateFolder();
			else
				localObject = Catalogs[GetNameObject(conf.ObjectDescriptor.ObjectType)].CreateItem();
			endif;
		else
			localObject = Catalogs[GetNameObject(conf.ObjectDescriptor.ObjectType)].CreateItem();
		endif;
	endif;
	
	if conf.updateCatalogs or localObject.isNew() then		
		
		localObject.DeletionMark = conf.source["DeletionMark"];
		mdata = localObject.Metadata();
		if mdata.CodeLength <> 0 then
			code = conf.source["Code"];
			if code <> undefined then
				localObject.Code = conf.source["Code"];
			endif;
		endif;
		
		if mdata.DescriptionLength <> 0 then
			localObject.Description = conf.source["Description"];
		endif;
		
		if mdata.Owners.Count() <> 0 then
			owner = conf.source["Owner"];
			if owner <> undefined then
				localObject.Owner = GetObjectRef(conf,mdata.FullName(),owner);
			endif;
		endif;
		
		if mdata.Hierarchical then
			parent = conf.source["Parent"];
			if parent <> undefined then
				localObject.Parent = GetObjectRef(conf,mdata.FullName(),conf.source["Parent"]);
			endif;	
			if localObject.IsFolder then
				return;
			endif;	
		endif;	
		
		ResolveAttributesAndTabularSections(conf,localObject,mdata);
	endif;
endprocedure	

procedure ResolveObjectDocument(conf,localObject)
	if localObject = undefined then
		localObject = Documents[GetNameObject(conf.ObjectDescriptor.ObjectType)].CreateDocument();
	endif;
	
	localObject.DeletionMark = conf.source["DeletionMark"];
	mdata = localObject.Metadata();
		
	localObject.Number = conf.source["Number"];
	localObject.Date = XMLValue(Type("Date"),conf.source["Date"]);
		
	ResolveAttributesAndTabularSections(conf,localObject,mdata);
	
endprocedure	

// Процедура - Аналіз вхідного обєкта
//
// Параметры:
//  conf		     - structure	 - параметри нода
//  conf.objectId	 - string	 -  ключ обєкта в системі клієнта
//  conf.objectType	 - string	 -  зовнішній тип обэкта (Справочник.Номенклатура)
//  conf.source		 - map	     -  Десеріалізований обєкт
//  conf.success	 - boolean	 -  Встановлюється признак помилки
//
procedure ResolveObject(conf)
	var extObjectConf;
	if not conf.ExternalObjects.Property(GetNormalizedObjectType(conf.objectType),extObjectConf) then
		raise "Імпорт обєктів даного типу не відтримується.";
	endif;	
	
	if extObjectConf.Parser <> undefined then
		try
			Execute(conf.userDefinedModule+"."+extObjectConf.Parser+"(conf)");
			return;
		except
			raise "Помилка виклику метода користувача"+extObjectConf.Parser+" : " +ErrorDescription();
		endtry;
	endif;	
	
	// спроба отримати налащтування для обєкта
	if extObjectConf.InternalObject = undefined then
		raise "Імпорт обєктів даного типу не відтримується.";	
	endif;	
	
	conf.ObjectDescriptor =  extObjectConf.InternalObject;
	
	// Використовуэмо автоматичний парсер
	objectManager = GetObjectManager(conf);
	if objectManager = undefined then
		raise "Обробка даного типу не підтримуэться - "+conf.localObjectType;
	endif;
	
	// варіант пошуку по атрибуту
	attributeId = conf.ObjectDescriptor.IdAttribute;
	
	// пошук обэкта по ід або атрибуту
	if attributeId = undefined then
		localObject = objectManager.GetRef(new UUID(conf.objectId)).GetObject();	
	else
		objectRef = objectManager.FindByAttribute(attributeId,new UUID(conf.objectId));
		if objectRef <> objectManager.EmptyRef() then
			localObject = objectRef.GetObject();
		endif;	
	endif;
	
	// спроба пошуку по користувацьким параметрам тільки непомічені до видалення
	if localObject = undefined and conf.source["DeletionMark"] = false then
		userDefinedLookProc =   conf.ObjectDescriptor.lookObjectProc;
		if userDefinedLookProc <> undefined then
			try
				Execute(conf.userDefinedModule+"."+userDefinedLookProc+"(conf,localObject)");
			except
				raise "Помилка виклику метода користувача"+userDefinedLookProc+" : " +ErrorDescription();
			endtry;
		endif;	
	endif;
	
	// пропуск видалених обєктів 
	if localObject = undefined and conf.source["DeletionMark"] = true then
		raise "Спроба імпорту нового обєкта поміченого до видалення в віддаленій системі";
	endif;	
	
	if conf.ObjectDescriptor.UnInserted then
		if localObject = undefined then
			raise "Обєкт не ідентифіковано. Даний обєкт необхвдно додавати вручну.";
		endif;
	else
	if localObject = undefined  then
		conf.isUpdated = true;
		// новий обьэкт
		if IsCatalog(conf.ObjectDescriptor.ObjectType) then
			ResolveObjectCatalog(conf,localObject);
		elsif IsDocument(conf.ObjectDescriptor.ObjectType) then
			if localObject <> undefined then
				if localObject.Проведен then
					return;
				endif;
			endif;
			ResolveObjectDocument(conf,localObject);
		else
			raise "Обробка даного типу не підтримуэться - "+conf.ObjectType;
		endif;
	endif;	
		
	endif;	

	// Постобробка
	if conf.ObjectDescriptor.PostParser <> undefined then
		try
			Execute(conf.userDefinedModule+"."+conf.ObjectDescriptor.PostParser+"(conf,localObject)");
		except
			raise "Помилка виклику метода користувача"+conf.ObjectDescriptor.PostParser+" : " +ErrorDescription();
		endtry;
	endif;
	
	// встановлення id обэкта
	if attributeId <> undefined then
		if localObject[attributeId] <> conf.objectId then
			mData = localObject.Metadata();
			attr = mData.Attributes[attributeId]; 
			types = attr.Type.Типы();
			if types.Count() =1 then
				attrType = types[0];
				if attrType = Type("string") then
					localObject[attributeId] = conf.objectId;
				elsif attrType = Type("UUID") then
					localObject[attributeId] = new UUID(conf.objectId);
				else
					raise "Помилка встановлення атрибуту " + attributeId + " for type = "+attrType;
				endif;
			else
				raise "Помилка встановлення атрибуту " + attributeId + " for complex type.";
			endif;
			
			conf.isUpdated = true;
		endif;
	else
		if localObject.IsNew() and conf.success then
			objectUUID = objectManager.GetRef(new UUID(conf.objectId));
			localObject.SetNewObjectRef(objectUUID);
		endif;	
	endif;
	
	
	
	
	
	
	
	// Запис обьєкта		
	if conf.success and conf.isUpdated then
		try
			localObject.Write();
		except
			Error(conf,"Помилка запису. Error:"+ErrorDescription());
		endtry;	
	endif;	
endprocedure

// Процедура - Аналіз 200 обєктів з урахуванням спроб (спочатку нові)
//
// Параметры:
//  conf - 	 - 
//
procedure AnalizeUnresolvedObjects(conf)
		Query = New Query;
		Query.Text = 
		"SELECT TOP 200
		|	sabatexExchangeUnresolvedObjects.sender AS sender,
		|	sabatexExchangeUnresolvedObjects.destination AS destination,
		|	sabatexExchangeUnresolvedObjects.dateStamp AS dateStamp,
		|	sabatexExchangeUnresolvedObjects.objectId AS objectId,
		|	sabatexExchangeUnresolvedObjects.objectType AS objectType,
		|	sabatexExchangeUnresolvedObjects.objectAsText AS objectAsText,
		|	sabatexExchangeUnresolvedObjects.Log AS Log,
		|	sabatexExchangeUnresolvedObjects.senderDateStamp AS senderDateStamp,
		|	sabatexExchangeUnresolvedObjects.serverDateStamp AS serverDateStamp,
		|	sabatexExchangeUnresolvedObjects.Id AS Id,
		|	sabatexExchangeUnresolvedObjects.levelLive AS levelLive
		|FROM
		|	InformationRegister.sabatexExchangeUnresolvedObjects AS sabatexExchangeUnresolvedObjects
		|WHERE
		|	sabatexExchangeUnresolvedObjects.sender = &sender
		|
		|ORDER BY
		|	levelLive";
		
		Query.SetParameter("sender",new UUID(conf.destinationId));
		QueryResult = Query.Execute();
		
		SelectionDetailRecords = QueryResult.Select();
		
		While SelectionDetailRecords.Next() Do
			try
				conf.objectId = SelectionDetailRecords["objectId"];
				conf.objectType = SelectionDetailRecords["objectType"];
				conf.Log = "";
				conf.success = true;
				conf.isUpdated = false;

				try
					datefields = new array;
					conf.source = Deserialize(SelectionDetailRecords.objectAsText,datefields);
				except
					Error(conf,"Помилка десереалізації ! Error Message: " + ОписаниеОшибки());
				endtry;
				
				if conf.success then
					try
						ResolveObject(conf);
					except
						Error(conf,"Помилка  аналіза Error:" + ОписаниеОшибки(),true);
					endtry;
				endif;
								
				if conf.success then
					DeleteUnresolvedObject(conf,SelectionDetailRecords);
				else
					LevelUpUnresolvedObject(conf,SelectionDetailRecords);
				endif;
				
			except
				Error(conf,"Do not load objectId=" + conf.objectId + ";objectType="+ conf.objectType + " Error Message: " + ОписаниеОшибки(),true);
				continue;
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
	if IsEmptyUUID(objectId) then
		return undefined;
	endif;	
	objRef = Documents[objectName].GetRef(new UUID(objectId));
	if objRef.GetObject() = undefined then
		Error(conf,"Помилка отримання обєкта документа "+objectName + " з ID="+objectId);
		return undefined;
	endif;
	return objRef;
endfunction

function GetCatalogById(conf,objectName,objectId)
	if IsEmptyUUID(objectId) then
		return undefined;
	endif;	

	objRef = Catalogs[objectName].GetRef(new UUID(objectId));
	if objRef.GetObject() = undefined then
		Error(conf,"Помилка отримання обєкта Довідника "+objectName + " з ID="+objectId);
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
		Information(conf,""+objectType + " з Id=" + objectId+" в черзі чекає обробки.");
		// miss unresolved object
		return;
	КонецЦикла;
	
	query = conf.queryList.Add();
	query.objectType = objectType;
	query.objectId = objectId;
	Information(conf,"Відправлено запит на отримання "+ objectType + " з Id=" + objectId);
endprocedure	

// Обробка запитів до системи
procedure DoQueriedObjects(conf)

	queries = GetQueriedObjects(conf);
	
	for each item in queries do
		if IsQueryEnable(conf) then
			objectId = item["objectId"];
			objectType = Upper(item["objectType"]);
			object = undefined;
			if StringStartWith(objectType,upper("справочник")) then
				object = GetCatalogById(conf,GetObjectTypeKind(conf,objectType),objectId);
			elsif StringStartWith(objectType,upper("документ")) then
				object = GetDocumentById(conf,GetObjectTypeKind(conf,objectType),objectId);
			else
				// get extended query
				extensionQueryFunction=undefined;
				if conf.Property("ExtensionQueryFunction",extensionQueryFunction) then
					try
						Execute(extensionQueryFunction+"(conf,objectType,objectId,object)");
					except
						Error(conf,"Помилка виконання розширеного запиту до бази:"+ОписаниеОшибки() );
					endtry;
				endif;
			endif;
			if object <> undefined then
				RegisterObjectForNode(object,conf.NodeName);		
			endif;
		endif;
		DeleteQueriesObject(conf,item["id"]);
	enddo;	    
endprocedure	

#endregion


// Процедура - Розпочати процесс обміну
//
procedure ExchangeProcess(exchangeMode,resultMessage="") export
	resultMessage = "";
	try
	    destinationNodes = GetDestinationNodes();
	except	
		resultMessage = "Помилка зчитування налаштувань обміну:"+ОписаниеОшибки();
		SystemLogError(resultMessage);
		return;
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
				AnalizeUnresolvedObjects(conf);
				
				// Відправка на сервер
				PostObjects(conf);
			except
				message = string(conf.nodeConfig.clientId) + " - Програмна помилка -" + ОписаниеОшибки();
				Error(conf,message,true);
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
		Note(conf,message,true);
		resultMessage = resultMessage  + message+ Chars.CR;
	enddo;
endprocedure

#endregion


