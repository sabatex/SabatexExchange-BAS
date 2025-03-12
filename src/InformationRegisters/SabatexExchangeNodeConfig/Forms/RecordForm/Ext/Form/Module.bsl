&AtServer
Procedure UpdateVisibility()
	if Record.NodeType = Enums.SabatexExchangeNodeType.USAP then
		Items.USAPLoginGroup.Visible = true;
		Items.destinationId.Visible = false;
	else
		Items.USAPLoginGroup.Visible = false;
		Items.destinationId.Visible = true;
	endif;
   
EndProcedure



&AtServer
Procedure OnReadAtServer(CurrentObject)
	if CurrentObject.NodeType = Enums.SabatexExchangeNodeType.USAP then
		hostConf = SabatexExchange.GetHostConfig(Enums.SabatexExchangeNodeType.USAP,CurrentObject.NodeName);
		host = hostConf.host;
		login = hostConf.login;
		password = hostConf.password;
		cid = hostConf.cid;
	endif;	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	Title = Record.NodeName;
	UpdateVisibility();
	if Record.NodeType = Enums.SabatexExchangeNodeType.EmptyRef() then
		Record.NodeType = Enums.SabatexExchangeNodeType.Sabatex;
	endif;
EndProcedure

&AtClient
Procedure NodeNameOnChange(Item)
EndProcedure

&AtClient
Procedure NodeTypeOnChange(Item)
	UpdateVisibility();
EndProcedure

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	if CurrentObject.NodeType = Enums.SabatexExchangeNodeType.USAP then
		result = new structure;
		result.Insert("cid",SabatexExchange.ValueOrDefault(cid,true));
		result.Insert("Host",SabatexExchange.ValueOrDefault(Host,""));
		result.Insert("login",SabatexExchange.ValueOrDefault(login,""));
		result.Insert("password",SabatexExchange.ValueOrDefault(password,""));
		SabatexExchange.SetHostConfig(result,CurrentObject.NodeType,Record.NodeName);
	endif;	
EndProcedure
