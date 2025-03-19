
#region SabatexExchangeAdapter5_0_0_rc8

// Copyright (c) 2021-2024 by Serhiy Lakas
// https://sabatex.github.io

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
procedure RegisterMessageForNode(val nodeName,val messageHeader=undefined, val object=undefined)
	SabatexExchange.RegisterMessageForNode(nodeName,messageHeader,object);
endprocedure


#endregion


#region Configuration
 
// Функция - Get destination nodes
// 
// Возвращаемое значение:
// array node config  -  масив конфігурацій нодів
//

function GetActiveDestinationNodes()
	return SabatexExchange.GetActiveDestinationNodes();
endfunction
 
 
// Процедура - Add attribute ignored
//
// Параметры:
//  objectDescriptor - structure	 - 
//  attrName		 - string	 - Назви атрибутів роздвлених комою які будуть ігноровані при імпорті
//
procedure AddAttributeIgnored(objectDescriptor,attrName)
	SabatexExchange.AddAttributeIgnored(objectDescriptor,attrName);
endprocedure

procedure AddAttributeDefault(objectDescriptor,attrName,default)
	SabatexExchange.AddAttributeDefault(objectDescriptor,attrName,default);	
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
	return SabatexExchange.AddAttributeMapped(objectDescriptor,attrName,destinationName);	
endfunction

procedure AddAttributeProc(objectDescriptor,attrName,procName)
	SabatexExchange.AddAttributeProc(objectDescriptor,attrName,procName)	
endprocedure

// Функция - Configured object descriptor
//
// Параметры:
//  Conf				 - 	 - 
//  ObjectType			 - string	 -  тип обьэкта типу "Справочник.Номенклатура"
//  ExternalObjectType	 - string	 -  (необовязково якщо одинакові) тип обэкта в іншвй базі
//  ignore			     - boolean	 -  (необовязково) вказуэться якщо обэкт ідентифікується не через UUID обэкта а через атрибут 
// 
// Возвращаемое значение:
//   structure - objectDescriptor
//
function CreateObjectDescriptor(Conf,ObjectType,val ExternalObjectType=undefined,val ignore=false) export
	return SabatexExchange.CreateObjectDescriptor(Conf,ObjectType,ExternalObjectType,ignore);
endfunction

// Процедура - Configure update startegy
//
// Параметры:
//  objectDescriptor - structure - 
//  update			 - boolean	 - (необовязково) true/false Оновлювати обэкт. (Обєкт може мінятись клієнтом і мати інші властивості в порівнянні destination)
//
procedure ConfigureUpdateStartegy(objectDescriptor,update)
	SabatexExchange.ConfigureUpdateStartegy(objectDescriptor,update);	
endprocedure	

// Процедура - Configure store unresolved startegy
//
// Параметры:
//  objectDescriptor - 	 - 
//  writeUnresolved	 - 	 - 
//
procedure ConfigureStoreUnresolvedStartegy(objectDescriptor,writeUnresolved)
	SabatexExchange.ConfigureStoreUnresolvedStartegy(objectDescriptor,writeUnresolved);
endprocedure	

// Процедура - Configure inserting object
//
// Параметры:
//  objectDescriptor - 	 - 
//  uninserted		 - 	 - 
//
procedure ConfigureInsertingStartegy(objectDescriptor,uninserted)
	SabatexExchange.ConfigureInsertingStartegy(objectDescriptor,uninserted);
endprocedure	

// Процедура - Configure missing data startegy
//
// Параметры:
//  objectDescriptor	 - 	 - 
//  ignoreMissedObject	 - 	 - 
//
procedure ConfigureMissingDataStartegy(objectDescriptor,ignoreMissedObject)
	SabatexExchange.ConfigureMissingDataStartegy(objectDescriptor,ignoreMissedObject);
endprocedure	

// Процедура - Configure transact document startegy (default false)
//
// Параметры:
//  objectDescriptor - conf	     -  контекст описувача обэкта створеного CreateObjectDescriptor(..)
//  transact		 - boolean	 - true  Обэкт автоматично проводиься
//  updateTransacted - Number    - різниця в годинах між поточною датою та датою документа на проміжку якої дозволена модифікація документа
//
procedure ConfigureTransactDocumentStartegy(objectDescriptor,transact,updateTransacted=undefined)
	SabatexExchange.ConfigureTransactDocumentStartegy(objectDescriptor,transact,updateTransacted);
