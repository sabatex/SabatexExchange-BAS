
&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	ObjectRef = Параметры.ObjectRef;
	SabatexExchangeId = Параметры.ObjectRef.SabatexExchangeId;
КонецПроцедуры

&НаСервереБезКонтекста
function SaveНаСервере(sabatex1C77Id,objectRef)
	obj = objectRef.GetObject(); 
	try 
		SabatexExchangeId = new UUID(sabatex1C77Id);	
		obj.SabatexExchangeId = SabatexExchangeId;
		obj.write();
		return undefined;
	except
		return ErrorDescription();
	endtry;
endfunction

&НаКлиенте
Процедура Save(Команда)
	result = SaveНаСервере(SabatexExchangeId,Параметры.ObjectRef);
	Close();
КонецПроцедуры

&НаСервереБезКонтекста
function CleanValueAtServer(objectRef)
	obj = objectRef.GetObject(); 
	try 
		obj.SabatexExchangeId = Sabatex.GetEmptyUUID();
		obj.write();
		return undefined;
	except
		return ErrorDescription();
	endtry;
endfunction

&AtClient
Procedure CleanValue(Command)
	r = Вопрос("Ви впевнені що хочете скинути привязку даного елемента?", РежимДиалогаВопрос.ДаНет, 0, КодВозвратаДиалога.Да, Параметры.ObjectRef);	
	if r =  КодВозвратаДиалога.Да then
		CleanValueAtServer(Параметры.ObjectRef);
	endif;
	
	Close();
EndProcedure
