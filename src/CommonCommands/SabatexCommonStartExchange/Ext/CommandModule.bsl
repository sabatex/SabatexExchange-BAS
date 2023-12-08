&AtServer
Procedure DoExchangeAtServer()
	SabatexExchange.ExchangeProcess();
EndProcedure

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	//Вставити вміст обробника.
	//FormParameters = New Structure("", );
	//OpenForm("CommonForm.", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL);
	DoExchangeAtServer();
	ShowMessageBox(,"Ообмін з сервером sabatex завершено",5);
	
EndProcedure
