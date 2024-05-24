
#region SabatexExchangeAdapter
// Copyright (c) 2021-2024 by Serhiy Lakas
// https://sabatex.github.io
// version 4.0.0-rc16

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
function GetObjectRef(conf,objectType,objectId,val objectDescriptor=undefined)
	return SabatexExchange.GetObjectRef(conf,objectType,objectId,objectDescriptor);
endfunction	


#region registration_message_for_exchange
procedure RegisterQueryObjectsByDayForNode(nodeName,objectType,date)
	SabatexExchange.RegisterQueryObjectsForNode(nodeName,objectType,date);
endprocedure

procedure RegisterQueryForNode(conf,query)
	SabatexExchange.RegisterQueryForNode(conf,query);
endprocedure	
procedure RegisterObjectForNode(conf,obj)
	SabatexExchange.RegisterMessageForNode(conf.NodeName,,obj);
endprocedure


#endregion


 #region Configuration
// Процедура - Add attribute property
//
// Параметры:
//  objectConf		 - 	 - 
//  attrName		 - 	 - 
//  Ignore			 - 	 - 
//  default			 - 	 - 
//  destinationName	 - 	 - 
//  procName		 - 	 - 
//  postParser		 - 	 - 
//  ignoredIsMiss	 - 	 - 
//
function AddAttributeProperty(objectConf,attrName,Ignore=false,default=undefined,destinationName=undefined,procName=undefined,postParser=undefined)
	return SabatexExchangeConfig.AddAttributeProperty(objectConf,attrName,Ignore,default,destinationName,procName,postParser);		
endfunction
// Процедура - Add attribute ignored
//
// Параметры:
//  objectDescriptor - structure	 - 
//  attrName		 - string	 - Назви атрибутів роздвлених комою які будуть ігноровані при імпорті
//
procedure AddAttributeIgnored(objectDescriptor,attrName)
	for each attr in StrSplit(attrName,",") do
		AddAttributeProperty(objectDescriptor,attr,true);
	enddo;
endprocedure
procedure AddAttributeDefault(objectDescriptor,attrName,default)
	AddAttributeProperty(objectDescriptor,attrName,,default);	
endprocedure
// Процедура - Add attribute mapped
//
// Параметры:
//  objectDescriptor - 	 - 
//  attrName		 - 	 - 
//  destinationName	 - 	 - 
//  ignoredIsMiss	 - 	 - 
//
function AddAttributeMapped(objectDescriptor,attrName,destinationName)
	return SabatexExchangeConfig.AddAttributeMapped(objectDescriptor,attrName,destinationName);	
endfunction

procedure AddAttributeProc(objectDescriptor,attrName,procName)
	AddAttributeProperty(objectDescriptor,attrName,,,,procName);	
endprocedure

// Функция - Configured object descriptor
//
// Параметры:
//  Conf				 - 	 - 
//  ObjectType			 - string	 -  тип обьэкта типу "Справочник.Номенклатура"
//  ExternalObjectType	 - string	 -  (необовязково якщо одинакові) тип обэкта в іншвй базі
//  IdAttribute			 - string	 -  (необовязково) вказуэться якщо обэкт ідентифікується не через UUID обэкта а через атрибут 
//  LookObjectProc		 - string	 -  (необовязково) процендура пошуку обєкта по користувацьким алгоритмам (тільки нові) IdAttribute - обовязкове 
//  UnInserted		 	 - bool 	 -  (необовязково) Обэкт тільки синхронізується з базою 
// 
// Возвращаемое значение:
//   structure - objectDescriptor
//
function CreateObjectDescriptor(Conf,ObjectType,val ExternalObjectType=undefined,UseIdAttribute=false,LookObjectProc=undefined) export
	return SabatexExchangeConfig.CreateObjectDescriptor(Conf,ObjectType,ExternalObjectType,UseIdAttribute,LookObjectProc);
endfunction

// Процедура - Configure update startegy
//
// Параметры:
//  objectDescriptor - structure - 
//  update			 - boolean	 - (необовязково) true/false Оновлювати обэкт. (Обєкт може мінятись клієнтом і мати інші властивості в порівнянні destination)
//
procedure ConfigureUpdateStartegy(objectDescriptor,update)
	SabatexExchangeConfig.ConfigureUpdateStartegy(objectDescriptor,update);	
endprocedure	

// Процедура - Configure store unresolved startegy
//
// Параметры:
//  objectDescriptor - 	 - 
//  writeUnresolved	 - 	 - 
//
procedure ConfigureStoreUnresolvedStartegy(objectDescriptor,writeUnresolved)
	SabatexExchangeConfig.ConfigureStoreUnresolvedStartegy(objectDescriptor,writeUnresolved);
