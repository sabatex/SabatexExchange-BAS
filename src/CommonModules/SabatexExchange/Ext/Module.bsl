// Copyright (c) 2021-2025 by Serhiy Lakas
// https://sabatex.github.io


#region Common_Methods
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

// Функция - Get empty UUID as string
// 
// Возвращаемое значение:
//   -   UUID в вигляды строки  00000000-0000-0000-0000-000000000000
//
function GetEmptyUUIDAsString() export
	return "00000000-0000-0000-0000-000000000000";
endfunction	

// Функция - Get empty UUID
// 
// Возвращаемое значение:
//   -  new UUID("00000000-0000-0000-0000-000000000000")
//
function GetEmptyUUID() export
	return new UUID(GetEmptyUUIDAsString());
endfunction


// Перевірка на пустий UUID
//  - value (UUID or string)
function IsEmptyUUID(value) export
	if TypeOf(value) = type("UUID") then
		return value = GetEmptyUUID();
	elsif TypeOf(value) = type("string") then
		try
			uuidValue = new UUID(value);
		except
			raise "Помилка приведення значення ["+ value+"] до UUID";
		endtry;
		
		return uuidValue = GetEmptyUUID();
	else
		raise("Неправильний тип value");
	endif;	
endfunction	


// Функция - Message header from url
//
// Параметры:
//  url	 - string	 -  url  e1cib/data/Справочник.Номенклатура?ref=9fb542010aa6000211ed9f50262b40a8
// 
// Возвращаемое значение:
//  structure - type,id
//
function GetMessageHeaderFromUrl(url) export
	result = new structure("type,id");
	if StrStartsWith(url,"e1cib/data") then
		index = StrFind(url,"?ref=");
		if index <> 0 then
			result.type = Mid(url,12,index-12);
			result.id = Mid(url,index+29,8)+"-"+Mid(url,index+25,4)+"-"+Mid(url,index+21,4)+"-"+Mid(url,index+5,4)+"-"+Mid(url,index+9,12);
		endif;
	endif;
	return result
endfunction

// Функция - Get url from message header
//
// Параметры:
//  messageHeader	 - structure or Map	 - (type string,id string)
// 
// Возвращаемое значение:
// string  -  url  e1cib/data/Справочник.Номенклатура?ref=9fb542010aa6000211ed9f50262b40a8
//

function GetUrlFromMessageHeader(messageHeader) export
	id= messageHeader["id"];
	return "e1cib/data/"+messageHeader["type"]+"?ref="+Mid(id,20,4)+Mid(id,25,12)+Mid(id,15,4)+Mid(id,10,4)+Mid(id,1,8);
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

#region JSON
// Функция - Sabatex JSONSerialize
//
// Параметры:
//  object	 - 	 - 
// 
// Возвращаемое значение:
//   -  Серіалізований в строку обєкт 
//
function Serialize(object) export
	jsonWriter = new JSONWriter;
	jsonParams = new JSONWriterSettings(JSONLineBreak.None,,,,,,true);
	jsonWriter.SetString(jsonParams);
	if TypeOf(object) = Type("Structure")or TypeOf(object) = Type("Array")  then
		WriteJSON(jsonWriter,object);
	else
		XDTOSerializer.WriteJSON(jsonWriter,object,XMLTypeAssignment.Implicit);
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
function Deserialize(txt,datefields = undefined) export
	if datefields = undefined then
		datefields = new array;
	endif;	
	
	jsonReader=Новый JSONReader;	
	jsonReader.SetString(txt);
	result = ReadJSON(jsonReader,true,datefields);
	if typeof(result) = type("Map") then
		objectXDTO = result.Get("#value");
		if objectXDTO <> undefined then
			SabatexExchangeId  = result["SabatexExchangeId"];
			if SabatexExchangeId <> undefined then
				objectXDTO["SabatexExchangeId"] = SabatexExchangeId;
			endif;	
			return objectXDTO;
		endif;
	endif;
	return result;
endfunction	
#endregion

#region Logged
// Процедура - System log
//
// Параметры:
//  logLevel - 	 - 
//  message	 - 	 - 
//
procedure SystemLog(logLevel,message)
	WriteLogEvent("SabatexExchange",logLevel,,,message);
endprocedure	
// Процедура - System log error
//
// Параметры:
//  message	 - 	 - 
//
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
// Функция - Sabatex log error
//
// Параметры:
//  conf	 - structure - 
//  level 	 - integer   - рівень логування, Log - додаэться поточний лог 
//  message	 - string	 - 
//  
//
// Возвращаемое значение:
//   - 
//
function Error(conf,message,result=undefined) export
	conf.success = false;
	Logged(conf,0,"",message,false);
	return result;
endfunction

// Функция - Error journaled
//
// Параметры:
//  conf	 - 	 - 
//  message	 - 	 - 
//  result	 - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function ErrorJournaled(conf,message,result = undefined) export
	conf.success = false;
	Logged(conf,0,"",message,true);		
	return result;	
endfunction	
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

#region WEB_Api

function CreateHTTPSConnection(conf)
	nodeConfig = conf.nodeConfig;
	ssl = ?(nodeConfig.https,new OpenSSLSecureConnection( undefined, undefined ),undefined);
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
// bearer accessToken 
function Login(conf)
	if conf.NodeType = Enums.SabatexExchangeNodeType.USAP then
		return LoginUSAP(conf);
	endif;
	
	connection = CreateHTTPSConnection(conf);
	request = new HTTPRequest(BuildUrl("api/v1/login"));
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

// Функция - Login USAP
//
// Параметры:
//  conf - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function LoginUSAP(conf)
	connection = CreateHTTPSConnection(conf);
	request = new HTTPRequest(BuildUrl("login"));
	request.Headers.Insert("Content-Type","application/json; charset=utf-8");
	jsonString = Serialize(new structure("cid,login,password",conf.nodeConfig.cid,conf.nodeConfig.login,conf.nodeConfig.password));
	request.SetBodyFromString(jsonString,"UTF-8",ByteOrderMarkUse.DontUse);
	response = connection.Post(request);
	
	if response.StatusCode <> 200 then
		raise "Login error with StatusCode="+ response.StatusCode;
	endif;
	
	cookie = response.Headers["Set-Cookie"];
	if not ValueIsFilled(cookie) then 
		raise "Login error with cookie not found Responce:"+ response.StatusCode;
	endif;
    return new structure("cookie",cookie);
endfunction



// отримати новий токен за допомогою  refresh_token
function RefreshToken(conf)
	connection = CreateHTTPSConnection(conf);
	request = new HTTPRequest(BuildUrl("api/v1/refresh_token"));
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
		SabatexExchange.SetAccessToken(conf,token);
		return true;
	except
	endtry;	
	return false;
endfunction

// download objects from server bay sender nodeName
function GetObjectsExchange(conf,first=true) export
	if conf.NodeType = Enums.SabatexExchangeNodeType.USAP then
		return GetObjectsUSAP(conf,first);
	endif;
	
	connection = CreateHTTPSConnection(conf); 
	if conf.TakeOneMessageAtATime then
		take = 1;
	else
		take =conf.take;
	endif;	
	request = new HTTPRequest(BuildUrl("api/v1/objects",new structure("take",XMLString(take))));
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
		return Deserialize(response.GetBodyAsString());	
	except
		raise "GetObjectsExchange error request with error:"+ОписаниеОшибки();
	endtry;	
endfunction

// download objects from server bay sender nodeName
function GetObjectsUSAP(conf,first=true) export
	connection = CreateHTTPSConnection(conf); 
	
	if conf.TakeOneMessageAtATime then
		take = 1;
	else
		take =conf.take;
	endif;
	
	packetInfo = SabatexExchange.GetStoredValue("USAP_SesionInfo");
	cookie = packetInfo["cookie"]; 
	if cookie = undefined then
		result = LoginUSAP(conf);
		cookie = result.cookie;
	    packetInfo["cookie"] = cookie;
	endif;
	
	
		
	request = new HTTPRequest(BuildUrl("/externaldb/readdata",new structure("take",take)));
	request.Headers.Insert("accept","*/*");
	request.Headers.Insert("cookie",cookie);
	request.Headers.Insert("Content-Type","application/json; charset=utf-8");
	

	data = new structure;
	data.Insert("senderName",conf.nodeConfig.login); //Узел.Пользователь
	data.Insert("sendVersion",SabatexExchange.ValueOrDefault(packetInfo["sendVersion"],0));//Узел.НомерОтправленного
	data.Insert("lastDownload",SabatexExchange.ValueOrDefault(packetInfo["lastDownload"],Date("19000101")));               //Узел.ДатаПоследнегоПолученогоПакета
	data.Insert("receiveName",conf.NodeName);//Узел.ИмяПубликации  що ставити ? назва 
	data.Insert("receiveVersion",SabatexExchange.ValueOrDefault(packetInfo["receiveVersion"],-1)); //   ?(Узел.НомерПринятого=0,-1,Узел.НомерПринятого));
	
	jsonString = Serialize(data);
    request.SetBodyFromString(jsonString,"UTF-8",ИспользованиеByteOrderMark.НеИспользовать);

	
	
	try
		response = connection.Post(request);
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
		return Deserialize(response.GetBodyAsString());	
	except
		raise "GetObjectsExchange error request with error:"+ОписаниеОшибки();
	endtry;	
