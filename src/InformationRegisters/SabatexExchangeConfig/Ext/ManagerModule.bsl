function GetValue(key) export
	reg = InformationRegisters.SabatexExchangeConfig.Get(new structure("Key",key));
	return reg.Value;	
endfunction

function GetValueAsMap(key) export
	str = GetValue(key);
	return SabatexExchange.Deserialize(str);
endfunction	

procedure SetValue(Key,Value) export
	reg = InformationRegisters.SabatexExchangeConfig.CreateRecordManager();
	reg.Key = Key;
	reg.Value  = Value;
	reg.Write(true);
endprocedure	


procedure SetValueFromStructure(Key,Value) export
	reg = InformationRegisters.SabatexExchangeConfig.CreateRecordManager();
	reg.Key = Key;
	reg.Value  = SabatexExchange.Serialize(Value);
	reg.Write(true);
endprocedure	


