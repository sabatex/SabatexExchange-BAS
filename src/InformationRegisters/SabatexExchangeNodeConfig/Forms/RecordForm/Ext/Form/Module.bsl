
&AtServer
Procedure OnReadAtServer(CurrentObject)
	// Вставити вміст обробника.
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Title = Record.NodeName;   
EndProcedure

&AtClient
Procedure NodeNameOnChange(Item)
	EndProcedure
