#region SabatexExchange
// Copyright (c) 2021 by Serhiy Lakas
// https://sabatex.github.io
// 1C 8.2.16 compatible
// version 3.0.0-rc6

#region CommonFunctions
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
// порівняння двох версій шаблону 0.0.0
//	- ver1 
//  - ver2
//result
//	- 0   ver1 = ver2
//  - 1   ver1 > ver2
//  - -1  ver1 < ver2
function VersionCompare(ver1,ver2) export
	ver1arr = StringSplit(ver1,".",false);
	ver2arr = StringSplit(ver2,".",false);
	if ver1arr.Количество() <> 3 then
		raise "Арнумент 1 не того формату ver1=" + ver1 + " шаблон 0.0.0";
	endif;	
	if ver1arr.Количество() <> 3 then
		raise "Арнумент 2 не того формату ver2=" + ver1 + " шаблон 0.0.0";
	endif;	
	for i=0 to 2 do
		r = DigitStrCompare(ver1arr[i],ver2arr[i]);
		if r <> 0 then
			return r;
		endif;
	enddo;
	return 0;
endfunction
function GetEmptyUUID() export
	return new UUID("00000000-0000-0000-0000-000000000000");
endfunction
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

function ItemOrDefault(items,itemName,default) export
	return ValueOrDefault(items[itemName],default);	
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
function DateAddDay(value,count = 1) export
	return value + count*86400;
endfunction

function DateAddHour(value,count = 1) export
	return value + count*3600;
endfunction	

function DateAddMinute(value,count = 1) export
	return value + count*60;
endfunction	

function StringStartWith(value,searchString) export
	return StrFind(value,searchString)=1;
endfunction

function StringSplit(value,delimiter=";",includeEmpty=true) export
	
	if StrLen(delimiter) <> 1 then
		raise "Роздільник має бути тільки 1 символ.";
	endif;	
	
	result = new array;
	position = 1;
	success = true;
	while success do
		nextPosition =  StrFind(value,delimiter,position);
		if nextPosition = 0 then
			success = false;
			continue;
		endif;
		count =  nextPosition - position;
		if count = 0 then
			if includeEmpty then
				result.Add("");
			endif;	
			position = position + 1;
			continue;
		endif;
		result.Add(Mid(value,position,count));
		position = position + count +1;
	enddo;
	return result;
endfunction	

#endregion

#region ExchangeConfig

function GetConfigValue(key) export
	reg = InformationRegisters.SabatexIExchangeConfig.Get(new structure("Key",key));
	return reg.Value;	
endfunction

procedure SetConfigValue(Key,Value) export
	reg = InformationRegisters.SabatexIExchangeConfig.CreateRecordManager();
	reg.Key = Key;
	reg.Value  = Value;
	reg.Write(true);
endprocedure	


// Зчитуэмо конфігурацію нода із константи
// result: structure node config
function GetNodeConfig() export
	result = new structure;
	result.Insert("clientId",ValueOrDefault(GetConfigValue("clientId"),""));
	result.Insert("https",ValueOrDefault(GetConfigValue("https"),true));
	result.Insert("Host",ValueOrDefault(GetConfigValue("Host"),"sabatex.francecentral.cloudapp.azure.com"));
	result.Insert("Port",ValueOrDefault(GetConfigValue("Port"),443));
	result.Insert("password",ValueOrDefault(GetConfigValue("password"),""));
	return result;
endfunction
procedure SetNodeConfig(nodeConfig) export
	SetConfigValue("clientId",ValueOrDefault(nodeConfig["clientId"],""));
	SetConfigValue("https",ValueOrDefault(nodeConfig["https"],true));
	SetConfigValue("Host",ValueOrDefault(nodeConfig["Host"],"sabatex.francecentral.cloudapp.azure.com"));
	SetConfigValue("Port",ValueOrDefault(nodeConfig["Port"],443));
	SetConfigValue("password",ValueOrDefault(nodeConfig["password"],""));
	SetConfigValue("ObjectDifferNames",ValueOrDefault(nodeConfig["ObjectDifferNames"],"{}"));
endprocedure

