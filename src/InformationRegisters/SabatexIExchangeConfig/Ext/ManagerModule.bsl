function GetValue(key) export
	reg = InformationRegisters.SabatexIExchangeConfig.Get(new structure("Key",key));
	return reg.Value;	
endfunction

procedure SetValue(Key,Value) export
	reg = InformationRegisters.SabatexIExchangeConfig.CreateRecordManager();
	reg.Key = Key;
	reg.Value  = Value;
	reg.Write(true);
endprocedure	