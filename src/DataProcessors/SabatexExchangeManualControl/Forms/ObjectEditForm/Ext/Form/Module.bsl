
&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	ObjectRef = Параметры.ObjectRef;
	SabatexExchangeId = Параметры.ObjectRef.SabatexExchangeId;
КонецПроцедуры

&НаСервереБезКонтекста
Процедура SaveНаСервере(sabatex1C77Id,objectRef)
	obj = objectRef.GetObject(); 
	try 
		SabatexExchangeId = new UUID(sabatex1C77Id);	
		obj.SabatexExchangeId = sabatex1C77Id;
		obj.write();
	except
	endtry;
КонецПроцедуры

&НаКлиенте
Процедура Save(Команда)
	SaveНаСервере(SabatexExchangeId,Параметры.ObjectRef);
	Close();
КонецПроцедуры
