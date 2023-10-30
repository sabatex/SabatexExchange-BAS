
&AtServerNoContext
Procedure DoExchangeAtServer()
	SabatexExchange.ExchangeProcess();
EndProcedure

&AtClient
Procedure DoExchange(Command)
	DoExchangeAtServer();
EndProcedure
