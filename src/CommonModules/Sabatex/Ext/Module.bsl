#region Sabatex
// Copyright (c) 2021 by Serhiy Lakas
// https://sabatex.github.io
// version 1.0.0


function DateAddDay(value,count = 1) export
	return value + count*86400;
endfunction

function DateAddHour(value,count = 1) export
	return value + count*3600;
endfunction	

function DateAddMinute(value,count = 1) export
	return value + count*60;
endfunction	

function StringStartWith(value,searchString) export
	return StrFind(value,searchString)=1;
endfunction

function StringSplit(value,delimiter=";",includeEmpty=true) export
	
	if StrLen(delimiter) <> 1 then
		raise "Роздільник має бути тільки 1 символ.";
	endif;	
	
	result = new array;
	position = 1;
	success = true;
	while success do
		nextPosition =  StrFind(value,delimiter,position);
		if nextPosition = 0 then
			success = false;
			continue;
		endif;
		count =  nextPosition - position;
		if count = 0 then
			if includeEmpty then
				result.Add("");
			endif;	
			position = position + 1;
			continue;
		endif;
		result.Add(Mid(value,position,count));
		position = position + count +1;
	enddo;
	return result;
endfunction	
	

#endregion