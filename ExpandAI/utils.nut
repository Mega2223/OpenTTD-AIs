class EAIUtils {
	function GetCargoTypeFromName(name);
}

function EAIUtils::GetCargoTypeFromName(name){
	local cargoList = AICargoList();
	for(local cargo = cargoList.Begin(); !cargoList.IsEnd(); cargo = cargoList.Next()){
		if(AICargo.GetName(cargo) == name){return cargo;}
	}
	return null;
}

//local Utils = EAIUtils();