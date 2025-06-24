
&AtServerNoContext
function GetFileStruct(object)
	result = new structure("FileName,JSON");
	
	result.FileName = object.Ref.Метаданные().FullName()+" "+ XMLString(object.Ref.UUID())+".json";
	result.JSON= SabatexExchange.Serialize(object.GetObject());
	return result;
endfunction


&AtServer
function GetObjects()
	result = new array;
    shema = Items.Objects.GetPerformingDataCompositionScheme();
	template = Items.Objects.GetPerformingDataCompositionSettings();
	cm = new DataCompositionTemplateComposer();
	mc = cm.Execute(shema,template,,,Type("ГенераторМакетаКомпоновкиДанныхДляКоллекцииЗначений"));
	ПроцессорКомпоновкиДанных = Новый ПроцессорКомпоновкиДанных;
    ПроцессорКомпоновкиДанных.Инициализировать(mc);
	ПроцессорВыводаРезультата = Новый ПроцессорВыводаРезультатаКомпоновкиДанныхВКоллекциюЗначений;
    table = ПроцессорВыводаРезультата.Вывести(ПроцессорКомпоновкиДанных);// Таблица значений
	return table.UnloadColumn("Ref");
	
	
EndFunction


&AtClient
Procedure Download(Command)
	folder =   new File(Object.FolderName);
	
	if not folder.Exists() then
		Message("Не знайдено каталог - " + Object.FolderName);
		return;
	endif;	
	
	nodeFolder = Object.FolderName+"\"+Object.NodeName;
	folder = new File(nodeFolder);
	if not folder.Exists() then
		CreateDirectory(nodeFolder);
	else
		DeleteFiles(nodeFolder,"*.json");
	endif;
	objectsFolder = nodeFolder+"\"+Object.ObjectType;
	folder = new File(objectsFolder);
	if not folder.Exists() then
		CreateDirectory(objectsFolder);
	else
		DeleteFiles(objectsFolder,"*.json");
	endif;	

	try
		
		for each item in GetObjects() do
			
		f = GetFileStruct(item);
		ЗаписьТекста = Новый ЗаписьТекста;

    	// Открываем файл для записи
    	ЗаписьТекста.Открыть(objectsFolder+"\"+ f.FileName, КодировкаТекста.UTF8);

        // Записываем строку в файл
        ЗаписьТекста.ЗаписатьСтроку(f.JSON);

        // Закрываем файл
        ЗаписьТекста.Закрыть();
		//progress = progress +1;
	enddo;
except
	Message("Помилка вивантаження");

	endtry;

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	nodes = SabatexExchange.GetActiveDestinationNodes();
	for each node in nodes do
		Items.NodeName.ChoiceList.Add(node);
	EndDo;
	for each item in Metadata.Documents do
		Items.ObjectType.ChoiceList.Add(item.FullName());
	enddo;	
	
	for each item in Metadata.Catalogs do
		Items.ObjectType.ChoiceList.Add(item.FullName());
	enddo;	
	
	Object.ObjectType = Items.ObjectType.ChoiceList[0];
	
	Objects.QueryText = 
	"SELECT
	| Object.Ref AS Ref
    |FROM
	| " + Object.ObjectType + " AS Object";
	
	if Object.FolderName = "" then
		Object.FolderName = "C:\var\upload";
	endif;
		
EndProcedure

&AtServer
Procedure ObjectTypeOnChangeAtServer()
	Objects.QueryText = 
	"SELECT
	| Object.Ref AS Ref
    |FROM
	| " + Object.ObjectType + " AS Object";
	

EndProcedure

&AtClient
Procedure ObjectTypeOnChange(Item)
	ObjectTypeOnChangeAtServer();
EndProcedure


&AtServer
procedure beforeStartTask()
	Items.Download.Enabled = false;
	Items.UnPosted.Enabled = false;
	Items.UnsafeDelete.Enabled = false;
endprocedure

&AtServer
procedure EndTask()
	Items.Download.Enabled = true;
	Items.UnPosted.Enabled = true;
	Items.UnsafeDelete.Enabled = true;
endprocedure


&НаСервере
Процедура StartTask(actionType)
	filter = new structure("Key,State","9de14907-ec23-4a07-96f0-85521cb6b53b-task",BackgroundJobState.Active);
	task = BackgroundJobs.GetBackgroundJobs(filter);
	if task.Count() = 0  then
		params = new array;
		params.Add(GetObjects());
		params.Add(actionType);
		task = BackgroundJobs.Execute("SabatexBackgroundTasks.UnPostedAsync",params,"9de14907-ec23-4a07-96f0-85521cb6b53b-task");
		TaskUUID = task.UUID;
	else
		Message("Завдання уже запущено");
	endif;
	
КонецПроцедуры

&НаКлиенте
Процедура UnPosted(Команда)
	beforeStartTask();
	StartTask("UnPost"); 
КонецПроцедуры

&AtServer
procedure check_task()
	task = BackgroundJobs.FindByUUID(TaskUUID);
	events = task.GetUserMessages(true);
	for each taskMessage in events do
		Message(taskMessage.Текст);
	enddo;	

	if task.State = BackgroundJobState.Completed then
		TaskUUID = SabatexExchange.GetEmptyUUID();
		EndTask();
    endif;
endprocedure	


&AtClient
Procedure Подключаемый_ПроверитьВыполнениеЗадания()
	if TaskUUID = SabatexExchange.GetEmptyUUID() then
		return;
	endif;	
	check_task();	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	ПодключитьОбработчикОжидания("Подключаемый_ПроверитьВыполнениеЗадания", 1);
EndProcedure

&AtClient
Procedure UnsafeDelete(Command)
	beforeStartTask();
	StartTask("Delete"); 
EndProcedure


