// Copyright (c) 2021-2024 by Serhiy Lakas
// https://sabatex.github.io


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
	jsonString = SabatexJSON.Serialize(new structure("clientId,password",string(conf.nodeConfig.clientId),conf.nodeConfig.password));
	request.SetBodyFromString(jsonString,"UTF-8",ИспользованиеByteOrderMark.НеИспользовать);
	response = connection.Post(request);
		
	if response.StatusCode <> 200 then
		raise "Login error with StatusCode="+ response.StatusCode;
	endif;
		
	apiToken = response.GetBodyAsString();
	
	if apiToken = "" then
		raise "Не отримано токен";
	endif;	
	return SabatexJSON.Deserialize(apiToken);
endfunction
// отримати новий токен за допомогою  refresh_token
function RefreshToken(conf)
	connection = CreateHTTPSConnection(conf);
	request = new HTTPRequest(BuildUrl("api/v0/refresh_token"));
	request.Headers.Insert("accept","*/*");
	request.Headers.Insert("Content-Type","application/json; charset=utf-8");
	jsonString = SabatexJSON.Serialize(new structure("clientId,password",string(conf.nodeConfig.clientId),conf.accessToken.refresh_token));
	request.SetBodyFromString(jsonString,"UTF-8",ИспользованиеByteOrderMark.НеИспользовать);
	response = connection.Post(request);
	
		if response.StatusCode <> 200 then
			raise "Login error request with StatusCode="+ response.StatusCode;
		endif;

	apiToken = response.GetBodyAsString();
	
	if apiToken = "" then
			raise "Не отримано токен";
	endif;
	return SabatexJSON.Deserialize(apiToken);
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
		SabatexExchangeConfig.SetAccessToken(conf,token);
		return true;
	except
	endtry;	
	return false;
endfunction
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
		return SabatexJSON.Deserialize(response.GetBodyAsString(),datefields);	
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
procedure POSTExchangeObject(conf, objectType, objectId, dateStamp,textJSON,first=true) export
	connection = CreateHTTPSConnection(conf);
	request = new HTTPRequest(BuildUrl("api/v0/objects"));
	request.Headers.Insert("accept","*/*");
	request.Headers.Insert("Content-Type","application/json; charset=utf-8");
	request.Headers.Insert("clientId",XMLСтрока(conf.nodeConfig.clientId));
	request.Headers.Insert("apiToken",XMLСтрока(conf.accessToken.access_token));
	request.Headers.Insert("destinationId",XMLСтрока(conf.destinationId));
	try			  
		jsonString = SabatexJSON.Serialize(new structure("objectType,objectId,dateStamp,text",objectType,XMLСтрока(objectId),dateStamp,textJSON));
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
		return SabatexJSON.Deserialize(response.GetBodyAsString());
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
		jsonString = SabatexJSON.Serialize(new structure("objectType,objectId",objectType,objectId));
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