endfunction


// Процедура - Delete exchange object
//
// Параметры:
//  conf	 - 	 - 
//  id		 - 	 - 
//  first	 - 	 - 
//
procedure DeleteExchangeObject(conf,id,first=true) export
	connection = CreateHTTPSConnection(conf);
	request = new HTTPRequest(BuildUrl("/api/v1/objects/"+XMLString(id)));
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
procedure POSTExchangeMessage(conf, messageHeader, dateStamp,textJSON,first=true) export
	connection = CreateHTTPSConnection(conf);
	request = new HTTPRequest(BuildUrl("api/v1/objects"));
	request.Headers.Insert("accept","*/*");
	request.Headers.Insert("Content-Type","application/json; charset=utf-8");
	request.Headers.Insert("clientId",XMLСтрока(conf.nodeConfig.clientId));
	request.Headers.Insert("apiToken",XMLСтрока(conf.accessToken.access_token));
	request.Headers.Insert("destinationId",XMLСтрока(conf.destinationId));
	try
		jsonString = Serialize(new structure("messageHeader,dateStamp,message",messageHeader,dateStamp,textJSON));
		request.SetBodyFromString(jsonString,"UTF-8",ИспользованиеByteOrderMark.НеИспользовать);
		response = connection.Post(request);
		if response.StatusCode = 401 then
			if first then
				if updateToken(conf) then
					POSTExchangeMessage(conf,messageHeader,dateStamp,textJSON,false);
					return;
				endif;
			endif;
		endif;

		if response.StatusCode <> 200 then
			raise "Помилка POST /api/v0/objects  with StatusCode: "+ response.StatusCode;	
		endif;
	except
		raise "Помилка ідентифікації на сервері! Error:"+ОписаниеОшибки();
	endtry;	
endprocedure	

#endregion


#region Check_Object
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

// Функция - Is chart of accounts
//
// Параметры:
//  objectType	 - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function IsChartOfAccounts(objectType) export
	return StringStartWith(upper(objectType),Upper("ПланСчетов"));	
endfunction

// Функция - Is chart of characteristic types
//
// Параметры:
//  objectType	 - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function IsChartOfCharacteristicTypes(objectType) export
	return StringStartWith(upper(objectType),Upper("ПланВидовХарактеристик"));	
endfunction

// Функция - Is exchange plan
//
// Параметры:
//  objectType	 - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function IsExchangePlan(objectType) export
	return StringStartWith(upper(objectType),Upper("ПланОбмена"));
endfunction

// Функция - Is information register
//
// Параметры:
//  objectType	 - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function IsInformationRegister(objectType) export
	return StringStartWith(upper(objectType),Upper("РегистрСведений"));
endfunction

// Функция - Is structure
//
// Параметры:
//  objectType	 - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function IsStructure(objectType) export
	return StringStartWith(upper(objectType),Upper("Structure"));
endfunction

// Функция - Check complex type
//
// Параметры:
//  conf		 - 	 - 
//  complexValue - 	 - 
//  objectId	 - 	 - 
//  objectType	 - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function checkComplexType(conf,complexValue,objectId,objectType) export
	try
		objectId = complexValue.Get("#value");
		complexType = complexValue.Get("#type");
		pos = Найти(complexType,".");
		//subType = Сред(complexType,1,pos);
		typeName = Сред(complexType,pos+1);
		if StrStartsWith(complexType,"jcfg:CatalogRef") then
			objectType = GetInternalObjectType(conf,"справочник."+lower(typeName));
			return true;
		elsif StrStartsWith(complexType,"jcfg:DocumentRef") then
			objectType = GetInternalObjectType(conf,"документ."+lower(typeName));
			return  true;
		elsif StrStartsWith(complexType,"jcfg:EnumRef") then	
			objectType = GetInternalObjectType(conf,"перечисление."+lower(typeName));
			return  true;  
		elsif StrStartsWith(complexType,"jcfg:ChartOfCharacteristicTypesRef.") then	
			objectType = GetInternalObjectType(conf,"ПланВидовХарактеристик."+lower(typeName));
			return  true;
 		elsif StrStartsWith(complexType,"jxs:string") then	
			objectType = Type("string");
			return  true;
		elsif StrStartsWith(complexType,"jxs:boolean") then	
			objectType = Type("boolean");
			return  true;

		else
			 Error(conf,"Невідомий тип " + complexType);
			return false;
		endif;
	except
		Error(conf,"Перевірка комплексного типу " + complexType+ " " + ErrorDescription());
		return false;
	endtry;
endfunction	
// Функция - Is folder
//
// Параметры:
//  object	 - ref	 - любий обэкт
// 
// Возвращаемое значение:
//   - 
//
function IsFolder(object)
	try
		return object.IsFolder;
	except
		return false;
	endtry	
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

  
 #region Config

// Функция - Отримати режим обміну Авто 
// 
// Возвращаемое значение:
//  enum - Enums.SabatexExchangeMode.Auto
//
 function GetSabatexExchangeModeAuto() export
	 return Enums.SabatexExchangeMode.Auto;
endfunction	 
 
 
 
function GetStoredValue(key) export
	reg = InformationRegisters.SabatexExchangeConfig.Get(new structure("Key",key));
		
	return Deserialize(?(reg.Value="","{}",reg.Value));
endfunction
	
procedure SetStoredValue(Key,Value) export
	reg = InformationRegisters.SabatexExchangeConfig.CreateRecordManager();
	reg.Key = Key;
	reg.Value  = Serialize(Value);
	reg.Write(true);
endprocedure	

// Функция - Get node config
// 
// Возвращаемое значение:
//   - 
//
function GetHostConfig(nodeType,nodeName="") export
	result = new structure;
	if nodeType = Enums.SabatexExchangeNodeType.Sabatex then
		reg = InformationRegisters.SabatexExchangeConfig.Get(new structure("Key","HostConfig"));
		rootNode =  Deserialize(ValueOrDefault(reg.Value,"{}")); 
		result.Insert("clientId",ValueOrDefault(rootNode["clientId"],""));
		result.Insert("https",ValueOrDefault(rootNode["https"],true));
		result.Insert("Host",ValueOrDefault(rootNode["Host"],"sabatex.francecentral.cloudapp.azure.com"));
		result.Insert("Port",ValueOrDefault(rootNode["Port"],443));
		result.Insert("password",ValueOrDefault(rootNode["password"],""));
	else
		reg = InformationRegisters.SabatexExchangeConfig.Get(new structure("Key","USAP-"+nodeName));
		rootNode =  Deserialize(ValueOrDefault(reg.Value,"{}")); 
		result.Insert("cid",ValueOrDefault(rootNode["cid"],""));
		result.Insert("https",ValueOrDefault(rootNode["https"],true));
		result.Insert("Host",ValueOrDefault(rootNode["Host"],"my.usap.online"));
		result.Insert("Port",443);
		result.Insert("login",ValueOrDefault(rootNode["login"],""));
		result.Insert("password",ValueOrDefault(rootNode["password"],""));
	endif;
	
	return result;
endfunction

procedure SetHostConfig(hostConfig,nodeType,nodeName="") export
	reg = InformationRegisters.SabatexExchangeConfig.CreateRecordManager();
	keyName = ?(nodeType = Enums.SabatexExchangeNodeType.Sabatex,"HostConfig","USAP-"+nodeName);
	reg.Key = keyName;
	reg.Value  = Serialize(hostConfig);;
	reg.Write(true);
endprocedure

