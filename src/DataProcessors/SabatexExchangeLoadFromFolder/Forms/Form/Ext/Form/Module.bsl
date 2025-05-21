
&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	nodes = SabatexExchange.GetActiveDestinationNodes();
	for each node in nodes do
		Items.NodeSelector.ChoiceList.Add(node);
	EndDo;

EndProcedure

&AtServer
procedure AddUnresolvedObject(nodeName,objectType,id,json)
	messageHeader = SabatexExchange.GetObjectHeader(objectType,id);
	reg = InformationRegisters.sabatexExchangeUnresolvedObjects.CreateRecordManager();
	//reg.sender = new UUID(item["sender"]);
	reg.MessageHeader = messageHeader;

	reg.dateStamp = CurrentDate();
	reg.serverDateStamp= CurrentDate();
	reg.senderDateStamp =CurrentDate();
	reg.objectAsText = json;
	reg.NodeName = nodeName;
	reg.Log = "Завантажено з файла";
	reg.Write();
endprocedure
	

&AtClient
Procedure LoadData(Command)
	folder =   new File(Object.FolderName);
	
	if not folder.Exists() then
		Message("Не знайдено каталог - " + Object.FolderName);
		return;
	endif;	
	
	for each file in FindFiles(Object.FolderName,"*.json") do
	   spacePos = StrFind(file.Name," ");	
	   objectType =	Mid(file.Name,1,spacePos-1);
	   id = Mid(file.Name,spacePos+1);
	   id = Mid(id,1,StrFind(id,".")-1);
	   t = new TextDocument;
	   t.Read(file.FullName);
	   
       AddUnresolvedObject(Object.NodeName,objectType,id,t.GetText());
	enddo;	


EndProcedure