endprocedure	

// Процедура - Configure inserting object
//
// Параметры:
//  objectDescriptor - 	 - 
//  uninserted		 - 	 - 
//
procedure ConfigureInsertingStartegy(objectDescriptor,uninserted)
	SabatexExchangeConfig.ConfigureInsertingStartegy(objectDescriptor,uninserted);
endprocedure	

// Процедура - Configure missing data startegy
//
// Параметры:
//  objectDescriptor	 - 	 - 
//  ignoreMissedObject	 - 	 - 
//
procedure ConfigureMissingDataStartegy(objectDescriptor,ignoreMissedObject)
	SabatexExchangeConfig.ConfigureMissingDataStartegy(objectDescriptor,ignoreMissedObject);
endprocedure	

// Процедура - Configure transact document startegy
//
// Параметры:
//  objectDescriptor - 	 - 
//  transact		 - 	 - 
//
procedure ConfigureTransactDocumentStartegy(objectDescriptor,transact)
	SabatexExchangeConfig.ConfigureTransactDocumentStartegy(objectDescriptor,transact);
endprocedure	

	


procedure ConfigureParserActions(conf,objectDescriptor,OnBeforeSave=false,OnAfterSave=undefined) export
 	SabatexExchangeConfig.ConfigureParserActions(conf,objectDescriptor,OnBeforeSave,OnAfterSave);
endprocedure	


function CreateExternalObjectDescriptor(conf,externalObjectType,parserProc=undefined,internalObjectDescriptor=undefined) export
 	SabatexExchangeConfig.CreateExternalObjectDescriptor(conf,externalObjectType,parserProc,internalObjectDescriptor);
endfunction

procedure CreateEnumObjectDescriptor(Conf,EnumName,EnumRelolveProc=undefined)
	SabatexExchangeConfig.CreateEnumObjectDescriptor(Conf,EnumName,EnumRelolveProc);
endprocedure	

function AddTableProperty(objectConf,attrName,Ignore=false,destinationName=undefined,procName=undefined,postParser=undefined) export
	return SabatexExchangeConfig.AddTableProperty(objectConf,attrName,Ignore,destinationName,procName,postParser);	
endfunction
 	
 #endregion


#region Logged
function Error(conf,message,result=undefined)
	return SabatexExchangeLogged.Error(conf,message,result);
endfunction	
// Процедура - Sabatex log warning
//
// Параметры:
//  conf	 - 	 - 
//  message	 - 	 - 
//
procedure Warning(conf,message,isJournalWrite=false)
	SabatexExchangeLogged.Warning(conf,message,isJournalWrite);		
endprocedure
// Процедура - Sabatex log information
//
// Параметры:
//  conf	 - 	 - 
//  message	 - 	 - 
//
procedure Information(conf,message,isJournalWrite=false)
	SabatexExchangeLogged.Information(conf,message,isJournalWrite);		
endprocedure
// Процедура - Sabatex log note
//
// Параметры:
//  conf	 - 	 - 
//  message	 - 	 - 
//
procedure Note(conf,message,isJournalWrite=false)
	SabatexExchangeLogged.Note(conf,message,isJournalWrite);		
endprocedure
	
#endregion



 #region functions
 function IsEmptyUUID(value)
	return Sabatex.IsEmptyUUID(value);
endfunction	

 #endregion
  
#endregion




// Процедура - Викликаэться при ініціалізації обміну (наявність обовязкова)
//
// Параметры:
//  conf - structure	 -  конфігупація обміну
//
procedure Initialize(conf) export
	// конфігурація ідентична хосту (підтримуэться правило повного обміну, перезапис обєктів, крім проведених)
	//conf.IsIdenticalConfiguration = false; 
    // вказується тип ключа обєкта в випадку викоритання SabatexExchangeId (UUID - default, string)	
	//conf.IdAttributeType =Enums.SabatexExchangeIdAttributeType.UUID;	
	
endprocedure


// Процедура - Query object
//
// Параметры:
//  conf		 - 	 - 
//  objectType	 - 	 - 
//  objectId	 - 	 - 
//  object		 - 	 - 
//
procedure QueryObject(conf,query,object) export
	Error(conf,"Для обробки запитів необхідно реалізувати матод QueryObject(conf,query,object)");		
endprocedure	

// Процедура додає список обєктів по яким можна зробити запит до нода
procedure ObjectQueriesList(conf,items) export

endprocedure	
