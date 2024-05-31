class TesteAI extends AIController 
{
  function Start();
  function BuyVehicles();
  function FindTown();
  function BuildAtTown(town);
  function HasStationAtTown(town);
  function BuildDepot();
  function SelectValidPax(depot);
}

function TesteAI::BuyVehicles(depot){
	local g = AIEngineList(AIVehicle.VT_ROAD);
	local v = g.Begin();
	for(local i = 0; !g.IsEnd(); i++){
		
		local isPax = AICargo.GetName(AIEngine.GetCargoType(v)) == "Passengers";
		if(!isPax){v = g.Next();continue;}
		
		AILog.Info("Tentando " + AIEngine.GetName(v));
		
		local attem = 0;
		local veh = AIVehicle.BuildVehicle(depot,v);
		while (!AIVehicle.IsValidVehicle(veh) && attem < 3){
			
			AILog.Info("tentando dnv (" + attem + ")");
			
			for(local u = 0; u < 15; u++){
				veh = AIVehicle.BuildVehicle(depot,v);
			}
			
			attem++;
		}
		AIVehicle.StartStopVehicle(veh);
		v = g.Next();
	}
}

function TesteAI::TrueFun(id){return true;}

function TesteAI::HasStationAtTown(town){
	local stations = AIStationList(AIStation.STATION_BUS_STOP);
	for(local station = stations.Begin(); !stations.IsEnd(); station = stations.Next()){
		local closest = AIStation.GetNearestTown(station);
		if(closest == town){
			return AIStation.GetLocation(station);
			AILog.Info("wtf");
		}
	}
	return null;
}

function TesteAI::SelectValidPax(depot){
	local vehicles = AIEngineList(AIVehicle.VT_ROAD);
	local vehicle = vehicles.Begin();
	for(local i = 0; !vehicles.IsEnd(); i++){
		local isPax = AICargo.GetName(AIEngine.GetCargoType(vehicle)) == "Passengers";
		if((!isPax) || AIEngine.GetCapacity(vehicle) < 30){vehicle = vehicles.Next();continue;}
		
		local actualVehicle = AIVehicle.BuildVehicle(depot, vehicle);
		if(!AIVehicle.IsValidVehicle(actualVehicle)){vehicle = vehicles.Next();continue;}
		return actualVehicle;
	}
	return null;
}

function TesteAI::BuildAtTown(town){
	local coord = AITown.GetLocation(town);
	local cx = AIMap.GetTileX(coord);
	local cz = AIMap.GetTileY(coord);
	local success = false;
	local tile = 0;
		
	for(local r = 0; r < 4; r++){
		for(local x = -4; x < 4; x++){
				for(local z = -4; z < 4; z++){
					local tileToTry = AIMap.GetTileIndex(cx+r*x,cz+r*z);
					if(!AIRoad.IsRoadTile(tileToTry) || success){continue;}
					local t1 = AIMap.GetTileIndex(cx+x+1,cz+z);
					local t2 = AIMap.GetTileIndex(cx+x-1,cz+z);
					local t3 = AIMap.GetTileIndex(cx+x,cz+z+1);
					local t4 = AIMap.GetTileIndex(cx+x,cz+z-1);
					
					success = success || AIRoad.BuildDriveThroughRoadStation(tileToTry,t1,AIRoad.ROADVEHTYPE_BUS,AIStation.STATION_NEW);
					success = success || AIRoad.BuildDriveThroughRoadStation(tileToTry,t2,AIRoad.ROADVEHTYPE_BUS,AIStation.STATION_NEW);
					success = success || AIRoad.BuildDriveThroughRoadStation(tileToTry,t3,AIRoad.ROADVEHTYPE_BUS,AIStation.STATION_NEW);
					success = success || AIRoad.BuildDriveThroughRoadStation(tileToTry,t4,AIRoad.ROADVEHTYPE_BUS,AIStation.STATION_NEW);
					if(success){return tileToTry;}
				}
			}
		}
	return null;
}

