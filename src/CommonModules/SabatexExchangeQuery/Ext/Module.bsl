// Copyright (c) 2021-2024 by Serhiy Lakas
// https://sabatex.github.io


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
			
			if Sabatex.IsEmptyUUID(objectId) then
				SabatexExchangeLogged.Error("Передано хибний запит з пустим Id");
				return;
			endif;	

			object = undefined;
			objectManager = SabatexExchange.GetObjectManager(objectType);
			objectRef = objectManager.GetRef(new UUID(objectId));
			if objectRef.GetObject() = undefined then
				SabatexExchangeLogged.Error(conf,"Помилка отримання обєкта " + objectType + " з ID="+objectId);
				return;
			endif;
			SabatexExchange.RegisterObjectForNode(conf,objectRef);		
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