function GetDestinationNodes()
		Query = new Query;
		Query.Text = 
			"SELECT
			|	sabatexNodeConfig.NodeName AS NodeName,
			|	sabatexNodeConfig.destinationId AS destinationId,
			|	sabatexNodeConfig.isActive AS isActive,
			|	sabatexNodeConfig.Take AS Take,
			|	sabatexNodeConfig.LogLevel AS LogLevel,
			|	sabatexNodeConfig.updateCatalogs AS updateCatalogs,
			|	sabatexNodeConfig.incomingParser AS incomingParser,
			|	sabatexNodeConfig.useObjectCashe AS useObjectCashe,
			|	sabatexNodeConfig.IsQueryEnable AS IsQueryEnable,
			|	sabatexNodeConfig.ObjectDifferNames AS ObjectDifferNames
			|FROM
			|	InformationRegister.sabatexNodeConfig AS sabatexNodeConfig
			|WHERE
			|	sabatexNodeConfig.isActive = TRUE";
	
			return Query.Execute().Выгрузить();
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

// отримати конфігурацію для обміну даними
//  - destinationNode список налаштувань для віддаленого вузла обміну
function GetConfig(destinationNode)
	config = new structure;
	config.Insert("nodeConfig",GetNodeConfig());
	config.Insert("accessToken",GetAccessToken());
	config.Insert("nodeName",destinationNode.nodeName);
	config.Insert("destinationId",new UUID(destinationNode.destinationId));
	config.Insert("Take",destinationNode.Take);
	config.Insert("LogLevel",destinationNode.LogLevel);
	config.Insert("updateCatalogs",destinationNode.updateCatalogs);
	config.Insert("incomingParser",destinationNode.incomingParser);		
	config.Insert("useObjectCashe",destinationNode.useObjectCashe);
	config.Insert("QueryParser","SabatexExchange.defaultQueryParser");
	config.Insert("IsQueryEnable",destinationNode.IsQueryEnable);
		
		//if config.Host = "" then
		//	raise "В регістрі відомостей sabatexNodeConfig не заповнено поле Host";	
		//endif;	
		//
		//	
		//if nodeConfig.Take <=0 or nodeConfig.Take >500 then
		//	config.Take = 50;	
		//endif;

    
	config.Insert("MapDifferObjects",new structure);
	config.MapDifferObjects.Insert("Forward",new map);
	config.MapDifferObjects.Insert("Backward",new map);
	try
		dfNames = Deserialize(destinationNode.ObjectDifferNames);
		for each v in dfNames do
			config.MapDifferObjects.Forward.Insert(v.Key,v.Value);
	        config.MapDifferObjects.Backward.Insert(v.Value,v.Key);
		enddo;
	except
		raise "Помилка зчитування параметру обміну JSON  Список обэктів з різними назвами";
	endtry;
	
	
	config.Insert("ExportObjects",0);
	config.Insert("ImportObjects",0);
	config.Insert("MissObjects",0);
	config.Insert("QueriedObjects",0);
	config.Insert("Log","");
		
	table = new ValueTable;
	table.Columns.Add("objectType");
	table.Columns.Add("objectId");
	config.Insert("queryList",table);

	//except
	//	raise "Помилка ініціювання налаштувань обміну для нода "+nodeConfig.nodeName+" з помилкою " + ОписаниеОшибки();	
	//endtry;
	
	return config;
endfunction
function GetConfigByNodeName(nodeName) export
	filter = new structure("NodeName",nodename);
	reg = РегистрыСведений.sabatexNodeConfig.Получить(filter);
	reg.Insert("NodeName",nodename);
	return GetConfig(reg);
endfunction	
	
#endregion

#region JSON
function Serialize(object) export
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
function Deserialize(txt,datefields = undefined)  export
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

#region Logged
procedure Logged(conf,level,sourceName,message)
	try
		if level <= conf.LogLevel then
			logLevel = УровеньЖурналаРегистрации.Примечание;
			if level = 0 then
				logLevel = УровеньЖурналаРегистрации.Ошибка;
			ИначеЕсли level=1 then
				logLevel = УровеньЖурналаРегистрации.Предупреждение;
			ИначеЕсли level=2 then
				logLevel = УровеньЖурналаРегистрации.Информация;
			endif;	
			
			ЗаписьЖурналаРегистрации("SabatexExchange",logLevel,sourceName,
			,
			message);
			conf.Log = conf.Log + message + Символы.ПС;
		endif;
	except
		
	endtry;