function TesteAI::BuildRoutes(depot){
	local towns = AITownList(this.TrueFun);
	local townFromRoute = towns.Begin();
	
	while(!towns.IsEnd()){
		local towns2 = AITownList(this.TrueFun);
		local townToRoute = towns2.Begin();
			
		while(!towns2.IsEnd()){
			
			if(townFromRoute == townToRoute){townToRoute = towns2.Next();}
			
			local stationFrom = this.HasStationAtTown(townFromRoute);
			while(stationFrom == null){stationFrom = this.BuildAtTown(townFromRoute);}

			local stationTo = this.HasStationAtTown(townToRoute);
			while(stationTo == null){stationTo = this.BuildAtTown(townToRoute);}
			
			while(!AIStation.IsValidStation(AIStation.GetStationID(stationFrom))){
				stationFrom = this.HasStationAtTown(townFromRoute);
			}
			
			while(!AIStation.IsValidStation(AIStation.GetStationID(stationTo))){
				stationTo = this.HasStationAtTown(townToRoute);
			}
			
			//AILog.Info("FR ->" + AIStation.GetName(AIStation.GetStationID(stationFrom)));
			//AILog.Info("DT ->" + AIStation.GetName(AIStation.GetStationID(stationTo)));
			
			//if(!AIRoad.AreRoadTilesConnected(stationFrom,stationFrom)){
			//	townToRoute = towns2.Next();
			//	continue;
			//}			
			
			local vehicle = this.SelectValidPax(depot);
			if(vehicle == null){
				this.Sleep(10);
				continue;
			}
			
			AILog.Info(AITown.GetName(townFromRoute) + " -> " + AITown.GetName(townToRoute));
		
			AIOrder.AppendOrder(vehicle, stationFrom, AIOrder.OF_NONE);
			AIOrder.AppendOrder(vehicle, stationTo, AIOrder.OF_NONE);
			AIVehicle.StartStopVehicle(vehicle);
			
			townToRoute = towns2.Next();
		}
		townFromRoute = towns.Next();
		
	}
	return 0;
}

function TesteAI::BuildDepot(){
	local towns = AITownList(this.TrueFun);
	local t = towns.Begin();
	local loc = AITown.GetLocation(t);
	local cx = AIMap.GetTileX(loc), cy = AIMap.GetTileY(loc);
	
	for(local r = 1; r < 20; r++){
		for(local x = 0; x < 20; x++){
			for(local y = 0; y < 20; y++){
				local dcx = cx + (r * x); local dcy = cy + (r * y);
				local tile = AIMap.GetTileIndex(dcx,dcy);
				
				local t1 = AIMap.GetTileIndex(dcx+1,dcy);
				local t2 = AIMap.GetTileIndex(dcx-1,dcy);
				local t3 = AIMap.GetTileIndex(dcx,dcy+1);
				local t4 = AIMap.GetTileIndex(dcx,dcy-1);
				
				if(
					(AIRoad.IsRoadTile(t1) && AIRoad.BuildRoadDepot(tile,t1)) ||
					(AIRoad.IsRoadTile(t2) && AIRoad.BuildRoadDepot(tile,t2)) ||
					(AIRoad.IsRoadTile(t3) && AIRoad.BuildRoadDepot(tile,t3)) ||
					(AIRoad.IsRoadTile(t4) && AIRoad.BuildRoadDepot(tile,t4))
				){	
					AILog.Info("Deposito criado em "+ AITown.GetName(t) + ": " + tile);
					AIRoad.BuildRoad(tile,t1); AIRoad.BuildRoad(tile,t2);
					AIRoad.BuildRoad(tile,t3); AIRoad.BuildRoad(tile,t4); 
					return tile;
				}
			}
		}
		return 0X0;
	}
}

function TesteAI::Start() {
	local teste = 1;
	AICompany.SetName("Mega2223 Inc.");
  
	AILog.Info("Rodando na " + AIController.GetVersion());
  
	AIRoad.SetCurrentRoadType (AIRoad.ROADTYPE_ROAD);
	
	local depot = BuildDepot();
	BuildRoutes(depot);
	
	this.Sleep(50);
	
	for(local i = 0; i < 20; i++){
		//this.BuyVehicles(depot);
	}
	
	while (true) {
		AILog.Info("Tick " + this.GetTick());
		
		this.Sleep(50);
	}
}