//  Get config for destination node
//
// Параметры:
//  destinationNode	 - SelectionDetailRecords - nodeConfigRecord 
// 
// Возвращаемое значение:
//  structure - Config for Node
//
function GetConfig(destinationNode)
	config = new structure("Owner,connection",undefined,undefined);
	config.Insert("nodeName",destinationNode.nodeName);
	config.Insert("NodeType",destinationNode.NodeType);
	config.Insert("nodeConfig",GetHostConfig(destinationNode.NodeType,destinationNode.nodeName));
	config.Insert("accessToken",GetAccessToken());
	config.Insert("Connection",undefined); // current connection to api
	
	try
		config.Insert("destinationId",new UUID(destinationNode.destinationId));
	except
		config.Insert("destinationId",GetEmptyUUID());
	endtry;
	
	config.Insert("Take",destinationNode.Take);
	config.Insert("LogLevel",destinationNode.LogLevel);
	config.Insert("updateCatalogs",destinationNode.updateCatalogs);
	config.Insert("userDefinedModule",destinationNode.userDefinedModule);		
	config.Insert("IsQueryEnable",destinationNode.IsQueryEnable);
	config.Insert("ExchangeMode",destinationNode.ExchangeMode); 
	config.Insert("Send",ValueOrDefault(destinationNode.Send,false));
	config.Insert("Parse",ValueOrDefault(destinationNode.Parse,false));
	config.Insert("TakeOneMessageAtATime",ValueOrDefault(destinationNode.TakeOneMessageAtATime,false));
	config.Insert("UpdateTransacted",ValueOrDefault(destinationNode.UpdateTransacted,0));
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

	
	// support predefined data types
	config.Insert("PredefinedAccepted",true);
	config.Insert("senderDateStamp",undefined);

	
	#endregion
	config.Insert("IdAttributeType",Enums.SabatexExchangeIdAttributeType.UUID);
	


	config.Insert("Log","");
	
	// таблиця обєктів для запиту
	table = new ValueTable;
	table.Columns.Add("objectType");
	table.Columns.Add("objectId");
	config.Insert("queryList",table);

	config.Insert("IsNew",undefined);
	config.Insert("Object",undefined);
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
			|	SabatexExchangeNodeConfig.UpdateTransacted AS UpdateTransacted,
			|	SabatexExchangeNodeConfig.NodeType AS NodeType
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


// Функция - Get active destination nodes
// 
// Возвращаемое значение:
// array node config  -  масив назв активних нодів
//
function GetActiveDestinationNodes() export
		Query = new Query;
		Query.Text = 
			"SELECT
			|	SabatexExchangeNodeConfig.NodeName AS NodeName
			|FROM
			|	InformationRegister.SabatexExchangeNodeConfig AS SabatexExchangeNodeConfig
			|WHERE
			|	SabatexExchangeNodeConfig.isActive = TRUE";
		result = new Array;
			
		return Query.Execute().Unload().UnloadColumn("NodeName");
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

// Функция - Перевірка типу обєкта
//
// Параметры:
//  objectType	 - string	 - тип обєкта Справочник.Номенклатура
// 
// Возвращаемое значение:
//  boolean - true/false
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
		
	result = new Structure("Attributes",New Structure); // Опис визначень для атрибутів обєкта
	result.Insert("Tables",New Structure); // Опис визначень для табличної частини обєкта
	result.Insert("Owner",conf); // власник налаштувань (загальні налаштування->налаштування обэкта->налаштування тч)
	result.Insert("NormalizedObjectType",normalizedObjectType); //справочник_номенклатура
	result.Insert("ExternalObjectDescriptor",CreateExternalObjectDescriptor(conf,ExternalObjectType,,result)); // описувач зовнішніх властивостей обєкта
	result.Insert("ObjectType",ObjectType); // тип обєкта в нормальному стані
	result.Insert("UseIdAttribute",false);  // використання зовнішнього ID
	result.Insert("UnInserted",false);   // true - object support only update
	result.Insert("Transact",undefined); // true/false - tansact document, undefined - взяти з owner 
	result.Insert("UpdateTransacted",undefined);   //true/false - update transacted document, undefined - взяти з owner
	result.Insert("ignoreMissedObject",undefined); // true/false - tansact document, undefined - взяти з owner 
	result.Insert("writeUnresolved",undefined);    // take global conf.writeUnresolved
	result.Insert("IsUpdated", undefined);         // обєкт можна оновлювати
	result.Insert("OnAfterSave",undefined);        // метод який викликається після запису 
	result.Insert("OnBeforeSave",undefined);       // метод який викликається перед записом
	result.Insert("EnumResolverProc",undefined);
	result.Insert("Ignore",ignore);                // ігнорувати (не обробляти) дані обєкти при поступленні 
	result.Insert("LookObjectProc",undefined);     // Метод користувача для пошуку обєкта при невдалій спробі знайти по Id
    result.Insert("IdAttributeType",undefined);    // тип id  
	result.Insert("PredefinedAccepted",Undefined); // 
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
		objectDescriptor = CreateObjectDescriptor(Conf,"Перечисление."+value);
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
//  procName		 - string	 - Назва процедури procedure(conf,source,destination,attr)
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
// Процедура - Add attribute ignored
//
// Параметры:
//  objectDescriptor - structure	 - 
//  attrName		 - string	 - Назви атрибутів роздвлених комою які будуть ігноровані при імпорті
//
procedure AddAttributeIgnored(objectDescriptor,attrName) export
	for each attr in StrSplit(attrName,",") do
		AddAttributeProperty(objectDescriptor,attr,true);
	enddo;
endprocedure
// Процедура - Add attribute default
//
// Параметры:
//  objectDescriptor - structure	 - (object or table descriptor)
//  attrName		 - string	 -  attribute name
//  default			 - any	 -  any default value
//
procedure AddAttributeDefault(objectDescriptor,attrName,default) export
	AddAttributeProperty(objectDescriptor,attrName,,default);	
endprocedure

// Процедура - Add attribute proc
//
// Параметры:
//  objectDescriptor - structure	 - (object or table descriptor) 
//  attrName		 - string	 -  attribute name
//  procName		 - string	 -  procedure(structure conf,map source,object destination,string attrName)
//   
procedure AddAttributeProc(objectDescriptor,attrName,procName) export
	AddAttributeProperty(objectDescriptor,attrName,,,,procName);	
endprocedure




// Функция - Add table property
//
// Параметры:
//  objectConf		 - 	 - 
//  attrName		 - 	 - 
//  Ignore			 - 	 - 
//  destinationName	 - 	 - 
//  procName		 - string - procedure procName(conf,source,destination,table)
//  postParser		 - string - procedure postParser(conf,localobject,line,row)
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
//  objectDescriptor - conf	     -  контекст описувача обэкта створеного CreateObjectDescriptor(..)
//  transact		 - boolean	 - true  Обэкт автоматично проводиься
//  updateTransacted - Number    - різниця в годинах між поточною датою та датою документа на проміжку якої дозволена модифікація документа,
//                                 по замовчуванню undefined - без обмежень
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


// Процедура - Configure parser actions
//
// Параметры:
//  conf			 - 	 - 
//  objectDescriptor - 	 - 
//  OnBeforeSave	 - строка	 - userProc(conf,localObject);
//  OnAfterSave		 - 	 - 
//
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
procedure SetAccessToken(conf,accessToken) export
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
 
 
 #region ObjectOptionsBuilder
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
 #endregion
 
 
 #region ObjectOptions
 // Функция - Спільна функція отримання опцій обєкта з підтримкою рекурсій 
//
// Параметры:
//  objectDescriptor - structure -  object descriptor or undefined (return default)
//  optionName		 - string	 -  option name
//  default			 - any	     -  default value
//  recursiveLevel	 - number	 - 
// 
// Возвращаемое значение:
//  any - 
//
function GetObjectOption(objectDescriptor,val optionName,val default,  val recursiveLevel = 5)
	if recursiveLevel <= 0 then
		raise "Перевищено кількість рекурсивниї звернень при отриманні опції обєкта "+ optionName+ ".";	
	endif;
	
	if objectDescriptor = undefined then
		return default;
	endif;	
	
	try
		option = objectDescriptor[optionName];
	except
		raise "Помилка зчитування опції - "+optionName+ "для даного обєкта .";
	endtry;
	if option <> undefined then
		return option;
	endif;
	
	try
		owner = objectDescriptor["Owner"];
	except
		raise "Помилка зчитування Owner для опції "+optionName+ "для даного обєкта .";
	endtry;
	
	return GetObjectOption(owner,optionName,default, recursiveLevel-1);