endprocedure
procedure LogError(conf,message) export
	Logged(conf,0,"",message);		
endprocedure	
procedure LogWarning(conf,message) export
	Logged(conf,1,"",message);		
endprocedure
procedure LogInformation(conf,message) export
	Logged(conf,2,"",message);		
endprocedure
procedure LogNote(conf,message) export
	Logged(conf,3,"",message);		
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
// Cteate HTTP Request 
// params:
//    url - complete url for service
//    headers - map headers for request
//    queries - url queries  
function CreateHTTPRequest(url,headers,queries=null)
	request = new HTTPRequest(BuildUrl(url,queries));
	for each header in headers do
		request.Headers.Insert(header.Ключ, header.Значение);
	enddo;
	return request;
endfunction	



#region Autenfication

function GetAccessToken()
	result = new Structure;
	result.Insert("access_token",ValueOrDefault(GetConfigValue("access_token"),"undefined"));
	result.Insert("token_type",ValueOrDefault(GetConfigValue("token_type"),""));
	result.Insert("refresh_token",ValueOrDefault(GetConfigValue("refresh_token"),"undefined"));
	result.Insert("expires_in",ValueOrDefault(GetConfigValue("expires_in"),CurrentDate()));
	return result;
endfunction

procedure SetAccessToken(conf,accessToken)
	expires_in = CurrentDate()+ Number(accessToken["expires_in"]);
	SetConfigValue("access_token",ValueOrDefault(accessToken["access_token"],"undefined"));
	SetConfigValue("token_type",ValueOrDefault(accessToken["token_type"],""));
	SetConfigValue("refresh_token",ValueOrDefault(accessToken["refresh_token"],"undefined"));
	SetConfigValue("expires_in",ValueOrDefault(expires_in,CurrentDate()));
	conf["accessToken"]=GetAccessToken();
endprocedure
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
		SetAccessToken(conf,token);
		return true;
	except
	endtry;	
	
	// 2. спроба оновити токен за допомогою login
	try
		token = Login(conf);
		SetAccessToken(conf,token);
		return true;
	except
	endtry;	
	return false;
endfunction

#endregion



#region objects
// download objects from server bay sender nodeName
function GetObjectsExchange(conf,first=true) export
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
procedure DeleteExchangeObject(conf,id,first=true) export
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
procedure POSTExchangeObject(conf, objectType, objectId, dateStamp,textJSON,first=true) export
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

#endregion

#region quries
// get queried objects
function GetQueriedObjects(conf,first=true) export
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
procedure DeleteQueriesObject(conf,id,first=true) export
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
procedure PostQueries(conf,ObjectId,ObjectType,first=true) export
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

#endregion

#endregion
#region GetObjects
function checkComplexType(conf,complexValue,objectId,objectType)
	try
		objectId = complexValue.Get("#value");
		complexType = complexValue.Get("#type");
		pos = Найти(complexType,".");
		subType = Сред(complexType,1,pos);
		typeName = Сред(complexType,pos+1);
		if subType = "jcfg:CatalogRef." then
			objectType = GetLocalObjectName(conf,"справочник."+lower(typeName));
			return true;
		elsif subType = "jcfg:DocumentRef." then
			objectType = GetLocalObjectName(conf,"документ."+lower(typeName));
			return  true;
		else
			LogError(conf,"Невідомий тип " + complexType);
			return false;
		endif;
	except
		return false;
	endtry;
endfunction	

function GetObjectManager(conf,objectType)
	pos = Найти(objectType,".");
	if pos = -1 then
		LogError(conf,"Задано неправильний тип objectType=" + objectType);
		return undefined;
	endif;	
	subType = Сред(objectType,1,pos-1);
	typeName = Сред(objectType,pos+1);
	
	if lower(subType) = "справочник" then
		return Catalogs[typeName];
	elsif lower(subType) = "документ" then
		return Documents[typeName];;
	else
		LogError(conf,"Задано неправильний тип objectType=" + objectType);
		return undefined;
	endif;
