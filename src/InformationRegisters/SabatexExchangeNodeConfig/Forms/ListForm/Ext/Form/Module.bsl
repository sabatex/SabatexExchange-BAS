
&AtServerNoContext
Процедура SaveNodeConfigНаСервере(https,host,port,clientId,password)
	nodeConfig = new structure;
	nodeConfig.Insert("clientId",clientId);
	nodeConfig.Insert("https",https);
	nodeConfig.Insert("Host",Host);
	nodeConfig.Insert("Port",Port);
	nodeConfig.Insert("password",password);
	SabatexExchangeConfig.SetHostConfig(nodeConfig,Enums.SabatexExchangeNodeType.Sabatex);
КонецПроцедуры

&НаКлиенте
Процедура SaveNodeConfig(Команда)
	SaveNodeConfigНаСервере(https,Host,Port,clientId,password);
КонецПроцедуры

&НаСервере
Процедура ПриСозданииНаСервере(Отказ, СтандартнаяОбработка)
	nodeConfig = SabatexExchangeConfig.GetHostConfig(Enums.SabatexExchangeNodeType.Sabatex);
	clientId = nodeConfig.clientId;
	https = nodeConfig.https;
	Host = nodeConfig.Host;
	Port = nodeConfig.Port;
	password = nodeConfig.password;
КонецПроцедуры
