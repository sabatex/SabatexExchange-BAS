
#region SabatexExchangeAdapter
// Copyright (c) 2021-2024 by Serhiy Lakas
// https://sabatex.github.io
// version 3.0.11

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

procedure AddAttributeProperty(objectConf,attrName,Ignore=false,default=undefined,destinationName=undefined,procName=undefined,postParser=undefined,ignoredIsMiss=false)
	SabatexExchangeConfig.AddAttributeProperty(objectConf,attrName,Ignore,default,destinationName,procName,postParser,ignoredIsMiss);		
endprocedure
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
procedure AddAttributeMapped(objectDescriptor,attrName,destinationName,ignoredIsMiss=false)
	AddAttributeProperty(objectDescriptor,attrName,,,destinationName,,,ignoredIsMiss);	
endprocedure

procedure AddAttributeProc(objectDescriptor,attrName,procName)
	AddAttributeProperty(objectDescriptor,attrName,,,,procName);	
endprocedure

// Функция - Configured object descriptor
//
// Параметры:
//  Conf				 - 	 - 
//  ObjectType			 - string	 -  тип обьэкта типу "Справочник.Номенклатура"
//  ExternalObjectType	 - string	 -  (необовязково якщо одинакові) тип обэкта в іншвй базі
//  PostParser			 - string	 -  (необовязково) назва процедури яка буде викликана після парсингу обєкта
//  IdAttribute			 - string	 -  (необовязково) вказуэться якщо обэкт ідентифікується не через UUID обэкта а через атрибут 
//  LookObjectProc		 - string	 -  (необовязково) процендура пошуку обєкта по користувацьким алгоритмам (тільки нові) IdAttribute - обовязкове 
//  UnInserted		 	 - bool 	 -  (необовязково) Обэкт тільки синхронізується з базою 
// 
// Возвращаемое значение:
//   structure - objectDescriptor
//
function CreateObjectDescriptor(Conf,ObjectType,val ExternalObjectType=undefined,PostParser=undefined,IdAttribute=undefined,LookObjectProc=undefined,UnInserted=false,Transact=false) export
	return SabatexExchangeConfig.CreateObjectDescriptor(Conf,ObjectType,ExternalObjectType,PostParser,IdAttribute,LookObjectProc,UnInserted,Transact);
endfunction
function CreateExternalObjectDescriptor(conf,externalObjectType,parserProc=undefined,internalObjectDescriptor=undefined) export
 	SabatexExchangeConfig.CreateExternalObjectDescriptor(conf,externalObjectType,parserProc,internalObjectDescriptor);
endfunction

procedure CreateEnumObjectDescriptor(Conf,EnumName,EnumRelolveProc=undefined)
	SabatexExchangeConfig.CreateObjectDescriptor(Conf,"Перечисление."+EnumName,,EnumRelolveProc);
endprocedure	

function AddTableProperty(objectConf,attrName,Ignore=false,destinationName=undefined,procName=undefined,postParser=undefined) export
	return SabatexExchangeConfig.AddTableProperty(objectConf,attrName,Ignore,destinationName,procName,postParser);	
endfunction

procedure PostQueries(conf,objectId,objectType)
	SabatexExchangeWebApi.PostQueries(conf, objectId,objectType);	
endprocedure	

function CreateDocumentDescriptor(Conf,ObjectType,val ExternalObjectType=undefined,PostParser=undefined,IdAttribute=undefined,LookObjectProc=undefined,UnInserted=false,Transact=false) export
	return SabatexExchangeConfig.CreateObjectDescriptor(Conf,ObjectType,ExternalObjectType,PostParser,IdAttribute,LookObjectProc,UnInserted,Transact);
endfunction
 
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


#endregion




// Процедура - Викликаэться при ініціалізації обміну (наявність обовязкова)
//
// Параметры:
//  conf - structure	 -  конфігупація обміну
//
procedure Initialize(conf) export
	
endprocedure


// Процедура - Query object
//
// Параметры:
//  conf		 - 	 - 
//  objectType	 - 	 - 
//  objectId	 - 	 - 
//  object		 - 	 - 
//
procedure QueryObject(conf,objectType,objectId,object) export
		
	
endprocedure	