endfunction
procedure AddToMapDifferObjects(conf,localName,destinationName) export
	if not conf.Property("MapDifferObjects") then
		conf.Insert("MapDifferObjects",new structure);
		conf.MapDifferObjects.Insert("Forward",new map);
		conf.MapDifferObjects.Insert("Backward",new map);
	endif;	
	conf.MapDifferObjects.Forward.Insert(lower(localName),lower(destinationName));
	conf.MapDifferObjects.Backward.Insert(lower(destinationName),lower(localName));
endprocedure
function GetDestinationObjectName(conf,localObjectName)
	result = conf.MapDifferObjects.Forward[lower(localObjectName)];
	if result = undefined then
		return localObjectName;
	else
		return result;
	endif;
endfunction
function GetLocalObjectName(conf,destinationObjectName)
	result = conf.MapDifferObjects.Backward[lower(destinationObjectName)];
	if result = undefined then
		return destinationObjectName;
	else
		return result;
	endif;
endfunction
// Get object by id
// conf  - config struct (include sender node
// objectId - string 
// objectType - empty for complex type, string справочник.номнклатура,...
// success - bool (set false if error)
// attributeName - if defined object find by attribute
function GetObjectRef(conf,знач objectId,знач objectType, success,attributeName=undefined) export
	// complex type
	if typeof(objectId) = type("Map") then
		complexObjectId = "";
		complexObjectType = "";
		if checkComplexType(conf,objectId,complexObjectId,complexObjectType) then
			return GetObjectRef(conf,complexObjectId,complexObjectType,success);
		endif;
		
		objectManager = GetObjectManager(conf,objectType);
		if objectManager <> undefined then
			return objectManager.EmptyRef();
		endif;
		success = false;
		return undefined;
	endif;	
	
	objectManager = GetObjectManager(conf,objectType);
	if objectManager = undefined then
		return undefined;
	endif;
	
	if IsEmptyUUID(ObjectId) then
		return objectManager.EmptyRef();	
	endif;
	
	if attributeName = undefined then
		result = objectManager.GetRef(new UUID(objectId));
	else
		result = objectManager.FindByAttribute(attributeName,new UUID(objectId));
	endif;	

	if result.GetObject() = undefined then
		destinationFullName = GetDestinationObjectName(conf, objectType);
		
		success = false;
		AddQueryForExchange(conf,destinationFullName,objectId);
		return objectManager.EmptyRef();
	endif;
	return result;
endfunction	
#endregion

#region Helpers
function GetSameEnumValue(conf,enumName,enumValueName,success) export
	try
		x= Enums[enumName];
	except
		success = false;
		LogError(conf,"Помилка отримання перерахування конфігурації - "+enumName);
		return Enums.AllRefsType();
	endtry;
	if enumValueName = "" then
		return Enums.AllRefsType();
	endif;	
	try
		return x[enumValueName];
	except
		success = false;
		LogError(conf,"Помилка отримання зжначення - "+enumValueName+" - з перерахування конфігурації - "+enumName);
		return x.EmptyRef();
		
	endtry;
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
	reg.object = objectRef;
	reg.NodeName  = nodeName;
	reg.dateStamp = CurrentDate();
	reg.Write(true);
endprocedure	
// Delete object from cashe
// params:
//	destinationId - 
//  dateStamp     - 
procedure DeleteObjectForExchange(Id,destinationNodeName)
	reg = InformationRegisters.sabatexExchangeObject.CreateRecordManager();
	reg.object = Id;
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
				LogError(conf,"Do not load objectId=" + objectId + ";objectType="+ objectType + " Error Message: " + ОписаниеОшибки());
				RollbackTransaction();
			endtry;
		enddo;
endprocedure

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

procedure PostObjects(conf)
	// post queries
	conf.queryList.GroupBy("objectType,objectId");
	for each query in conf.queryList do 
		PostQueries(conf,query.objectId,query.objectType);
	enddo;	
	
	Query = Новый Запрос;
	Query.Текст = 
		"ВЫБРАТЬ ПЕРВЫЕ 200
		|	sabatexExchangeObject.object КАК object,
		|	sabatexExchangeObject.dateStamp КАК dateStamp
		|ИЗ
		|	РегистрСведений.sabatexExchangeObject КАК sabatexExchangeObject
		|ГДЕ
		|	sabatexExchangeObject.NodeName = &nodeName";
	
	Query.SetParameter("nodeName",conf.nodeName);
	РезультатЗапроса = Query.Выполнить();
	
	items = РезультатЗапроса.Выбрать();
	
	while items.Next() do
		try
			
			ref	= items.object.Ref;
			objectType = ref.Metadata().FullName();
			objectId = ref.UUID();
			objectJSON =Serialize(ref.GetObject());
			POSTExchangeObject(conf,objectType,objectId,items.dateStamp,objectJSON);
			DeleteObjectForExchange(items.object,conf.nodeName);
		except
			
		endtry;
	enddo;
