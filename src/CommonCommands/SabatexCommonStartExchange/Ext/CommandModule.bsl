&AtServer
Procedure DoExchangeAtServer(error)
	SabatexExchange.ExchangeProcess(Enums.SabatexExchangeMode.Manual,error);
EndProcedure

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	//Вставити вміст обробника.
	//FormParameters = New Structure("", );
	//OpenForm("CommonForm.", FormParameters, CommandExecuteParameters.Source, CommandExecuteParameters.Uniqueness, CommandExecuteParameters.Window, CommandExecuteParameters.URL);
	result = "";
	DoExchangeAtServer(result);
	message = "Ообмін з сервером sabatex завершено" + Символы.ПС + result;
	ShowMessageBox(,message,20);
EndProcedure
