
#region SabatexExchangeAdapter5_0_2

// Copyright (c) 2021-2025 by Serhiy Lakas
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
//  updateTransacted - Number    - різниця в годинах між поточною датою та датою документа на проміжку якої дозволена модифікація документа,
//                                 по замовчуванню undefined - без обмежень
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

// Функция - Отримати режим обміну Авто 
// 
// Возвращаемое значение:
//  enum - Enums.SabatexExchangeMode.Auto
//
function GetSabatexExchangeModeAuto()
	return SabatexExchange.GetSabatexExchangeModeAuto();
endfunction	 
 
 #endregion

 


&НаСервере
Процедура ВигрузкаДокументаЗаДеньНаСервере(nodeName,objectType)
	f = UploadObjectFilter.Выгрузить(new structure("NodeName,ObjectType",nodeName,objectType));
	for each item in f do
		Запрос = Новый Запрос;
		Запрос.Текст = 
			"ВЫБРАТЬ
			|	doc.Ссылка КАК Ссылка
			|ИЗ
			|	"+item.ObjectType+" КАК doc
			|ГДЕ
			|	doc.Дата МЕЖДУ НАЧАЛОПЕРИОДА(&Date, ДЕНЬ) И КОНЕЦПЕРИОДА(&Date, ДЕНЬ)";
		if item.КассаККМ <> Справочники.КассыККМ.ПустаяСсылка() then
			Запрос.Текст = Запрос.Текст + "	И doc.КассаККМ = &КассаККМ";
		endif;
		if item.Store <> Справочники.Склады.ПустаяСсылка() then
			if Upper(objectType) = Upper("Документ.ПеремещениеТоваров") then
			    Запрос.Текст = Запрос.Текст + "	И (doc.СкладОтправитель = &Склад or doc.СкладПолучатель = &Склад)";	
			else
				Запрос.Текст = Запрос.Текст + "	И doc.Склад = &Склад";
			endif;
		endif;
		if item.Касса <> Справочники.Кассы.ПустаяСсылка() then
			Запрос.Текст = Запрос.Текст + "	И doc.Касса = &Касса";
		endif;
		
		Запрос.УстановитьПараметр("Date", Объект.Дата);
		if item.КассаККМ <> Справочники.КассыККМ.ПустаяСсылка() then
			Запрос.УстановитьПараметр("КассаККМ", item.КассаККМ);
		endif;
		if item.Store <> Справочники.Склады.ПустаяСсылка() then 
			Запрос.УстановитьПараметр("Склад", item.Store); 
		endif;
        if item.Касса <> Справочники.Кассы.ПустаяСсылка() then
			Запрос.УстановитьПараметр("Касса", item.Касса);
		endif;


		РезультатЗапроса = Запрос.Выполнить();
	
		ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	
		Пока ВыборкаДетальныеЗаписи.Следующий() Цикл
			SabatexExchange.RegisterMessageForNode(nodeName,,ВыборкаДетальныеЗаписи.Ссылка.GetObject(),true);
		КонецЦикла;

		
		
	enddo;
		
	
КонецПроцедуры

&НаСервере
Процедура ВигрузкаДокументівЗаДеньНаСервере()
	
	for each item in ObjectTypes do
		if item.Checked then
			ВигрузкаДокументаЗаДеньНаСервере(NodeName,item.Name);
		endif;	
		
	enddo;	
	
КонецПроцедуры


&НаКлиенте
Процедура ВигрузкаДокументівЗаДень(Команда)
	ВигрузкаДокументівЗаДеньНаСервере();
КонецПроцедуры



&НаСервере
Процедура SetPriceНаСервере()
	//{{КОНСТРУКТОР_ЗАПРОСА_С_ОБРАБОТКОЙ_РЕЗУЛЬТАТА
	// Даний фрагмент побудований конструктором.
	// При повторному використанні конструктора, внесені вручну зміни будуть втрачені!!!
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	УстановкаЦенНоменклатуры.Ссылка КАК Ссылка
		|ИЗ
		|	Документ.УстановкаЦенНоменклатуры КАК УстановкаЦенНоменклатуры
		|ГДЕ
		|	УстановкаЦенНоменклатуры.Товары.ВидЦены = &ВидЦены";
	
	Запрос.УстановитьПараметр("ВидЦены",  Объект.ВидЦін);
	Запрос.УстановитьПараметр("Дата",  Объект.Дата);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	
	Пока ВыборкаДетальныеЗаписи.Следующий() Цикл
		//RegisterMessageForNode(ВыборкаДетальныеЗаписи.Ссылка);
		SabatexExchange.RegisterMessageForNode(nodeName,,ВыборкаДетальныеЗаписи.Ссылка.GetObject(),true);
	КонецЦикла;
	
	//}}КОНСТРУКТОР_ЗАПРОСА_С_ОБРАБОТКОЙ_РЕЗУЛЬТАТА
	// Вставити вміст обробника.