endfunction
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
	return GetObjectOption(objectDescriptor,"AutoQuerySending",true);
endfunction	
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

// Функция - Is use external id
//
// Параметры:
//  objectDescriptor - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function IsUseExternalId(objectDescriptor)
	return GetObjectOption(objectDescriptor,"UseIdAttribute",false);	
endfunction	



// Функция - Get id attribute type
//
// Параметры:
//  objectDescriptor - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function GetIdAttributeType(objectDescriptor)
	return GetObjectOption(objectDescriptor,"IdAttributeType",Enums.SabatexExchangeIdAttributeType.UUID);
endfunction

// Функция - Is updated 
//
// Параметры:
//  conf		 - 	 - 
//  localObject	 - 	 - 
// 
// Возвращаемое значение:
//   - 
//
function IsUpdated(conf,localObject=undefined)
	if localObject <> undefined then
		if localObject.isNew() then
			return true;
		endif;
	endif;
	
	if IsWriteUnresilved(conf) then
		return true;
	endif;
	if conf.ObjectDescriptor.IsUpdated <> undefined then
		return conf.ObjectDescriptor.IsUpdated;
	endif;
	return conf.IsUpdated;
endfunction

function IsAcceptWrite(conf)
	if not IsUnserted(conf.ObjectDescriptor) then
		if conf.success then
			return true;
		endif;
		Return IsWriteUnresilved(conf);
	else
		return false;
	endif;
endfunction


 #endregion
 
 
 #region Objects_With_External_Key
// Процедура - Реєстрація зовнішнього ключа для обєкта
//
// Параметры:
//  object		 - Ref					- посилання на обєкт в базі
//  nodeName	 - string	 			- назва нода синхронізації
//  externalId	 - UUID,string,number	- зовнішній ключ (UUID,string,number)
//
 procedure RegisterExtrnalId(val object,val nodeName, val externalId) export
	reg = InformationRegisters.SabatexExchangeIds.CreateRecordManager();
	reg.NodeName  = Lower(nodeName);
	reg.ObjectType = GetNormalizedObjectType(object.Ref.Метаданные().FullName()); 
	reg.objectRef = externalId;
	reg.InternalObjectRef = object.Ref.UUID();
 	reg.Write(true);
endprocedure	
 #endregion
 
 
#region Objects_Analize
// Перевірка доступності аналізу вхідних документів
// - conf структура з параметрами
function IsAnalizeEnable(conf)
	result =false;
	if conf.Property("Parse",result) then
		return result;
	endif;
	return false;
endfunction	

function IsAcceptMissData(object,descriptor,iteraction=5)
	
	if iteraction=5 then
		if IsFolder(object) then
			// for folder always accept missed data
			return true;
		endif;
	endif;
	
	if iteraction <= 0 then
		raise "Перевищена глибина рекурсивних викликів";	
	endif;	
	if descriptor.ignoreMissedObject <> undefined then
		return descriptor.ignoreMissedObject;
	endif;
	if descriptor.Owner <> undefined then
		return IsAcceptMissData(object,descriptor.Owner,iteraction-1);
	endif;
	raise "Помилка в ланцюжку Owner";  
endfunction	

function IsWriteUnresilved(conf)
	if conf.LevelLive > 10 then
		if conf.ObjectDescriptor.WriteUnresolved <> undefined then
			return conf.ObjectDescriptor.WriteUnresolved;
		endif;
		return conf.WriteUnresolved;
	endif;
	return false;
endfunction	


function IsUpdateTransacted(conf,object)
	updateTransacted=conf.updateTransacted;
	
	if conf.ObjectDescriptor.updateTransacted <> undefined then
		// add additional shift time for current object		
		updateTransacted = updateTransacted+conf.ObjectDescriptor.updateTransacted;
	endif;	
	
	if updateTransacted = 0 then
		return false;
	endif;
	
	try
		
		Query = New Query;
		Query.Text = "SELECT DATEDIFF(&docDate, &CurrenDate, HOUR) AS DIFF";
		
		Query.SetParameter("CurrenDate", CurrentDate());
		Query.SetParameter("docDate", object.Date);
		
		QueryResult = Query.Execute().Select();
		
		diff = ?(QueryResult.Next(), ?(QueryResult.DIFF <> Null, QueryResult.DIFF, 0), 0);
		
		result = diff < updateTransacted; 
		
		if not result then
			Error(conf,"Заборонено імпортувати документи з різницею в часі більше ніж "+updateTransacted+" годин");
			return false;
		endif;
		return true;
	except
		Error(conf,ErrorDescription());
		return false;
	endtry ;
	return false;
endfunction	

function IsPredefinedAccepted(conf)
	if conf.ObjectDescriptor.PredefinedAccepted <> undefined then
		return conf.ObjectDescriptor.PredefinedAccepted;
	endif;
	return conf.PredefinedAccepted;
endfunction

function IsPredefined(object)
	try
		return object.Predefined;
	except
		return false;
	endtry;
endfunction

function GetValueTypes(conf,value)
	//{"Type":["{http://www.w3.org/2001/XMLSchema}boolean"]}
	result = new Array; 
	valueTypes =value["Type"];
	if valueTypes = undefined then
		return undefined;
	endif;
	
	for each item in value["Type"] do
		str = StrReplace(item,"{http://www.w3.org/2001/XMLSchema}","");
		str = StrReplace(str,"{http://v8.1c.ru/8.1/data/enterprise/current-config}","");
		result.Add(Type(str));
	enddo;
	return result;
endfunction


procedure LevelUpUnresolvedObject(conf,item)
	reg = InformationRegisters.sabatexExchangeUnresolvedObjects.CreateRecordManager();
	reg.NodeName = conf.NodeName;
	reg.MessageHeader = item.MessageHeader;
	reg.Read();
	reg.levelLive = reg.levelLive +1;
	reg.Log = conf.Log;
	reg.Write();
endprocedure
procedure DeleteUnresolvedObject(conf,item)
	reg = InformationRegisters.sabatexExchangeUnresolvedObjects.CreateRecordManager();;
	reg.NodeName = conf.NodeName;
	reg.MessageHeader = item.MessageHeader;
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
procedure SetAttribute(conf,objectConf,source,destination,attr,tableName=undefined)
	var attrConf;
	sourceAttrName = attr.Name;
	if upper(attr.Name) = upper("SabatexExchangeId") then
		return;
	endif;	
	if objectConf <> undefined and  objectConf.Attributes.Property(attr.Name,attrConf) then
		// check ignore
		if attrConf.Ignore  then
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
			if IsAcceptMissData(destination,?(attrConf<>undefined,attrConf,objectConf)) then
				return;
			else
				raise "Атрибут "+ sourceAttrName + " відсутній в файлі імпорта.";
			endif;
			
		endif;	
		
		
		if attrType = Type("string") or attrType = Type("Boolean") or attrType = Type("Number")  then
			destination[attr.name] = importValue;
		elsif attrType = Type("Date") then
			destination[attr.name] = XMLValue(attrType,importValue);
		elsif attrType = Type("ХранилищеЗначения") then
			destination[attr.name] = XMLValue(attrType,importValue);
		elsif attrType = Type("UUID") then
			destination[attr.name] = XMLValue(attrType,importValue);	
		else
			mtype = Metadata.FindByType(attrType);
			
			try
				destination[attr.Name] = SabatexExchange.GetObjectRef(conf,mtype.FullName(),importValue);
			except
				Error(conf,"Помилка отримання атрибуту - "+attr.name+" Error:"+ErrorDescription());
				return;
			endtry;
		endif;
	else
		importValue = source[sourceAttrName];
		if importValue = undefined then
			if IsAcceptMissData(destination,?(attrConf<>undefined,attrConf,?(objectConf<>undefined,objectConf,conf.objectDescriptor))) then
				return;
			else
				raise "Атрибут "+ sourceAttrName + " відсутній в файлі імпорта.";
			endif;
		endif;
		objectId = "";
		objectType = "";
		if not SabatexExchange.checkComplexType(conf,importValue,objectId,objectType) then
			Error(conf,"Помилка встановлення комплексного значення для атрибуту "+attr.Name);
		else
			if objectType = Type("string") then
				destination[attr.Name]=objectId;
			elsif objectType = Type("boolean") then
				destination[attr.Name]=objectId;	
			else	
				destination[attr.Name]=SabatexExchange.GetObjectRef(conf,objectType,objectId);
			endif;
		endif;	
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

