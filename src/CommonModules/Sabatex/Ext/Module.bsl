// Copyright (c) 2021-2024 by Serhiy Lakas
// https://sabatex.github.io
#region CommonMethods
// Функция - Value or default
//
// Параметры:
//  value	 - any type	 - 
//  default	 - any type	 - 
// 
// Возвращаемое значение:
//   -  as value
//
function ValueOrDefault(value,default) export
	if typeof(default)=type("Number") then
		return ?(value=undefined or value="",default,Number(value));
	elsif  typeof(default)=type("Boolean") then
		return ?(value=undefined or value="",default,value);
	elsif  typeof(default)=type("String") then
		return ?(value=undefined or value="",default,value);
	else
		return ?(value=undefined,default,value);
	endif;	
endfunction


procedure SetSenderValueIfDestinationEmpty(valueName,sender,destination)
	var propValue;
	if sender.Property(valueName,propValue) then
		if not destination.Property(valueName) then
			destination.Insert(valueName,sender[ValueName]);
		endif;	
	endif	
endprocedure
procedure FillStructFromSenderIsEmpty(sender,destination)
	for each item in sender do
		SetSenderValueIfDestinationEmpty(string(item.key),sender,destination);
	enddo;	
endprocedure

function StringStartWith(value,searchString) export
	return StrFind(value,searchString)=1;
endfunction

function DateAddDay(value,count = 1) export
	return value + count*86400;
endfunction

function DateAddHour(value,count = 1) export
	return value + count*3600;
endfunction	

function DateAddMinute(value,count = 1) export
	return value + count*60;
endfunction	
function DigitStrCompare(str1,str2)
	val1 = Число(str1);
	val2 = Число(str2);
	if val1 > val2 then
		return 1;
	elsif val1< val2 then
		return -1;
	else
		return 0;
	endif;	
endfunction

// Функция - Get empty UUID as string
// 
// Возвращаемое значение:
//   -   UUID в вигляды строки  00000000-0000-0000-0000-000000000000
//
function GetEmptyUUIDAsString() export
	return "00000000-0000-0000-0000-000000000000";
endfunction	

// Функция - Get empty UUID
// 
// Возвращаемое значение:
//   -  new UUID("00000000-0000-0000-0000-000000000000")
//
function GetEmptyUUID() export
	return new UUID(GetEmptyUUIDAsString());
endfunction


// Перевірка на пустий UUID
//  - value (UUID or string)
function IsEmptyUUID(value) export
	if TypeOf(value) = type("UUID") then
		return value = GetEmptyUUID();
	elsif TypeOf(value) = type("string") then
		return new UUID(value) = GetEmptyUUID();
	else
		raise("Неправильний тип value");
	endif;	
endfunction	


//function StringSplit(value,delimiter=";",includeEmpty=true) export
//	
//	if StrLen(delimiter) <> 1 then
//		raise "Роздільник має бути тільки 1 символ.";
//	endif;	
//	
//	result = new array;
//	position = 1;
//	success = true;
//	while success do
//		nextPosition =  StrFind(value,delimiter,position);
//		if nextPosition = 0 then
//			success = false;
//			continue;
//		endif;
//		count =  nextPosition - position;
//		if count = 0 then
//			if includeEmpty then
//				result.Add("");
//			endif;	
//			position = position + 1;
//			continue;
//		endif;
//		result.Add(Mid(value,position,count));
//		position = position + count +1;
//	enddo;
//	return result;
//endfunction

// порівняння двох версій шаблону 0.0.0
//	- ver1 
//  - ver2
//result
//	- 0   ver1 = ver2
//  - 1   ver1 > ver2
//  - -1  ver1 < ver2
//function VersionCompare(ver1,ver2) export
//	ver1arr = StringSplit(ver1,".",false);
//	ver2arr = StringSplit(ver2,".",false);
//	if ver1arr.Количество() <> 3 then
//		raise "Арнумент 1 не того формату ver1=" + ver1 + " шаблон 0.0.0";
//	endif;	
//	if ver1arr.Количество() <> 3 then
//		raise "Арнумент 2 не того формату ver2=" + ver1 + " шаблон 0.0.0";
//	endif;	
//	for i=0 to 2 do
//		r = DigitStrCompare(ver1arr[i],ver2arr[i]);
//		if r <> 0 then
//			return r;
//		endif;
//	enddo;
//	return 0;
//endfunction

//function ItemOrDefault(items,itemName,default) export
//	return ValueOrDefault(items[itemName],default);	
//endfunction	

#endregion

