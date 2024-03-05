&AtServer
function DoExchangeAtServer()
	return SabatexExchange.ExchangeProcess(Enums.SabatexExchangeMode.Manual);
EndFunction

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	result = DoExchangeAtServer();
	message = "Ообмін з сервером sabatex завершено" + Символы.ПС + result;
	ShowMessageBox(,message,20);
EndProcedure