procedure ResolveAccountingFlags(conf,localobject,mdata)
	for each attr in mdata.AccountingFlags do
		try
			SetAttribute(conf,conf.objectDescriptor ,conf.source,localObject,attr);
		except
			Error(conf,"Помилка встановлення атрибуту "+ attr.Name+ " Error:"+ErrorDescription());  
		endtry;
		
	enddo;	
	
endprocedure

procedure ResolveExtDimensionAccountingFlags(conf,localobject,mdata)
	for each attr in mdata.ExtDimensionAccountingFlags do
		try
			SetAttribute(conf,conf.objectDescriptor ,conf.source,localObject,attr);
		except
			Error(conf,"Помилка встановлення атрибуту "+ attr.Name+ " Error:"+ErrorDescription());  
		endtry;
		
	enddo;	
	
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
		localObject[table.Name].Clear();
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
							Execute(methodname+ "(conf,localobject,line,row)");
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
		if Metadata.Catalogs[SabatexExchange.GetNameObject(conf.ObjectDescriptor.ObjectType)].Hierarchical  then
			isFolder = conf.source["IsFolder"];
			if ?(isFolder = undefined,false,isFolder) then
				localObject = Catalogs[SabatexExchange.GetNameObject(conf.ObjectDescriptor.ObjectType)].CreateFolder();
			else
				localObject = Catalogs[SabatexExchange.GetNameObject(conf.ObjectDescriptor.ObjectType)].CreateItem();
			endif;
		else
			localObject = Catalogs[SabatexExchange.GetNameObject(conf.ObjectDescriptor.ObjectType)].CreateItem();
		endif;
	endif;
	
	if  IsUpdated(conf,localObject) then		
		
		localObject.DeletionMark = conf.source["DeletionMark"];
		mdata = localObject.Metadata();
		if mdata.CodeLength <> 0 then
			code = conf.source["Code"];
			if code <> undefined then
				localObject.Code = code;
			endif;
		endif;
		
		if mdata.DescriptionLength <> 0 then
			localObject.Description = conf.source["Description"];
		endif;
		
		if IsPredefinedAccepted(conf) then
			
			PredefinedDataName = conf.source["PredefinedDataName"];
			if PredefinedDataName <> undefined then
				localObject.PredefinedDataName = PredefinedDataName;
			endif;
			
		endif;
		
		if mdata.Owners.Count() <> 0 then
			owner = conf.source["Owner"];
			if owner <> undefined then
				localObject.Owner = SabatexExchange.GetObjectRef(conf,mdata.FullName(),owner);
			endif;
		endif;
		
		if mdata.Hierarchical and not conf.ObjectDescriptor.UseIdAttribute then
			parent = conf.source["Parent"];
			if parent <> undefined then
				localObject.Parent = SabatexExchange.GetObjectRef(conf,mdata.FullName(),conf.source["Parent"]);
			endif;	
			//if localObject.IsFolder then
			//	return;
			//endif;	
		endif;	
		
		ResolveAttributesAndTabularSections(conf,localObject,mdata);
	endif;
endprocedure	
procedure ResolveObjectDocument(conf,localObject)
	if localObject = undefined then
		localObject = Documents[SabatexExchange.GetNameObject(conf.ObjectDescriptor.ObjectType)].CreateDocument();
	endif;
	
	localObject.DeletionMark = conf.source["DeletionMark"];
	mdata = localObject.Metadata();
	
	localObject.Number = conf.source["Number"];
	localObject.Date = XMLValue(Type("Date"),conf.source["Date"]);
	
	ResolveAttributesAndTabularSections(conf,localObject,mdata);
	
endprocedure	
procedure ResolveInformationRegister(conf,objectManager)
	mdata = Metadata.InformationRegisters[SabatexExchange.GetNameObject(conf.ObjectDescriptor.ObjectType)];
	localObject = objectManager.CreateRecordManager();
	for each attr in mdata.Attributes do
		try
			SetAttribute(conf,conf.objectDescriptor ,conf.Source,localObject,attr);
		except
			Error(conf,"Помилка встановлення атрибуту "+ attr.Name+ " Error:"+ErrorDescription());  
		endtry;
		
	enddo;	
	
	for each attr in mdata.Resources do
		try
			SetAttribute(conf,conf.objectDescriptor ,conf.Source,localObject,attr);
		except
			Error(conf,"Помилка встановлення Resources "+ attr.Name+ " Error:"+ErrorDescription());  
		endtry;
	enddo;	
	
	for each attr in mdata.Dimensions do
		try
			SetAttribute(conf,conf.objectDescriptor, conf.Source,localObject,attr);
		except
			Error(conf,"Помилка встановлення Dimensions "+ attr.Name+ " Error:"+ErrorDescription());  
		endtry;
	enddo;	
	
	if conf.success then
		localObject.Write();	
	endif;	
endprocedure	
procedure ResolveObjectChartOfCharacteristicTypes(conf,localObject)
	if localObject = undefined then 
		objectManager = SabatexExchange.GetObjectManager(conf.ObjectDescriptor.ObjectType);
		localObject = objectManager.CreateItem();
	endif;
	
	if IsUpdated(conf,localObject) then		
		
		localObject.DeletionMark = conf.source["DeletionMark"];
		mdata = localObject.Metadata();
		if mdata.CodeLength <> 0 then
			code = conf.source["Code"];
			if code <> undefined then
				localObject.Code = code;
			endif;
		endif;
		
		if mdata.DescriptionLength <> 0 then
			localObject.Description = conf.source["Description"];
		endif;
		
		
		if mdata.Hierarchical and not conf.ObjectDescriptor.UseIdAttribute then
			parent = conf.source["Parent"];
			if parent <> undefined then
				localObject.Parent = SabatexExchange.GetObjectRef(conf,mdata.FullName(),conf.source["Parent"]);
			endif;	
			if localObject.IsFolder then
				return;
			endif;	
		endif;	
		localObject.ValueType = GetValueTypes(conf,conf.source["ValueType"]);
		
		ResolveAttributesAndTabularSections(conf,localObject,mdata);
	endif;
endprocedure	
procedure ResolveObjectChartOfAccounts(conf,localObject)
	if localObject = undefined then 
		objectManager = SabatexExchange.GetObjectManager(conf.ObjectDescriptor.ObjectType);
		localObject = objectManager.CreateAccount();
	endif;
	
	if IsUpdated(conf,localObject) then		
		
		localObject.DeletionMark = conf.source["DeletionMark"];
		mdata = localObject.Metadata();
		
		if mdata.CodeLength <> 0 then
			code = conf.source["Code"];
			if code <> undefined then
				localObject.Code = code;
			endif;
		endif;
		
		if mdata.DescriptionLength <> 0 then
			localObject.Description = conf.source["Description"];
		endif;
		
		
		localObject.Order = conf.source["Order"];
		localObject.Type = conf.source["Type"];
		localObject.OffBalance = conf.source["OffBalance"];
		
		PredefinedDataName = conf.source["PredefinedDataName"];
		if PredefinedDataName <> undefined then
			localObject.PredefinedDataName = PredefinedDataName;
		endif;
		
		
		if not conf.ObjectDescriptor.UseIdAttribute then
			parent = conf.source["Parent"];
			if parent <> undefined then
				localObject.Parent = SabatexExchange.GetObjectRef(conf,mdata.FullName(),conf.source["Parent"]);
			endif;	
		endif;
		
		
		ResolveAttributesAndTabularSections(conf,localObject,mdata);
		ResolveAccountingFlags(conf,localobject,mdata);
		ResolveExtDimensionAccountingFlags(conf,localobject,mdata);
		
	endif;
endprocedure	



procedure WriteObject(conf,object)
	try
		if IsAcceptWrite(conf) then
			try
				object.ОбменДанными.Загрузка = true;
				if IsPredefined(object) then
					objectManager = SabatexExchange.GetObjectManager(conf.ObjectDescriptor.ObjectType);	
					try
						pObject = objectManager[object.PredefinedDataName];
						object.Write();
					except
						pObject = object;
					endtry;	
					if pObject.Ref <> object.Ref then 
						pObject = pObject.GetObject();
						pObject.ОбменДанными.Загрузка = true;
						pObject.PredefinedDataName = "";
						if SabatexExchange.IsChartOfAccounts(conf.ObjectDescriptor.ObjectType) then
							for each attr in pObject.ВидыСубконто do
								try
									attr.Predefined = false;
								except
									Error(conf,"Помилка встановлення атрибуту "+ attr.Name+ " Error:"+ErrorDescription());  
								endtry;
								
							enddo;	
							
						endif;
						pObject.Write();
						pObject.SetDeletionMark(true);
						pObject.Write();
					else
						object.Write();	
					endif;
				else
					object.Write();	
				endif;
			except
				Error(conf,"Помилка запису. Error:"+ErrorDescription());
			endtry; 
		endif;
	except
		Error(conf,"Помилка запису. Error:"+ErrorDescription());
	endtry; 
