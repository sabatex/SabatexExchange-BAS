// Copyright (c) 2021-2024 by Serhiy Lakas
// https://sabatex.github.io
// 
// incoming objects analize   

#region AnalizeObjects
// Перевірка доступності аналізу вхідних документів
// - conf структура з параметрами
function IsAnalizeEnable(conf)
	result =false;
	if conf.Property("Parse",result) then
		return result;
	endif;
	return false;
endfunction	
function IsFolder(object)
	try
		return object.IsFolder;
	except
		return false;
	endtry	
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

function IsWriteUnresilved(conf)
	if conf.LevelLive > 10 then
		if conf.ObjectDescriptor.WriteUnresolved <> undefined then
			return conf.ObjectDescriptor.WriteUnresolved;
		endif;
		return conf.WriteUnresolved;
	endif;
	return false;
endfunction	

function IsAcceptWrite(conf)
	if conf.success then
		return true;
	endif;
	Return IsWriteUnresilved(conf);
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
				SabatexExchangeLogged.Error(conf,"Заборонено імпортувати документи з різницею в часі більше ніж "+updateTransacted+" годин");
				return false;
			endif;
			return true;
		except
				SabatexExchangeLogged.Error(conf,ErrorDescription());
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


procedure LevelUpUnresolvedObject(conf,item)
	reg = InformationRegisters.sabatexExchangeUnresolvedObjects.CreateRecordManager();
	reg.sender = item.sender;
	reg.MessageHeader = item.MessageHeader;
	reg.Read();
	reg.levelLive = reg.levelLive +1;
	reg.Log = conf.Log;
	reg.Write();
endprocedure
procedure DeleteUnresolvedObject(conf,item)
	reg = InformationRegisters.sabatexExchangeUnresolvedObjects.CreateRecordManager();;
	reg.sender = item.sender;
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
				SabatexExchangeLogged.Error(conf,"Помилка виконання методу визначено користувачем - "+methodName+" Error:"+ErrorDescription());
			endtry;	
	    	return;
		endif;
		sourceAttrName = Sabatex.ValueOrDefault(attrConf.destinationName,attr.Name);
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
				SabatexExchangeLogged.Error(conf,"Помилка отримання атрибуту - "+attr.name+" Error:"+ErrorDescription());
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
			SabatexExchangeLogged.Error(conf,"Помилка встановлення комплексного значення для атрибуту "+attr.Name);
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
				SabatexExchangeLogged.Error(conf,"Помилка виконання методу визначено користувачем - "+methodName+" Error:"+ErrorDescription());
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
			SabatexExchangeLogged.Error(conf,"Помилка встановлення атрибуту "+ attr.Name+ " Error:"+ErrorDescription());  
		endtry;
		
	enddo;	

endprocedure

procedure ResolveExtDimensionAccountingFlags(conf,localobject,mdata)
	for each attr in mdata.ExtDimensionAccountingFlags do
		try
			SetAttribute(conf,conf.objectDescriptor ,conf.source,localObject,attr);
		except
			SabatexExchangeLogged.Error(conf,"Помилка встановлення атрибуту "+ attr.Name+ " Error:"+ErrorDescription());  
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
			SabatexExchangeLogged.Error(conf,"Помилка встановлення атрибуту "+ attr.Name+ " Error:"+ErrorDescription());  
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
					SabatexExchangeLogged.Error(conf,"Помилка виконання методу визначено користувачем - "+methodName+" Error:"+ErrorDescription());
				endtry;	
				continue;
			endif;
			sourceAttrName = Sabatex.ValueOrDefault(tableAttribute.destinationName,table.Name);
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
						SabatexExchangeLogged.Error(conf,"Помилка встановлення атрибуту "+ attr.Name+ " для табличної частини "+ table.Name+" Error:"+ErrorDescription());  
					endtry;
						
				enddo;
				
				if tableAttribute <> undefined then
					if tableAttribute.postParser <> undefined then
						methodName = conf.userDefinedModule+"."+tableAttribute.postParser;
						try
							Execute(methodname+ "(conf,localobject,line,row)");
						except
							SabatexExchangeLogged.Error(conf,"Помилка виконання методу визначено користувачем - "+methodName+" Error:"+ErrorDescription());
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
				SabatexExchangeLogged.Error(conf,"Помилка встановлення атрибуту "+ attr.Name+ " Error:"+ErrorDescription());  
			endtry;
			
		enddo;	
		
		for each attr in mdata.Resources do
			try
				SetAttribute(conf,conf.objectDescriptor ,conf.Source,localObject,attr);
			except
				SabatexExchangeLogged.Error(conf,"Помилка встановлення Resources "+ attr.Name+ " Error:"+ErrorDescription());  
			endtry;
		enddo;	
		
		for each attr in mdata.Dimensions do
			try
				SetAttribute(conf,conf.objectDescriptor, conf.Source,localObject,attr);
			except
				SabatexExchangeLogged.Error(conf,"Помилка встановлення Dimensions "+ attr.Name+ " Error:"+ErrorDescription());  
			endtry;
		enddo;	
		
	if conf.success then
		localObject.Write();	
	endif;	
