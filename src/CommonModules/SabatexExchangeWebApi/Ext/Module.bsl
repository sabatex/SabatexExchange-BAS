// Copyright (c) 2021-2024 by Serhiy Lakas
// https://sabatex.github.io

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
	jsonString = SabatexJSON.Serialize(new structure("cid,login,password",conf.nodeConfig.cid,conf.nodeConfig.login,conf.nodeConfig.password));
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
	if conf.NodeType = Enums.SabatexExchangeNodeType.USAP then
		return GetObjectsUSAP(conf,first);
	endif;
	
	connection = CreateHTTPSConnection(conf); 
	if conf.TakeOneMessageAtATime then
		take = 1;
	else
		take =conf.take;
	endif;	
	request = new HTTPRequest(BuildUrl("api/v1/objects",new structure("take",take)));
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
		return SabatexJSON.Deserialize(response.GetBodyAsString());	
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
	
	packetInfo = SabatexExchangeConfig.GetStoredValue("USAP_SesionInfo");
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
	data.Insert("sendVersion",Sabatex.ValueOrDefault(packetInfo["sendVersion"],0));//Узел.НомерОтправленного
	data.Insert("lastDownload",Sabatex.ValueOrDefault(packetInfo["lastDownload"],Date("19000101")));               //Узел.ДатаПоследнегоПолученогоПакета
	data.Insert("receiveName",conf.NodeName);//Узел.ИмяПубликации  що ставити ? назва 
	data.Insert("receiveVersion",Sabatex.ValueOrDefault(packetInfo["receiveVersion"],-1)); //   ?(Узел.НомерПринятого=0,-1,Узел.НомерПринятого));
	
	jsonString = SabatexJSON.Serialize(data);
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
		return SabatexJSON.Deserialize(response.GetBodyAsString());	
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
		jsonString = SabatexJSON.Serialize(new structure("messageHeader,dateStamp,message",messageHeader,dateStamp,textJSON));
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