endprocedure


// встановлення id оєкта (внутрішній або зовнішній) 
procedure SetInternalObjectId(conf,localObject,objectManager)
	if not IsUseExternalId(conf.ObjectDescriptor) then 
		if IsAcceptWrite(conf) then
			newUUID = new UUID(conf.objectId); 
			objectUUID = objectManager.GetRef(newUUID);
			localObject.SetNewObjectRef(objectUUID);
		endif;
	endif;
endprocedure	

// виклик методу користувача перед записом обэкта, після встановлення внутрішнього id
procedure OnBeforeSave(conf,localObject)
	methodName = conf.ObjectDescriptor.OnBeforeSave; 
		if methodName <> undefined then
			try
				Execute(conf.userDefinedModule+"."+methodName+"(conf,localObject)");
			except
				Error(conf,"Помилка виклику метода користувача"+methodName+" : " +ErrorDescription());
			endtry;
		endif;
endprocedure	

// встановлення id оєкта (внутрішній або зовнішній) 
procedure SetExternalObjectId(conf,localObject,objectManager)
	if IsUseExternalId(conf.ObjectDescriptor) then
		SabatexExchange.RegisterExtrnalId(localObject,conf.NodeName,conf.objectId);
	endif;
endprocedure	

procedure OnAfterSave(conf,localObject)
	if conf.success then
		methodName = conf.ObjectDescriptor.OnAfterSave;
		if methodName <> undefined then
			try
				Execute(conf.userDefinedModule+"."+methodName+"(conf,localObject)");
			except
				Error(conf,"Помилка виклику метода користувача"+methodName+" : " +ErrorDescription());
			endtry;
		endif;
	endif;
endprocedure	

function IsTransact(conf,object)
	if conf.success and not object.DeletionMark then
		if SabatexExchange.IsDocument(conf.ObjectType) then
			if conf.ObjectDescriptor.Transact <> undefined then
				return conf.ObjectDescriptor.Transact;
			endif;
			return conf.Transact;
		endif;
	endif;	
	return false;
endfunction


procedure TransactDocement(conf,object)
	if conf.success then
		if IsTransact(conf,object) then
			object.ОбменДанными.Загрузка =false;
			object.ОбменДанными.Получатели.АвтоЗаполнение = false;
			object.Write(DocumentWriteMode.Posting);
		endif;
	endif;
endprocedure	


// Функция - Отримати дескриптор аналізуємого обєкта
//
// Параметры:
//  conf - structure - контекст нода
// 
// Возвращаемое значение:
//   structure - External descriptor або  raise "Імпорт обєктів даного типу не відтримується."
//
function GetExternalObjectConfig(conf)
	result = undefined; 
	normalizedName = GetNormalizedObjectType(conf.objectType);
	if conf.ExternalObjects.Property(GetNormalizedObjectType(conf.objectType),result) then 
		return result;
	else
		if conf.IsIdenticalConfiguration then
			// For identical configuration automatic create object descriptor
			extObjectConf = SabatexExchange.CreateObjectDescriptor(conf,conf.objectType);
			return extObjectConf.ExternalObjectDescriptor;	
		else	
			raise "Імпорт обєктів даного типу не відтримується.";
		endif;
		
	endif;	
endfunction



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
	conf.IsNew = false;
	conf.Object = undefined;
	
	
	// determine object configuration Description
	if not conf.ExternalObjects.Property(SabatexExchange.GetNormalizedObjectType(conf.objectType),extObjectConf) then
		if conf.IsIdenticalConfiguration then
			// For identical configuration automatic create object descriptor
			extObjectConf = SabatexExchange.CreateObjectDescriptor(conf,conf.objectType);
			extObjectConf = extObjectConf.ExternalObjectDescriptor;	
		else	
			raise "Імпорт обєктів даного типу не відтримується.";
		endif;
	endif;	
	
	// exist user defined full parser
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
		raise "Імпорт обєктів даного типу не підтримується.";
	endif;

	conf.ObjectDescriptor =  extObjectConf.InternalObject;
	
	// отримуємо менеджер обєкта 
	objectManager = GetObjectManager(conf.ObjectDescriptor.ObjectType);
	if objectManager = undefined then
		raise "Тип -"+ conf.localObjectType +" відсутній в поточній конфігурації! Призначте відповідність типів або повну обробку даного типу.";
	endif;
	
	// імпорт регістрів відомостей
	if SabatexExchange.IsInformationRegister(conf.ObjectDescriptor.ObjectType) then
		ResolveInformationRegister(conf,objectManager);
		return;
	endif;	
	
	objectRef = SabatexExchange.GetObjectRefById(conf,objectManager,conf.ObjectDescriptor,conf.objectId);
	
	
	// спроба пошуку по користувацьким параметрам
	onlySinchro = false;
	
	if objectRef = objectManager.EmptyRef() then
		userDefinedLookProc =   conf.ObjectDescriptor.lookObjectProc;
		if userDefinedLookProc <> undefined then
			onlySinchro = true;
			try
				Execute(conf.userDefinedModule+"."+userDefinedLookProc+"(conf,objectRef)");
			except
				raise "Помилка виклику метода користувача"+userDefinedLookProc+" : " +ErrorDescription();
			endtry;
		endif;
		
		// можливо цей обэкт має зовнішній ключ для цього ноду?
		id = conf.source["SabatexExchangeId"];
		if id <> undefined and conf.ObjectDescriptor.UseIdAttribute then
			if not IsEmptyUUID(id) then
				lO = objectManager.GetRef(new UUID(id)).GetObject();
				if lO <> undefined then
					objectRef = lO.Ref;
					onlySinchro = true;
				endif;
			else
				Error(conf,"Передано пустий ключ SabatexExchangeId ");
			endif;
		endif;	
	endif;
	
	isNew = false;
	localObject = undefined;
	if objectRef = objectManager.EmptyRef() then
		isNew = true;
		if SabatexExchange.IsUnserted(conf.ObjectDescriptor) then
			Error(conf,"Обєкт не ідентифіковано. Даний обєкт необхідно додавати вручну.");
			return;	
		endif;
	else
		if IsUpdated(conf) or onlySinchro then
			localObject =  objectRef.GetObject();
		else
			Error(conf,"Оновлення данного обэкта не передбачено.");
			return;	
		endif;
		
	endif;		
	
	if not onlySinchro then
		if SabatexExchange.IsCatalog(conf.ObjectDescriptor.ObjectType) then
			ResolveObjectCatalog(conf,localObject);
		elsif SabatexExchange.IsDocument(conf.ObjectDescriptor.ObjectType) then
			if localObject <> undefined then
				if localObject.Проведен then
					if not IsUpdateTransacted(conf,localObject) then
						// miss transacted documents
						return;
					endif;	
				endif;
			endif;
			ResolveObjectDocument(conf,localObject);
		elsif SabatexExchange.IsChartOfCharacteristicTypes(conf.ObjectDescriptor.ObjectType) then
			ResolveObjectChartOfCharacteristicTypes(conf,localObject); 
		elsif SabatexExchange.IsChartOfAccounts(conf.ObjectDescriptor.ObjectType) then
			ResolveObjectChartOfAccounts(conf,localObject);
		else
			raise "Обробка даного типу не підтримуэться - "+conf.ObjectType;
		endif;
	endif;
	
	// встановлення id обэкта
	if isNew then
		SetInternalObjectId(conf,localObject,objectManager);
	endif;	
	

	OnBeforeSave(conf,localObject);
	
	WriteObject(conf,localObject);
	
	SetExternalObjectId(conf,localObject,objectManager);
	
	OnAfterSave(conf,localObject);
	
	TransactDocement(conf,localObject);

endprocedure