endprocedure	




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

function IsPredefined(object)
	try
		return object.Predefined;
	except
		return false;
	endtry;
endfunction



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
									SabatexExchangeLogged.Error(conf,"Помилка встановлення атрибуту "+ attr.Name+ " Error:"+ErrorDescription());  
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
				SabatexExchangeLogged.Error(conf,"Помилка запису. Error:"+ErrorDescription());
			endtry; 
		endif;
	except
		SabatexExchangeLogged.Error(conf,"Помилка запису. Error:"+ErrorDescription());
	endtry;
endprocedure

procedure SetObjectId(conf,localObject,objectManager)
	attrIdName = "SabatexExchangeId"; 
	if conf.ObjectDescriptor.UseIdAttribute then
		if upper(string(localObject[attrIdName])) <> upper(conf.objectId) then //?
			mData = localObject.Metadata();
			attr = mData.Attributes[attrIdName]; 
			types = attr.Type.Типы();
			if types.Count() =1 then
				attrType = types[0];
				if attrType = Type("string") then
					localObject[attrIdName] = conf.objectId;
				elsif attrType = Type("UUID") then
					localObject[attrIdName] = new UUID(conf.objectId);
				else
					raise "Помилка встановлення атрибуту SabatexExchangeId for type = "+attrType;
				endif;
			else
				raise "Помилка встановлення атрибуту SabatexExchangeId for complex type.";
			endif;
		endif;
	else
		newUUID = new UUID(conf.objectId); 
		objectUUID = objectManager.GetRef(newUUID);
		localObject.SetNewObjectRef(objectUUID);
	endif;
endprocedure	

procedure OnBeforeSave(conf,localObject)
	if conf.success then
		methodName = conf.ObjectDescriptor.OnBeforeSave; 
		if methodName <> undefined then
			try
				Execute(conf.userDefinedModule+"."+methodName+"(conf,localObject)");
			except
				SabatexExchangeLogged.Error(conf,"Помилка виклику метода користувача"+methodName+" : " +ErrorDescription());
			endtry;
		endif;
	endif;
endprocedure	
	