endprocedure	
#endregion

#region AnalizeObjects
// parse incoming object and return 
// true - object is Ok
// false - missed object
// unresolved - array structure queried objects
procedure IncomingDefaultParser(conf,obj,success)
	success = false;
	LogError(conf,"Не задано IncomingParser!");	
endprocedure	

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
procedure AnalizeUnresolvedObjects(conf)
	try
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
			objectId = "";
			objectType = "";
			
			НачатьТранзакцию();
			try
				objectId = SelectionDetailRecords["objectId"];
				objectType = SelectionDetailRecords["objectType"];
				
				success = true;
				conf.Log = "";
				Execute(conf.IncomingParser+"(conf,SelectionDetailRecords,success)");
				
				if success then
					DeleteUnresolvedObject(conf,SelectionDetailRecords);
				else
					LevelUpUnresolvedObject(conf,SelectionDetailRecords);
				endif;
				
			except
				LogError(conf,"Do not load objectId=" + objectId + ";objectType="+ objectType + " Error Message: " + ОписаниеОшибки());
				ОтменитьТранзакцию();
				continue;
			endtry;
			ЗафиксироватьТранзакцию();
		enddo;
	except
		LogError(conf,"Загальна помилка AnalizeUnresolvedObjects для клієнта -"+ string(conf.clientId) + " - " + ОписаниеОшибки());
	endtry;
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
		LogError(conf,"Помилка отримання обєкта документа "+objectName + " з ID="+objectId);
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
		LogError(conf,"Помилка отримання обєкта Довідника "+objectName + " з ID="+objectId);
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
		LogInformation(conf,""+objectType + " з Id=" + objectId+" в черзі чекає обробки.");
		// miss unresolved object
		return;
	КонецЦикла;
	
	query = conf.queryList.Add();
	query.objectType = objectType;
	query.objectId = objectId;
	LogInformation(conf,"Відправлено запит на отримання "+ objectType + " з Id=" + objectId);
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
						LogError(conf,"Помилка виконання розширеного запиту до бази:"+ОписаниеОшибки() );
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


// Розпочати процесс обміну
// params:
// 		nodeName - назва нода обміну в регістрі sabatexNodeConfig
//      incomingParser - метод який прододить аналіз вхідних обєктів
//      queryParser    - метод який обробляє вхідні запити до облікової системи 
procedure ExchangeProcess() export
	try
	    destinationNodes = GetDestinationNodes();
		for each destinationNode in destinationNodes do
			start = CurrentDate();
			
			try  
				conf = GetConfig(destinationNode);
				
				// ansver the query and set to queue
				DoQueriedObjects(conf);
				
				// read  input objects
				ReciveObjects(conf);
				
				AnalizeUnresolvedObjects(conf);
				
				PostObjects(conf);
				
								
			except
				LogError(conf,string(conf.nodeConfig.clientId) + " - " + ОписаниеОшибки());
			endtry;
			end = ТекущаяДата();
			log = "The exchange with "+conf.nodeName + " process result:" + Chars.LF;
			log = log + "Import objects - " + conf.ImportObjects + Chars.LF;
			log = log + "Missed objects - " + conf.MissObjects + Chars.LF;
			log = log + "Export objects - " +conf.ExportObjects  +Chars.LF;
			log = log+ "Duration process = " + string(end - start)+ " сек.";
			LogNote(conf,log); 
		enddo;
		
	except
		ЗаписьЖурналаРегистрации("SabatexExchange",
		УровеньЖурналаРегистрации.Ошибка,
		,
		,
		"Аварійне завершення обміну з помилкою:"+ОписаниеОшибки());
	endtry;
endprocedure

#endregion