// Процедура - Аналіз 200 обєктів з урахуванням спроб (спочатку нові)
//
// Параметры:
//  conf - 	 - 
//
procedure AnalizeUnresolvedObjects(conf) export
	Query = New Query;
	Query.Text = 
	"SELECT TOP " + conf.take+"
	|	sabatexExchangeUnresolvedObjects.NodeName AS nodeName,
	|	sabatexExchangeUnresolvedObjects.dateStamp AS dateStamp,
	|	sabatexExchangeUnresolvedObjects.objectAsText AS objectAsText,
	|	sabatexExchangeUnresolvedObjects.Log AS Log,
	|	sabatexExchangeUnresolvedObjects.senderDateStamp AS senderDateStamp,
	|	sabatexExchangeUnresolvedObjects.serverDateStamp AS serverDateStamp,
	|	sabatexExchangeUnresolvedObjects.levelLive AS levelLive,
	|	sabatexExchangeUnresolvedObjects.MessageHeader AS MessageHeader
	|FROM
	|	InformationRegister.sabatexExchangeUnresolvedObjects AS sabatexExchangeUnresolvedObjects
	|WHERE
	|	sabatexExchangeUnresolvedObjects.NodeName = &sender
	|
	|ORDER BY
	|	levelLive,
	|	senderDateStamp";
	
	Query.SetParameter("sender",conf.nodeName);
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		try
			conf.Log = "";
			conf.success = true;
			conf.LevelLive = SelectionDetailRecords.levelLive; 
			message = SelectionDetailRecords["messageHeader"];
			if message = undefined then
				Error(conf,"Відсутній messageHeader");
				continue;
			endif;
			
			try
				messageHeader = Deserialize(message);
			except
				Error(conf,"Помилка десереалізації messageHeader");
				continue;
			endtry;
			
			
			query = messageHeader["query"];
			if query = undefined then
				if IsAnalizeEnable(conf) then
					conf.objectId = messageHeader["id"];
					conf.objectType = messageHeader["type"];
					conf.senderDateStamp = SelectionDetailRecords.senderDateStamp;
					Information(conf,"Аналіз повідомлення "+conf.objectType+" id = "+ conf.objectId);
					try
						conf.source = Deserialize(SelectionDetailRecords.objectAsText);
					except
						Error(conf,"Помилка десереалізації повідомлення! Error Message: " + ОписаниеОшибки());
					endtry;
					
					if conf.success then
						try
							ResolveObject(conf);
						except
							Error(conf,"Error:" + ОписаниеОшибки(),true);
						endtry;
					endif;
				else
					Error(conf,"Аналіз вхідних документів вимкнено.");
				endif;
				
			else
				SabatexExchange.QyeryAnalize(conf,query);	
			endif;
			
			if conf.success then
				DeleteUnresolvedObject(conf,SelectionDetailRecords);
			else
				LevelUpUnresolvedObject(conf,SelectionDetailRecords);
			endif;
			
		except
			ErrorJournaled(conf,"Do not load objectId=" + conf.objectId + ";objectType="+ conf.objectType + " Error Message: " + ОписаниеОшибки());
			continue;
		endtry;
	enddo;
endprocedure
#endregion

 
 #region POST_Objects


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

// post objects to service
procedure PostObjects(conf) export
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
			//if TrimAll(items.JSONText) = "" then
			//	// серыалізація обєкта під час відправлення
			//	messageHeader = SabatexJSON.Deserialize(items.MessageHeader);
			//	message = undefined;
			//	if messageHeader["query"] = undefined then
			//		objectType = messageHeader["type"]; 
			//		objectId = messageHeader["id"];
			//		objectManager = GetObjectManager(objectType);	
			//		object	= objectManager.GetRef(new UUID(objectId)).GetObject();
			//		if object <> undefined then
			//			message =SabatexJSON.Serialize(object);
			//		endif;
			//	endif;
			//else
				message =items.JSONText;
			//endif;
			
			POSTExchangeMessage(conf,items.MessageHeader,items.dateStamp,message);
			
			DeleteObjectForExchange(items.MessageHeader,conf.nodeName);
		except
			Error(conf,ErrorDescription());	
		endtry;
	enddo;
endprocedure	