КонецПроцедуры

&НаКлиенте
Процедура SetPrice(Команда)
	SetPriceНаСервере();
КонецПроцедуры

&НаСервере
Процедура UploadCatalogНаСервере()
	
	
	if CatalogItem.IsFolder then
		catalogName = CatalogItem.Metadata().Имя;
		Запрос = Новый Запрос;
		Запрос.Текст = 
		"ВЫБРАТЬ
		|	Item.Ссылка КАК Ссылка
		|ИЗ
		|	Catalog."+catalogName+ " КАК Item
		|ГДЕ
		|	Item.Родитель В ИЕРАРХИИ(&Родитель)";
		
		Запрос.УстановитьПараметр("Родитель", CatalogItem);
		
		РезультатЗапроса = Запрос.Выполнить();
		
		ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
		
		Пока ВыборкаДетальныеЗаписи.Следующий() Цикл
			//RegisterMessageForNode(ВыборкаДетальныеЗаписи.Ссылка)  ;
			SabatexExchange.RegisterMessageForNode(nodeName,,ВыборкаДетальныеЗаписи.Ссылка.GetObject(),true);
			
		КонецЦикла;
	else
		//RegisterMessageForNode(CatalogItem)  ;
		SabatexExchange.RegisterMessageForNode(nodeName,,CatalogItem.GetObject());
	endif;
	
КонецПроцедуры

&НаКлиенте
Процедура UploadCatalog(Команда)
	UploadCatalogНаСервере();
КонецПроцедуры


&НаСервере
Процедура UploadRegistersНаСервере()
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	ШтрихкодыНоменклатуры.Штрихкод КАК Штрихкод,
		|	ШтрихкодыНоменклатуры.Номенклатура КАК Номенклатура,
		|	ШтрихкодыНоменклатуры.Характеристика КАК Характеристика,
		|	ШтрихкодыНоменклатуры.Упаковка КАК Упаковка
		|ИЗ
		|	РегистрСведений.ШтрихкодыНоменклатуры КАК ШтрихкодыНоменклатуры
		|ГДЕ
		|	ШтрихкодыНоменклатуры.Номенклатура В ИЕРАРХИИ(&Номенклатура)";
	
	Запрос.УстановитьПараметр("Номенклатура", Объект.NomenckatureFolder);
	
	РезультатЗапроса = Запрос.Выполнить();
	
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	
	Пока ВыборкаДетальныеЗаписи.Следующий() Цикл
		header = new structure("id,type",ВыборкаДетальныеЗаписи.Штрихкод,"РегистрСведений.ШтрихкодыНоменклатуры");
		obj = new structure("Штрихкод,Номенклатура,Характеристика,Упаковка",ВыборкаДетальныеЗаписи.Штрихкод,XMLString(ВыборкаДетальныеЗаписи.Номенклатура.Ref),XMLString(ВыборкаДетальныеЗаписи.Характеристика.Ref),XMLString(ВыборкаДетальныеЗаписи.Упаковка.Ref));
		//RegisterMessageForNode(obj,header,true);
		SabatexExchange.RegisterMessageForNode(nodeName,header,ВыборкаДетальныеЗаписи.Ссылка.GetObject(),true);
	КонецЦикла;
КонецПроцедуры

&НаКлиенте
Процедура UploadRegisters(Команда)
	UploadRegistersНаСервере();
КонецПроцедуры

&НаСервере
Процедура UploadPredefinedНаСервере()
	for each item in Метаданные.Справочники  do
		Запрос = Новый Запрос;
		Запрос.Текст = 
		"ВЫБРАТЬ
		|	Item.Ссылка КАК Ссылка
		|ИЗ
		|	Справочник."+item.Name +" КАК Item
		|ГДЕ
		|	Item.Предопределенный = ИСТИНА";
	
		РезультатЗапроса = Запрос.Выполнить();
	
		ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	
		Пока ВыборкаДетальныеЗаписи.Следующий() Цикл
			//RegisterMessageForNode(ВыборкаДетальныеЗаписи.Ссылка);
			SabatexExchange.RegisterMessageForNode(nodeName,,ВыборкаДетальныеЗаписи.Ссылка.GetObject(),true);
		КонецЦикла;
	enddo;	
