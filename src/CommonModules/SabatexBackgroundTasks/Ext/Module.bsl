
procedure SendMessage(text)
	message = new UserMessage;
	message.Text = text;
	message.Message();

endprocedure	

procedure UnPostedAsync(items,actionType) export
	success = 0;
	unsuccess = 0;
	for each item in items do
		if actionType = "UnPost" then
			if not item.Posted then
				success = success +1;
				SendMessage("Документ не потребує розпроведення "+item);
	            continue;
			endif;
		endif;
		
		try
			obj = item.GetObject();
			if actionType = "UnPost" then 
				obj.Write(РежимЗаписиДокумента.ОтменаПроведения);
				SendMessage("Розпроведено документ "+item);
			elsif actionType = "Delete" then
				SendMessage("Видаляю документ "+item);
				obj.Delete();
			endif;
			
			success = success +1;
		except
			if actionType = "UnPost" then 
				SendMessage("Не вдалось зняти проведення з документа "+item);
			elsif actionType = "Delete" then
				SendMessage("Не вдалось видалити документ");
			endif;
 			unsuccess = unsuccess+1;
		endtry;
	enddo;
	SendMessage("Успішно -  "+success + "  невдача -"+unsuccess);
endprocedure
