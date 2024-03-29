// Copyright (c) 2021-2024 by Serhiy Lakas
// https://sabatex.github.io
 
#region Logged
procedure SystemLog(logLevel,message)
	WriteLogEvent("SabatexExchange",logLevel,,,message);
endprocedure	
procedure SystemLogError(message) export
	WriteLogEvent("SabatexExchange",EventLogLevel.Error,,,message);
endprocedure	

// Процедура - Логування 
//
// Параметры:
//  conf			 - structure	 - 
//  level			 - integer	 -  0 Error,1 Warning,2 Information,3-9 Note
//  sourceName		 - string	 - 
//  message			 - string	 -  Повідомлення
//  isJournalWrite	 - boolean	 -  Чи проводити запис в загальний лог
//
procedure Logged(conf,level,sourceName,message,isJournalWrite)
	if level <= conf.LogLevel then
		conf.Log = conf.Log + message + Символы.ПС;
		if isJournalWrite then
			if level = 0 then
				logLevel = EventLogLevel.Error;
			elsif level=1 then
				logLevel = EventLogLevel.Warning;
			elsif level=2 then
				logLevel = EventLogLevel.Information;
			else
				logLevel = EventLogLevel.Note;
			endif;	
			
			WriteLogEvent("SabatexExchange",logLevel,sourceName,,message);
		endif;
	endif;
endprocedure
// Процедура - Sabatex log error
//
// Параметры:
//  conf	 - structure - LogLevel - рівень логування, Log - додаэться поточний лог 
//  message	 - 	 - 
//
procedure Error(conf,message,isJournalWrite=false) export
	conf.success = false;
	Logged(conf,0,"",message,isJournalWrite);		
endprocedure	
// Процедура - Sabatex log warning
//
// Параметры:
//  conf	 - 	 - 
//  message	 - 	 - 
//
procedure Warning(conf,message,isJournalWrite=false) export
	Logged(conf,1,"",message,isJournalWrite);		
endprocedure
// Процедура - Sabatex log information
//
// Параметры:
//  conf	 - 	 - 
//  message	 - 	 - 
//
procedure Information(conf,message,isJournalWrite=false) export
	Logged(conf,2,"",message,isJournalWrite);		
endprocedure
// Процедура - Sabatex log note
//
// Параметры:
//  conf	 - 	 - 
//  message	 - 	 - 
//
procedure Note(conf,message,isJournalWrite=false) export
	Logged(conf,3,"",message,isJournalWrite);		
endprocedure
#endregion

