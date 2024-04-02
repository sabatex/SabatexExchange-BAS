// Copyright (c) 2021-2024 by Serhiy Lakas
// https://sabatex.github.io
// 
// incoming objects analize   

#region AnalizeObjects

// Процедура - Add unresolved object
//
// Параметры:
//  conf		 - struct    - 
//  item		 - map	     - 
//  newObject	 - boolean	 - 
//
procedure AddUnresolvedObject(conf,item,newObject = true) export
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
	if upper(attr.Name) = upper("SabatexExchangeId") then
		return;
	endif;	
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
			if attrConf<>undefined and attrConf.ignoredIsMiss then
				return;
			else
				raise "Атрибут "+ sourceAttrName + " відсутній в файлі імпорта.";
			endif;
			
		endif;	
		
		
		if attrType = Type("string") or attrType = Type("Boolean") or attrType = Type("Number")  then
			destination[attr.name] = importValue;
		elsif attrType = Type("Date") then
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
			if attrConf<>undefined and attrConf.ignoredIsMiss then
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
			destination[attr.Name]=SabatexExchange.GetObjectRef(conf,objectType,objectId);
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
				localObject.Owner = SabatexExchange.GetObjectRef(conf,mdata.FullName(),owner);
			endif;
		endif;
		
		if mdata.Hierarchical and conf.ObjectDescriptor.IdAttribute=undefined then
			parent = conf.source["Parent"];
			if parent <> undefined then
				localObject.Parent = SabatexExchange.GetObjectRef(conf,mdata.FullName(),conf.source["Parent"]);
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
		localObject = Documents[SabatexExchange.GetNameObject(conf.ObjectDescriptor.ObjectType)].CreateDocument();
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
	
	if not conf.ExternalObjects.Property(SabatexExchangeConfig.GetNormalizedObjectType(conf.objectType),extObjectConf) then
		raise "Імпорт обєктів даного типу не відтримується.";
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
	
	// Використовуэмо автоматичний парсер
	objectManager = SabatexExchange.GetObjectManager(conf);
	if objectManager = undefined then
		raise "Обробка даного типу не підтримуэться - "+conf.localObjectType;
	endif;
	
	// варіант пошуку по атрибуту
	attributeId = conf.ObjectDescriptor.IdAttribute;
	
	// пошук обэкта по ід або атрибуту
	if attributeId = undefined then
		lO = objectManager.GetRef(new UUID(conf.objectId)).GetObject();
		if lO = undefined then
			objectRef = objectManager.EmptyRef();
		else
			objectRef = lO.Ref();
		endif;	
	else
		objectRef = objectManager.FindByAttribute(attributeId,new UUID(conf.objectId));
	endif;

	
	// спроба пошуку по користувацьким параметрам тільки непомічені до видалення
	if objectRef = objectManager.EmptyRef() and conf.source["DeletionMark"] = false then
		userDefinedLookProc =   conf.ObjectDescriptor.lookObjectProc;
		if userDefinedLookProc <> undefined then
			try
				Execute(conf.userDefinedModule+"."+userDefinedLookProc+"(conf,objectRef)");
			except
				raise "Помилка виклику метода користувача"+userDefinedLookProc+" : " +ErrorDescription();
			endtry;
		endif;	
	endif;
	
	// пропуск видалених обєктів 
	if objectRef = objectManager.EmptyRef() and conf.source["DeletionMark"] = true then
		raise "Спроба імпорту нового обєкта поміченого до видалення в віддаленій системі";
	endif;	
	
	localObject = undefined;
	if conf.ObjectDescriptor.UnInserted then
		if objectRef = objectManager.EmptyRef() then
			raise "Обєкт не ідентифіковано. Даний обєкт необхвдно додавати вручну.";
		endif;
	else
		if objectRef = objectManager.EmptyRef()  then
			conf.isUpdated = true;
			// новий обьэкт
			
			if SabatexExchange.IsCatalog(conf.ObjectDescriptor.ObjectType) then
				ResolveObjectCatalog(conf,localObject);
			elsif SabatexExchange.IsDocument(conf.ObjectDescriptor.ObjectType) then
				if localObject <> undefined then
					if localObject.Проведен then
						return;
					endif;
				endif;
				ResolveObjectDocument(conf,localObject);
			else
				raise "Обробка даного типу не підтримуэться - "+conf.ObjectType;
			endif;
		else
			localObject = objectRef.GetObject();
		endif;	
		
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
	
	BeginTransaction();
	// Постобробка
	if conf.ObjectDescriptor.PostParser <> undefined then
		try
			Execute(conf.userDefinedModule+"."+conf.ObjectDescriptor.PostParser+"(conf,localObject)");
		except
			SabatexExchangeLogged.Error(conf,"Помилка виклику метода користувача"+conf.ObjectDescriptor.PostParser+" : " +ErrorDescription());
		endtry;
	endif;
	
	// Запис обьєкта		
	if conf.success and conf.isUpdated then
		try
			if SabatexExchange.IsDocument(conf.ObjectType) then
				if conf.ObjectDescriptor.Transact then
					localObject.Write(DocumentWriteMode.Posting,DocumentPostingMode.Regular);
				else
					localObject.Write();
				endif;	
			else
				localObject.Write();
			endif;	
		except
			SabatexExchangeLogged.Error(conf,"Помилка запису. Error:"+ErrorDescription());
		endtry;	
	endif;
	if conf.success then
		CommitTransaction();
	else
		RollbackTransaction();
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
					conf.source = SabatexJSON.Deserialize(SelectionDetailRecords.objectAsText,datefields);
				except
					SabatexExchangeLogged.Error(conf,"Помилка десереалізації ! Error Message: " + ОписаниеОшибки());
				endtry;
				
				if conf.success then
					try
						ResolveObject(conf);
					except
						SabatexExchangeLogged.Error(conf,"Помилка  аналіза Error:" + ОписаниеОшибки(),true);
					endtry;
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