procedure OnAfterSave(conf,localObject)
		methodName = conf.ObjectDescriptor.OnAfterSave;
	    if methodName <> undefined then
			try
				Execute(conf.userDefinedModule+"."+methodName+"(conf,localObject)");
			except
				SabatexExchangeLogged.Error(conf,"Помилка виклику метода користувача"+methodName+" : " +ErrorDescription());
			endtry;
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
	if IsTransact(conf,object) then
		object.ОбменДанными.Загрузка =false;
		object.ОбменДанными.Получатели.АвтоЗаполнение = false;
		object.Write(DocumentWriteMode.Posting);
	endif;	
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
	
	// determine object configuration Description
	if not conf.ExternalObjects.Property(SabatexExchangeConfig.GetNormalizedObjectType(conf.objectType),extObjectConf) then
		if conf.IsIdenticalConfiguration then
			// For identical configuration automatic create object descriptor
			extObjectConf = SabatexExchangeConfig.CreateObjectDescriptor(conf,conf.objectType);
			extObjectConf = extObjectConf.ExternalObjectDescriptor;	
		else	
			SabatexExchangeLogged.Error(conf,"Імпорт обєктів даного типу не відтримується.");
			return;
		endif;
	endif;	
	
	// exist user defined full parser
	if extObjectConf.Parser <> undefined then
		try
			Execute(conf.userDefinedModule+"."+extObjectConf.Parser+"(conf)");
			return;
		except
			SabatexExchangeLogged.Error(conf,"Помилка виклику метода користувача"+extObjectConf.Parser+" : " +ErrorDescription());
			return;
		endtry;
	endif;	
	
	// спроба отримати налащтування для обєкта
	if extObjectConf.InternalObject = undefined then
		SabatexExchangeLogged.Error(conf,"Імпорт обєктів даного типу не підтримується.");
		return;
	else
		conf.ObjectDescriptor =  extObjectConf.InternalObject;
	endif;	
	
	
	// Використовуэмо автоматичний парсер
	objectManager = SabatexExchange.GetObjectManager(conf.ObjectDescriptor.ObjectType);
	if objectManager = undefined then
		SabatexExchangeLogged.Error(conf,"Тип -"+ conf.localObjectType +" відсутній в поточній конфігурації! Призначте відповідність типів або повну обробку даного типу.");
		return;
	endif;
	
	// імпорт регістрів відомостей
	if SabatexExchange.IsInformationRegister(conf.ObjectDescriptor.ObjectType) then
		ResolveInformationRegister(conf,objectManager);
		return;
	endif;	
	
	
	
	
	objectRef = SabatexExchange.GetObjectRefById(objectManager,conf.ObjectDescriptor,conf.objectId);
	
	
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
	endif;

	isNew = false;
	localObject = undefined;
	if objectRef = objectManager.EmptyRef() then
		isNew = true;
  		if SabatexExchange.IsUnserted(conf.ObjectDescriptor) then
			SabatexExchangeLogged.Error(conf,"Обєкт не ідентифіковано. Даний обєкт необхідно додавати вручну.");
			return;	
		endif;
	else
		if IsUpdated(conf) or onlySinchro then
			localObject =  objectRef.GetObject();
		else
			SabatexExchangeLogged.Error(conf,"Оновлення данного обэкта не передбачено.");
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
	if isNew or onlySinchro then
		SetObjectId(conf,localObject,objectManager);
	endif;	

	
	// OnBeforeSave
	OnBeforeSave(conf,localObject);
	
	WriteObject(conf,localObject);
	
	OnAfterSave(conf,localObject);
	if not onlySinchro then
		TransactDocement(conf,localObject);
	endif;
	
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
		|	sabatexExchangeUnresolvedObjects.sender AS sender,
		|	sabatexExchangeUnresolvedObjects.destination AS destination,
		|	sabatexExchangeUnresolvedObjects.dateStamp AS dateStamp,
		|	sabatexExchangeUnresolvedObjects.objectAsText AS objectAsText,
		|	sabatexExchangeUnresolvedObjects.Log AS Log,
		|	sabatexExchangeUnresolvedObjects.senderDateStamp AS senderDateStamp,
		|	sabatexExchangeUnresolvedObjects.serverDateStamp AS serverDateStamp,
		|	sabatexExchangeUnresolvedObjects.Id AS Id,
		|	sabatexExchangeUnresolvedObjects.levelLive AS levelLive,
		|	sabatexExchangeUnresolvedObjects.MessageHeader AS MessageHeader
		|FROM
		|	InformationRegister.sabatexExchangeUnresolvedObjects AS sabatexExchangeUnresolvedObjects
		|WHERE
		|	sabatexExchangeUnresolvedObjects.sender = &sender
		|
		|ORDER BY
		|	levelLive,
		|	senderDateStamp";
		
		Query.SetParameter("sender",new UUID(conf.destinationId));
		QueryResult = Query.Execute();
		
		SelectionDetailRecords = QueryResult.Select();
		
		While SelectionDetailRecords.Next() Do
			try
				conf.Log = "";
				conf.success = true;
                conf.LevelLive = SelectionDetailRecords.levelLive; 
				message = SelectionDetailRecords["messageHeader"];
				if message = undefined then
					SabatexExchangeLogged.Error(conf,"Відсутній messageHeader");
					continue;
				endif;
				
				try
					messageHeader = SabatexJSON.Deserialize(message);
				except
					SabatexExchangeLogged.Error(conf,"Помилка десереалізації messageHeader");
					continue;
				endtry;
				
					
				query = messageHeader["query"];
				if query = undefined then
					if IsAnalizeEnable(conf) then
						conf.objectId = messageHeader["id"];
						conf.objectType = messageHeader["type"];
						conf.senderDateStamp = SelectionDetailRecords.senderDateStamp;
						SabatexExchangeLogged.Information(conf,"Аналіз повідомлення "+conf.objectType+" id = "+ conf.objectId);
						try
							conf.source = SabatexJSON.Deserialize(SelectionDetailRecords.objectAsText);
						except
							SabatexExchangeLogged.Error(conf,"Помилка десереалізації повідомлення! Error Message: " + ОписаниеОшибки());
						endtry;
						
						if conf.success then
							try
								ResolveObject(conf);
							except
								SabatexExchangeLogged.Error(conf,"Помилка  аналіза Error:" + ОписаниеОшибки(),true);
							endtry;
						endif;
					else
						SabatexExchangeLogged.Error(conf,"Аналіз вхідних документів вимкнено.");
					endif;
					
				else
					SabatexExchangeQuery.QyeryAnalize(conf,query);	
				endif;
				
				if conf.success then
					DeleteUnresolvedObject(conf,SelectionDetailRecords);
				else
					LevelUpUnresolvedObject(conf,SelectionDetailRecords);
				endif;
				
			except
				SabatexExchangeLogged.ErrorJournaled(conf,"Do not load objectId=" + conf.objectId + ";objectType="+ conf.objectType + " Error Message: " + ОписаниеОшибки());
				continue;
			endtry;
		enddo;
endprocedure
#endregion
