procedure RegisterObject(val object,val nodeName, val externalId) export

	reg = InformationRegisters.SabatexExchangeIds.CreateRecordManager();
	reg.NodeName  = Lower(nodeName);
	reg.ObjectType = SabatexExchangeConfig.GetNormalizedObjectType(object.Ref.Метаданные().FullName()); 
	reg.objectRef = externalId;
	reg.InternalObjectRef = object.Ref.UUID();
 	reg.Write(true);
endprocedure	