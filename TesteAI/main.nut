class TesteAI extends AIController 
{
  function Start();
}

function TesteAI::Start() {
	local teste = 1;
	AICompany.SetName("Mega2223 Inc.");
  
  
	AILog.Info("Rodando na " + AIController.GetVersion());
  
	AIRoad.SetCurrentRoadType (AIRoad.ROADTYPE_ROAD);
	//AILog.Info(AIRoad.BuildRoad(0X185658,0X185659));
	local depot = 0X237FAA;
	AIRoad.BuildRoadDepot(depot,0X238FAA);
	AIRoad.BuildRoad(0X2387AA,depot)
  
	local g = AIEngineList(AIVehicle.VT_ROAD);
	local v = g.Begin();
	this.Sleep(100);
	
	for(local i = 0; !g.IsEnd(); i++){
		AILog.Info(v);
		v = g.Next();
		local attem = 0;
		local veh = AIVehicle.BuildVehicle(depot,v);
		while (!AIVehicle.IsValidVehicle(veh) && attem < 3){
			//this.Sleep(1);
			AILog.Info("tentando " + attem);
			veh = AIVehicle.BuildVehicle(depot,v);
			attem++;
		}
		AIVehicle.StartStopVehicle(veh);
	}
  
	while (true) {
		AILog.Info("Oi " + this.GetTick());
	
		this.Sleep(50);
	}
}