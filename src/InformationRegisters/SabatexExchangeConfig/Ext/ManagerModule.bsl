function GetValue(key) export
	reg = InformationRegisters.SabatexExchangeConfig.Get(new structure("Key",key));
	return reg.Value;	
endfunction

procedure SetValue(Key,Value) export
	reg = InformationRegisters.SabatexExchangeConfig.CreateRecordManager();
	reg.Key = Key;
	reg.Value  = Value;
	reg.Write(true);
endprocedure	