КонецПроцедуры

&НаКлиенте
Процедура UploadPredefined(Команда)
	UploadPredefinedНаСервере();
КонецПроцедуры

&НаСервере
Процедура UploadConstantsНаСервере()
	for each const in Метаданные.Константы do
		m = Константы[const.Name].СоздатьМенеджерЗначения();
		header = new structure("id,type",const.Name,"Константа."+const.Name);
		obj = m.ЭтотОбъект;
		//RegisterMessageForNode(m.ЭтотОбъект,header,true);
		SabatexExchange.RegisterMessageForNode(nodeName,header,obj,true);
	enddo;	
КонецПроцедуры

&НаКлиенте
Процедура UploadConstants(Команда)
	UploadConstantsНаСервере();
КонецПроцедуры

&НаСервереБезКонтекста
Процедура ClearКлючиДоступаКОбъектамНаСервере()
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	КлючиДоступаКОбъектам.Объект КАК Объект
		|ИЗ
		|	РегистрСведений.КлючиДоступаКОбъектам КАК КлючиДоступаКОбъектам";
	
	РезультатЗапроса = Запрос.Выполнить();
	
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	
	Пока ВыборкаДетальныеЗаписи.Следующий() Цикл
		 m = РегистрыСведений.КлючиДоступаКОбъектам.СоздатьМенеджерЗаписи();
		 m.Объект = ВыборкаДетальныеЗаписи.Объект;
		 m.Удалить();
	КонецЦикла;
КонецПроцедуры

&НаКлиенте
Процедура ClearКлючиДоступаКОбъектам(Команда)
	ClearКлючиДоступаКОбъектамНаСервере();
КонецПроцедуры

&НаСервере
Процедура UploadBonusНаСервере()
	Запрос = Новый Запрос;
	Запрос.Текст = 
		"ВЫБРАТЬ
		|	БонусныеБаллыОстатки.НачисленоОстаток КАК НачисленоОстаток,
		|	БонусныеБаллыОстатки.Партнер КАК Партнер,
		|	БонусныеБаллыОстатки.КСписаниюОстаток КАК КСписаниюОстаток,
		|	БонусныеБаллыОстатки.БонуснаяПрограммаЛояльности КАК БонуснаяПрограммаЛояльности
		|ИЗ
		|	РегистрНакопления.БонусныеБаллы.Остатки КАК БонусныеБаллыОстатки";
	
	РезультатЗапроса = Запрос.Выполнить();
	
	ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
	header = new structure("id,type",ТекущаяДата(),"Structure.BonusAmount");
	obj = new array;
	
	Пока ВыборкаДетальныеЗаписи.Следующий() Цикл
		obj.Add(new structure("Партнер,БонуснаяПрограммаЛояльности,НачисленоОстаток,КСписаниюОстаток",XMLString(ВыборкаДетальныеЗаписи.Партнер.Ref),XMLString(ВыборкаДетальныеЗаписи.БонуснаяПрограммаЛояльности.Ref),XMLString(ВыборкаДетальныеЗаписи.НачисленоОстаток),XMLString(ВыборкаДетальныеЗаписи.КСписаниюОстаток)));
	КонецЦикла;
	
	//RegisterMessageForNode(obj,header,true); 
	SabatexExchange.RegisterMessageForNode(nodeName,header,obj,true);
	
КонецПроцедуры

&НаКлиенте
Процедура UploadBonus(Команда)
	UploadBonusНаСервере();
КонецПроцедуры

&НаСервере
procedure AddObjectToObjectTypes(objectName)
	row = ObjectTypes.Add();
	row.Checked = true;
	row.Name = objectName;
endprocedure	


