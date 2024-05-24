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
	if Sabatex.IsEmptyUUID(objectId) then
		return undefined;
	endif;	
	objRef = Documents[objectName].GetRef(new UUID(objectId));
	if objRef.GetObject() = undefined then
		return SabatexExchangeLogged.Error(conf,"Помилка отримання обєкта документа "+objectName + " з ID="+objectId);
	endif;
	return objRef;
endfunction

function GetCatalogById(conf,objectName,objectId)
	if Sabatex.IsEmptyUUID(objectId) then
		return undefined;
	endif;	

	objRef = Catalogs[objectName].GetRef(new UUID(objectId));
	if objRef.GetObject() = undefined then
		return SabatexExchangeLogged.Error(conf,"Помилка отримання обєкта Довідника "+objectName + " з ID="+objectId);
	endif;
	return objRef;
endfunction

function GetChartOfCharacteristicTypesById(conf,objectName,objectId)
	if Sabatex.IsEmptyUUID(objectId) then
		return undefined;
	endif;	

	objRef =  ChartsOfCharacteristicTypes[objectName].GetRef(new UUID(objectId));
	if objRef.GetObject() = undefined then
		return SabatexExchangeLogged.Error(conf,"Помилка отримання обєкта ПланВидовХарактеристик "+objectName + " з ID="+objectId);
	endif;
	return objRef;
endfunction


// Обробка запитів до системи
procedure QyeryAnalize(conf,query) export
	try
	if IsQueryEnable(conf) then
		objectId = query["id"];
		objectType = query["type"];
		if objectId <> undefined and objectType <> undefined then
			object = undefined;
			if SabatexExchange.IsCatalog(objectType) then
				object = GetCatalogById(conf,GetObjectTypeKind(conf,objectType),objectId);
			elsif SabatexExchange.IsDocument(objectType) then
				object = GetDocumentById(conf,GetObjectTypeKind(conf,objectType),objectId);
			elsif SabatexExchange.IsChartOfCharacteristicTypes(objectType) then
				object = GetChartOfCharacteristicTypesById(conf,GetObjectTypeKind(conf,objectType),objectId);
			else
				SabatexExchangeLogged.Error(conf,"Даний тип не підтримується - "+objectType);
			endif;
			if object <> undefined then
				SabatexExchange.RegisterObjectForNode(conf,object);		
			endif;
		else
			try
				Execute(conf.userDefinedModule+".QueryObject(conf,query,object)");
			except
				SabatexExchangeLogged.Error(conf,"Помилка виконання розширеного запиту до бази:"+ОписаниеОшибки() );
			endtry;
		endif;
 	else
		SabatexExchangeLogged.Error(conf,"Обробка запитів для даного нода заборонена!");
	endif;
except
	  SabatexExchangeLogged.Error(conf,"Не передбачена помилка при виконанны аналізу запиту обєкта !"+ОписаниеОшибки());
	endtry;
endprocedure	