// Процедура - Реэстрація повідомлення до відправлення
//
// Параметры:
//  nodeName		 - string 		- назва ноду  node name as SabatexExchangeNodeConfig.NodeName
//  messageHeader	 - structure	- заголовок повідомлення, udefined (default) - auto serialize id and type object
//  object			 - object 		- Object
//  serializeNow     - boolean      - серіалізувати зразу (для обєктів які помічені до видалення серіалізуються зразу) 
procedure RegisterMessageForNode(nodeName,messageHeader=undefined,object=undefined) export
	if messageHeader = undefined and object = undefined then
    	raise "Параметри messageHeader та object не можуть бути оночасно undefined!";
	endif;
	
	reg = InformationRegisters.sabatexExchangeObject.CreateRecordManager();
	reg.NodeName  = nodeName;
	reg.dateStamp = CurrentDate();
	
	if messageHeader = undefined then
		reg.MessageHeader =	Serialize(new structure("type,id",object.Ref.Метаданные().FullName(),XMLString(object.Ref.UUID())));	
	else
		reg.MessageHeader =	Serialize(messageHeader);	
	endif;
	
	if object <> undefined then
		txt = Serialize(object);
		SabatexExchangeId = undefined;
		try
			objectType = lower(object.Ref.Метаданные().FullName()); 
			
			Query = New Query;
			Query.Text = 
				"SELECT TOP 1
				|	SabatexExchangeIds.objectRef AS objectRef
				|FROM
				|	InformationRegister.SabatexExchangeIds AS SabatexExchangeIds
				|WHERE
				|	SabatexExchangeIds.InternalObjectRef = &InternalObjectRef
				|	AND SabatexExchangeIds.ObjectType = &ObjectType
				|	AND SabatexExchangeIds.NodeName = &NodeName";
	
			Query.SetParameter("InternalObjectRef", object.Ref.UUID());
	    	Query.SetParameter("ObjectType", GetNormalizedObjectType(objectType));
			Query.SetParameter("NodeName", lower(nodeName));
			QueryResult = Query.Execute();
	
			SelectionDetailRecords = QueryResult.Select();
			if SelectionDetailRecords.Next() then
				SabatexExchangeId = XMLString(SelectionDetailRecords.objectRef);
			endif;
		except
			SabatexExchangeId = undefined;
		endtry;	
		
		if SabatexExchangeId <> undefined then
			txt = Left(txt,StrLen(txt) - 1);
			reg.JSONText = txt + ",""SabatexExchangeId"":""" +SabatexExchangeId+"""}";
		else
			reg.JSONText = txt;
		EndIf;
	endif;
 	reg.Write(true);
endprocedure	

// Register object in cashe for send to destination
// params:
// 	obj        - object  or reference  (Catalog or Documrnt)
//  nodeName   - нод в якому приймає участь даний обєкт  
procedure RegisterObjectForNode(conf,obj) export
	try
		RegisterMessageForNode(conf.NodeName,,obj);
	except
		Error(conf,"Помилка реэстрації обєкта для обміну");
	endtry;
endprocedure
procedure RegisterQueryForNode(conf,query) export
	try 
		RegisterMessageForNode(conf.NodeName,new Structure("query",query));
	except
		Error(conf,"Помилка реэстрації запиту обєкта.");
	endtry;
	
endprocedure 


procedure RegisterQueryObjectForNode(conf,objectId,objectType) export
	try
		RegisterQueryForNode(conf,New Structure("id,type",Lower(XMLString(objectId)),Lower(objectType)));
	except
		Error(conf,"Помилка реэстрації запиту обєкта.");
	endtry;
endprocedure	

procedure RegisterQueryObjectsForNode(conf,ObjectTypes,day) export
	for each objectType in StrSplit(ObjectTypes,",") do
		query = New Structure("type,day",Lower(objectType),Lower(Format(day,"DF=yyyyMMdd")));
		RegisterQueryForNode(conf,query);
	enddo;	
endprocedure

// Add query for exchange
// params:
// 		conf 		Configuration structure
//      objectType  Queried object type (50) as (Справочник.Контрагенты)
//      objectId    destination objectId or object code
procedure AddQueryForExchange(conf,objectType,objectId) export
	query = Serialize(new Structure("type,id",objectType,objectId));
	
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
		Information(conf,"обєкт " + query+" в черзі чекає обробки.");
		// miss unresolved object
		return;
	КонецЦикла;
	RegisterQueryObjectForNode(conf,objectId,objectType);	
	Information(conf,"Відправлено запит на отримання "+ objectType + " з Id=" + objectId);
endprocedure	
 
 #endregion

#region Query
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


// Обробка запитів до системи
procedure QyeryAnalize(conf,query) export
	try
	if IsQueryEnable(conf) then
		objectId = query["id"];
		objectType = query["type"];
		if objectId <> undefined and objectType <> undefined then
			
			if IsEmptyUUID(objectId) then
				Error(conf,"Передано хибний запит з пустим Id");
				return;
			endif;	

			object = undefined;
			objectManager = SabatexExchange.GetObjectManager(objectType);
			objectRef = objectManager.GetRef(new UUID(objectId));
			if objectRef.GetObject() = undefined then
				Error(conf,"Помилка отримання обєкта " + objectType + " з ID="+objectId);
				return;
			endif;
			SabatexExchange.RegisterObjectForNode(conf,objectRef.GetObject());		
		else
			try
				Execute(conf.userDefinedModule+".QueryObject(conf,query,object)");
			except
				Error(conf,"Помилка виконання розширеного запиту до бази:"+ОписаниеОшибки() );
			endtry;
		endif;
 	else
		Error(conf,"Обробка запитів для даного нода заборонена!");
	endif;
except
	  Error(conf,"Не передбачена помилка при виконанны аналізу запиту обєкта !"+ОписаниеОшибки());
	endtry;
endprocedure	
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
		if not conf.Objects.Property(GetNormalizedObjectType(objectType),objectDescriptor) then
			if conf.IsIdenticalConfiguration or conf.IsEnumAutoImport then
				objectDescriptor = CreateObjectDescriptor(conf,objectType)
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
function GetObjectRefById(conf,objectManager,objectDescriptor,id) export
	if id = "" or id = GetEmptyUUIDAsString() then
		Error(conf,"Не вказано id або id = EmptyRef");
		return objectManager.EmptyRef();
	endif;

	objectId = id;
	if IsUseExternalId(objectDescriptor) then
	
		Query = New Query;
		Query.Text = 
			"SELECT
			|	SabatexExchangeIds.InternalObjectRef AS InternalObjectRef
			|FROM
			|	InformationRegister.SabatexExchangeIds AS SabatexExchangeIds
			|WHERE
			|	SabatexExchangeIds.NodeName = &NodeName
			|	AND SabatexExchangeIds.ObjectType = &ObjectType
			|	AND SabatexExchangeIds.objectRef = &objectRef";
	
		Query.SetParameter("ObjectType", objectDescriptor.NormalizedObjectType);
		Query.SetParameter("NodeName", Lower(conf.NodeName));
		Query.SetParameter("objectRef", Lower(String(id)));
	
		QueryResult = Query.Execute();
	
		SelectionDetailRecords = QueryResult.Select();
	
		result = objectManager.EmptyRef();
		if not SelectionDetailRecords.Next() then
			return objectManager.EmptyRef();
		endif;
		
		objectId = SelectionDetailRecords.InternalObjectRef;
		if IsEmptyUUID(objectId) then
			return objectManager.EmptyRef();	
		endif;
 
	endif;
	
	lO = objectManager.GetRef(new UUID(objectId)).GetObject();
	if lO <> undefined then
		return lO.Ref
	else
		return objectManager.EmptyRef();	
	endif;
endfunction	

function GetQueryHeader(query)
	return Serialize(new Structure("query",query));
endfunction

function GetObjectHeader(type,id) export
	return Serialize(new structure("type,id",type,id));
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
			Error(conf,"Помилка отримання комплексного типу "+objectType + "  з objectId ="+objectId );
			return undefined;
		endtry;	
	endif;	
	
	if IsEnum(objectType) then
		return GetEnumValue(conf,objectType,objectId,objectDescriptor);
	endif;	
	
	if objectDescriptor = undefined then
		if not conf.Objects.Property(GetNormalizedObjectType(objectType),objectDescriptor) then
			if conf.IsIdenticalConfiguration then
				objectDescriptor = CreateObjectDescriptor(conf,objectType)
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
	
	if IsEmptyUUID(ObjectId) then
		return objectManager.EmptyRef();	
	endif;
	
	if objectDescriptor.Ignore then
		return objectManager.EmptyRef();
	endif;	
	
	result = GetObjectRefById(conf,objectManager,objectDescriptor,objectId);

	if result= objectManager.EmptyRef() or  result.GetObject() = undefined then
		conf.success = false;
		if IsAutoQuerySending(objectDescriptor) then
			destinationFullName = objectDescriptor.ExternalObjectDescriptor.ObjectType;
		    AddQueryForExchange(conf,destinationFullName,objectId);
		else
			Information(conf,"Відправка запиту на отримання "+ objectType + " з Id=" + objectId +" заборонена.");	
		endif;
		
		return objectManager.EmptyRef();
	endif;
	return result;
endfunction	





#endregion

#region ExchangeObjects


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
    reg.NodeName = conf.NodeName;
	
	reg.levelLive = 0;
	reg.dateStamp = CurrentDate();
	reg.serverDateStamp= XMLValue(Type("Date"),item["senderDateStamp"]);
	reg.senderDateStamp =XMLValue(Type("Date"),item["dateStamp"]);
	reg.objectAsText = item["message"];
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
			
			incoming = GetObjectsExchange(conf);
			for each item in incoming do
				BeginTransaction();
				try
					AddUnresolvedObject(conf,item);
					DeleteExchangeObject(conf,item["id"]);
					CommitTransaction();
				except
					RollbackTransaction();
					Error(conf,"Do not load message Error Message: " + ОписаниеОшибки());
				endtry;
			enddo;
		enddo;
endprocedure
#endregion

#region User_Defined_Actions
procedure BeforeSend(conf)
	if conf.userDefinedModule <> "" then
		try
			Execute(conf.userDefinedModule+".BeforeSend(conf)");
		except
			Information(conf,"Не встановлено обробник користувача BeforeSend(conf)");
		endtry;	
	endif;	
	
endprocedure	
#endregion

procedure ExchangeTaskAsync(nodeName) export
	conf = GetConfigByNodeName(nodeName);
	// read  input objects
	ReciveObjects(conf);
	// Аналіз поступивших обєктів
	AnalizeUnresolvedObjects(conf);

    BeforeSend(conf);
	
	// Відправка на сервер 
	if conf.Send then
		PostObjects(conf);
	endif;
endprocedure




// Процедура - процесс обміну
//
// Параметры:
//  exchangeMode - enum	 - exchange take node by mode (auto/manual) 
// 
// Возвращаемое значение:
//  string - Result log 
//
function ExchangeProcess(exchangeMode,background=true) export
	Query = New Query;
	Query.Text = 
	"SELECT
	|	SabatexExchangeNodeConfig.NodeName AS NodeName,
	|	SabatexExchangeNodeConfig.destinationId AS destinationId,
	|	SabatexExchangeNodeConfig.ExchangeMode AS ExchangeMode,
	|	SabatexExchangeNodeConfig.isActive AS isActive
	|FROM
	|	InformationRegister.SabatexExchangeNodeConfig AS SabatexExchangeNodeConfig
	|WHERE
	|	SabatexExchangeNodeConfig.isActive = TRUE
	|	AND SabatexExchangeNodeConfig.ExchangeMode = &ExchangeMode";
	
	Query.SetParameter("ExchangeMode",exchangeMode);
	
	QueryResult = Query.Execute();
	
	sr = QueryResult.Select();
	resultMessage = "";
	While sr.Next() Do
		if background then
			filter = new structure("Key,State",XMLString(sr.destinationId),BackgroundJobState.Active);
			task = BackgroundJobs.GetBackgroundJobs(filter);
			if task.Count() = 0  then
				params = new array;
				params.Add(sr.NodeName);
				BackgroundJobs.Execute("SabatexExchange.ExchangeTaskAsync",params,XMLString(sr.destinationId),"SabatexExchange "+sr.nodeName);
				resultMessage = resultMessage + "Запущено завдання обміну  з вузлом "+sr.nodeName+ Chars.CR;
			else
				resultMessage = resultMessage + "Завдання обміну  з вузлом "+sr.nodeName + " - пропущено, так як не виконано попереднє"+ Chars.CR;
			endif;
		else
			try
				ExchangeTaskAsync(sr.NodeName);
			except
				resultMessage = resultMessage + "Помилка: Завдання обміну  з вузлом "+sr.nodeName + " - пропущено, так як не виникла помилка"+  ОписаниеОшибки()+Chars.CR;
			endtry;	
		endif;
	enddo;
	return resultMessage;
endfunction