&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	for each item in Метаданные.Справочники do
		Элементы.CatalogType.СписокВыбора.Добавить(item.ПолноеИмя());
	enddo;
	
	//nodes =  SabatexExchange.GetDestinationNodes(false);
	nodes = GetActiveDestinationNodes();
	
	for each node in nodes do
		Элементы.NodeName.СписокВыбора.Добавить(node);	
	    Элементы.UploadObjectFilterNodeName.СписокВыбора.Добавить(node);
    enddo; 
	
	Элементы.UploadObjectFilterObjectType.СписокВыбора.Добавить("Документ.ЧекККМ"); //1
	Элементы.UploadObjectFilterObjectType.СписокВыбора.Добавить("Документ.ЧекККМВозврат");//2
	Элементы.UploadObjectFilterObjectType.СписокВыбора.Добавить("Документ.ОтчетОРозничныхПродажах");//3
	Элементы.UploadObjectFilterObjectType.СписокВыбора.Добавить("Документ.ВыемкаДенежныхСредствИзКассыККМ");//4
	Элементы.UploadObjectFilterObjectType.СписокВыбора.Добавить("Документ.ВнесениеДенежныхСредствВКассуККМ");//5
	Элементы.UploadObjectFilterObjectType.СписокВыбора.Добавить("Документ.Документ.КассоваяСмена");//6	
	
	Элементы.UploadObjectFilterObjectType.СписокВыбора.Добавить("Документ.ПриобретениеТоваровУслуг");//7 
	Элементы.UploadObjectFilterObjectType.СписокВыбора.Добавить("Документ.ВозвратТоваровПоставщику");//8
	Элементы.UploadObjectFilterObjectType.СписокВыбора.Добавить("Документ.ЗаказПоставщику");//9
	Элементы.UploadObjectFilterObjectType.СписокВыбора.Добавить("Документ.ПеремещениеТоваров");//10
	Элементы.UploadObjectFilterObjectType.СписокВыбора.Добавить("Документ.СборкаТоваров");//11
	Элементы.UploadObjectFilterObjectType.СписокВыбора.Добавить("Документ.СписаниеНедостачТоваров");//12
	Элементы.UploadObjectFilterObjectType.СписокВыбора.Добавить("Документ.ОприходованиеИзлишковТоваров");//13
	Элементы.UploadObjectFilterObjectType.СписокВыбора.Добавить("Документ.ПересортицаТоваров");//14
	Элементы.UploadObjectFilterObjectType.СписокВыбора.Добавить("Документ.ПересчетТоваров");//15
	
	Элементы.UploadObjectFilterObjectType.СписокВыбора.Добавить("Документ.РасходныйКассовыйОрдер");//16
	Элементы.UploadObjectFilterObjectType.СписокВыбора.Добавить("Документ.ПриходныйКассовыйОрдер");//17  
	Элементы.UploadObjectFilterObjectType.СписокВыбора.Добавить("Документ.КассоваяСмена");//18 
	
	
	RestoreStateAtServer();	
	NodeNameПриИзмененииНаСервере();
	
КонецПроцедуры

&НаСервере
Процедура UploadAllCatalogНаСервере()
		Запрос = Новый Запрос;
		Запрос.Текст = 

		"ВЫБРАТЬ
		|	Item.Ссылка КАК Ссылка
		|ИЗ
		|"+Объект.CatalogType+ " КАК Item";
		
		
		РезультатЗапроса = Запрос.Выполнить();
		
		ВыборкаДетальныеЗаписи = РезультатЗапроса.Выбрать();
		
		Пока ВыборкаДетальныеЗаписи.Следующий() Цикл
			//RegisterMessageForNode(ВыборкаДетальныеЗаписи.Ссылка)  ;
			SabatexExchange.RegisterMessageForNode(nodeName,,ВыборкаДетальныеЗаписи.Ссылка.GetObject(),true);
			
		КонецЦикла;
 КонецПроцедуры

&НаКлиенте
Процедура UploadAllCatalog(Команда)
	UploadAllCatalogНаСервере();
КонецПроцедуры

&НаСервере
Процедура RestoreStateAtServer()
	reg = InformationRegisters.SabatexExchangeConfig.Get(new structure("Key","ExchangeToolsNodeProperties"));
	state =  SabatexExchange.Deserialize(SabatexExchange.ValueOrDefault(reg.Value,"{}"));
	NodeName = state["NodeName"];
	
	UploadObjectFilter.Clear(); 
	of = state["ObjectFilters"];
	if of <> undefined then
	for each item in  of do
		row = UploadObjectFilter.Add();
		row.NodeName = item["NodeName"];
		row.ObjectType = item["ObjectType"];
		row.Checked = SabatexExchange.ValueOrDefault(item["Checked"],false);
		row.Store = Справочники.Склады.ПолучитьСсылку(new UUid(item["Store"]));
		row.КассаККМ = Справочники.КассыККМ.ПолучитьСсылку(new UUid(item["КассаККМ"])); 
		row.Касса = Справочники.Кассы.ПолучитьСсылку(new UUid(?(item["Касса"] = undefined,SabatexExchange.GetEmptyUUID(),item["Касса"])));
	enddo;	
    endif;