endprocedure	

	
procedure ConfigureSearchObject(objectDescriptor,UseIdAttribute=false,LookObjectProc=undefined)
	SabatexExchange.ConfigureSearchObject(objectDescriptor,UseIdAttribute,LookObjectProc);	
endprocedure	


procedure ConfigureParserActions(conf,objectDescriptor,OnBeforeSave=false,OnAfterSave=undefined) export
 	SabatexExchange.ConfigureParserActions(conf,objectDescriptor,OnBeforeSave,OnAfterSave);
endprocedure	


function CreateExternalObjectDescriptor(conf,externalObjectType,parserProc=undefined,internalObjectDescriptor=undefined) export
 	SabatexExchange.CreateExternalObjectDescriptor(conf,externalObjectType,parserProc,internalObjectDescriptor);
endfunction

procedure CreateEnumObjectDescriptor(Conf,EnumName,EnumRelolveProc=undefined)
	SabatexExchange.CreateEnumObjectDescriptor(Conf,EnumName,EnumRelolveProc);
endprocedure	

function AddTableProperty(objectConf,attrName,Ignore=false,destinationName=undefined,procName=undefined,postParser=undefined) export
	return SabatexExchange.AddTableProperty(objectConf,attrName,Ignore,destinationName,procName,postParser);	
endfunction

// Procedure - Configure auto query sending.
// By default, the system supports sending requests for unresolved objects.
// If set to unsupported, queries are handled separately for each object descriptor. 
//
// Parameters:
//  descriptor	 - structure - exchange or object descriptor
//  enable		 - boolean	 - default true
//
procedure ConfigureAutoQuerySending(descriptor,enable = true) export
	SabatexExchange.ConfigureAutoQuerySending(descriptor,enable);	
endprocedure	

#endregion


#region Logged
function Error(conf,message,result=undefined)
	return SabatexExchange.Error(conf,message,result);
endfunction	
// Процедура - Sabatex log warning
//
// Параметры:
//  conf	 - 	 - 
//  message	 - 	 - 
//
procedure Warning(conf,message,isJournalWrite=false)
	SabatexExchange.Warning(conf,message,isJournalWrite);		
endprocedure
// Процедура - Sabatex log information
//
// Параметры:
//  conf	 - 	 - 
//  message	 - 	 - 
//
procedure Information(conf,message,isJournalWrite=false)
	SabatexExchange.Information(conf,message,isJournalWrite);		
endprocedure
// Процедура - Sabatex log note
//
// Параметры:
//  conf	 - 	 - 
//  message	 - 	 - 
//
procedure Note(conf,message,isJournalWrite=false)
	SabatexExchange.Note(conf,message,isJournalWrite);		
endprocedure
	
#endregion



 #region functions
 function IsEmptyUUID(value)
	return SabatexExchange.IsEmptyUUID(value);
endfunction	

 #endregion
 
 procedure AddPostObjectDescription(items,objectType,filter)
	items.Add(new structure("ObjectType,Filter",objectType,filter));	 
	 
 endprocedure
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
	
	
	// загальне правило додавання обєктів за замовчуванням true.
	// Блокує додванння нових обєктів (для розблокування обєкта потрібно викликати ConfigureInsertingStartegy
	//conf.UnInserted = true; 
	
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
//
// Параметры:
//  conf	 - 	 - 
//  items	 - 	 - 
//
procedure ObjectQueriesList(conf,items) export
	//items.Add("Документ.ЧекККМ");
endprocedure	

// Процедура додає список обєктів по які можна вивантажити до нода
//
// Параметры:
//  conf	 - structure  - конфігурація обміну 
//  items	 - array 	  - масив елементів string або structure (ObjectType,Filter) 
//
procedure ObjectPostList(conf,items) export
	//items.Add(new structure("ObjectType,Filter","Документ.ЧекККМ","Организация.Код = 'ER0000123'");
	//AddPostObjectDescription(items,"Документ.ЧекККМ","Организация.Код = 'ER0000123'");
endprocedure	

// Процедура - Дана процедура запускається після імпорту рядка таблиці обєкта і дозволяє додатково заповнити рядок. Назва процедури вказується в AddTableProperty(...,postParser)  
//
// Параметры:
//  conf		 - structure - контекст парсера для поточного нода 
//  localobject	 - object	 -  поточний обєкт який імпортується
//  line		 - Map       -  рядок з файла імпорта
//  row			 - TableRow	 - поточний рядок обєкта який імпортується
//
procedure DemoTablePostParser(conf,localobject,line,row)
endprocedure	
	