// Copyright (c) 2021-2024 by Serhiy Lakas
// https://sabatex.github.io

// Функция - Sabatex JSONSerialize
//
// Параметры:
//  object	 - 	 - 
// 
// Возвращаемое значение:
//   -  Серіалізований в строку обєкт 
//
function Serialize(object) export
	jsonWriter = new JSONWriter;
	jsonParams = new JSONWriterSettings(JSONLineBreak.None,,,,,,true);
	jsonWriter.SetString(jsonParams);
	if TypeOf(object) = Type("Structure")or TypeOf(object) = Type("Array")  then
		WriteJSON(jsonWriter,object);
	else
		XDTOSerializer.WriteJSON(jsonWriter,object,XMLTypeAssignment.Implicit);
	endif;
	return jsonWriter.Close();
endfunction

// Функция - Sabatex JSONDeserialize
//
// Параметры:
//  txt			 - string	 - JSON текст
//  datefields	 - array	 - список полів з типом Date
// 
// Возвращаемое значение:
//   - десеріалызований обєкт в Map
//
function Deserialize(txt,datefields = undefined) export
	if datefields = undefined then
		datefields = new array;
	endif;	
	
	jsonReader=Новый JSONReader;	
	jsonReader.SetString(txt);
	result = ReadJSON(jsonReader,true,datefields);
	if typeof(result) = type("Map") then
		objectXDTO = result.Get("#value");
		if objectXDTO <> undefined then
			return objectXDTO;
		endif;
	endif;
	return result;
endfunction	