КонецПроцедуры


&НаСервере
Процедура SaveStateНаСервере()
	state = new structure();
	state.Вставить("NodeName",NodeName);
	ObjectFilters = new array;
	for each item in  UploadObjectFilter do
		p = new structure;
		p.Insert("NodeName",item.NodeName);
		p.Insert("ObjectType",item.ObjectType); 
		p.Insert("Checked",item.Checked);
		p.Insert("Store",XMLString(item.Store.Ref));
		p.Insert("КассаККМ",XMLСтрока(item.КассаККМ.Ref)); 
		p.Insert("Касса",XMLСтрока(item.Касса.Ref));
    	ObjectFilters.Add(p);
	enddo;
	state.Вставить("ObjectFilters",ObjectFilters);
   	reg = InformationRegisters.SabatexExchangeConfig.CreateRecordManager();
	reg.Key = "ExchangeToolsNodeProperties";
	reg.Value  = SabatexExchange.Serialize(state);
	reg.Write(true);
КонецПроцедуры

&НаКлиенте
Процедура SaveState(Команда)
	SaveStateНаСервере();
КонецПроцедуры

&НаКлиенте
Процедура ПриЗакрытии(ЗавершениеРаботы)
	SaveStateНаСервере();
КонецПроцедуры

&НаСервере
Процедура NodeNameПриИзмененииНаСервере()
	ObjectTypes.Clear(); 
	f = UploadObjectFilter.Выгрузить(new structure("NodeName",NodeName));
    f.Свернуть("ObjectType");
	for each item in f do
		AddObjectToObjectTypes(item.ObjectType);
	enddo;
КонецПроцедуры

&НаКлиенте
Процедура NodeNameПриИзменении(Элемент)
	NodeNameПриИзмененииНаСервере();
КонецПроцедуры

&НаСервере
Процедура UploadDocumentНаСервере()
	SabatexExchange.RegisterMessageForNode(NodeName,,SelectedDoc.GetObject(),true);
КонецПроцедуры

&НаКлиенте
Процедура UploadDocument(Команда)
	UploadDocumentНаСервере();
КонецПроцедуры

&НаСервере
Процедура ЗбираееРозбиранняНаСервере()
	ОписаниеОшибки = "";
		//AITS_РозничныеПродажи.СоздатьСборкуТоваровПриЗакрытииСмены(ОтчетОРозничныхПродажах, ОписаниеОшибки);
КонецПроцедуры

&НаКлиенте
Процедура ЗбираееРозбирання(Команда)
	ЗбираееРозбиранняНаСервере();
КонецПроцедуры
&НаСервереБезКонтекста
Функция вНайтиОбъектПоURL(Знач URL)
	Поз1 = Найти(URL, "e1cib/data/");
	Поз2 = Найти(URL, "?ref=");

	Если Поз1 = 0 Или Поз2 = 0 Тогда
		Возврат Неопределено;
	КонецЕсли;

	Попытка
		ИмяТипа = Сред(URL, Поз1 + 11, Поз2 - Поз1 - 11);
		ШаблонЗначения = ЗначениеВСтрокуВнутр(ПредопределенноеЗначение(ИмяТипа + ".ПустаяСсылка"));
		ЗначениеСсылки = СтрЗаменить(ШаблонЗначения, "00000000000000000000000000000000", Сред(URL, Поз2 + 5));
		Ссылка = ЗначениеИзСтрокиВнутр(ЗначениеСсылки);
	Исключение
		Возврат Неопределено;
	КонецПопытки;

	Возврат Ссылка;
КонецФункции


&НаКлиенте
Процедура НайтиОбъектПоURL(Команда)
	Значение = вНайтиОбъектПоURL(_URL);

	Если CatalogItem <> Значение Тогда
		CatalogItem = Значение;
		//ОбновитьДанныеОбъекта(Неопределено);
	КонецЕсли;
КонецПроцедуры

