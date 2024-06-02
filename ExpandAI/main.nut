class ExpandAI extends AIController 
{

  radius = 10;
  town = 0;
  depot = 0;
  
  function Start();
  function SelectRandomTown();
  function FindTown();
  function BuildAtTown(town);
  function HasStationAtTown(town);
  function BuildDepot();
  function SelectValidPax(depot);
  function Expand();
  function GetTownsNearRadius();
  function HasPaxRoute();
  
  routes = null;
  
  constructor(){
	routes = []
  }
  
}



function  ExpandAI::SelectRandomTown(){
	local towns = AITownList(this.TrueFun);
	local rand = AIBase.RandRange(towns.Count());
	local t =towns.Begin();
	
	for(local i = 0; i < towns.Count(); i++){
	if(i == rand){return t;}
		t = towns.Next();
	}
	
	return -1;
}

function ExpandAI::TrueFun(id){return true;}

function ExpandAI::HasStationAtTown(town){
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

function ExpandAI::SelectValidPax(depot){
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

function ExpandAI::BuildAtTown(town){
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

function ExpandAI::BuildRoute(town1, town2){
	AILog.Info(AITown.GetName(town1) + " -> " + AITown.GetName(town2));
	

	local stationFrom = this.HasStationAtTown(town1);
	while(stationFrom == null){stationFrom = this.BuildAtTown(town1);}

	local stationTo = this.HasStationAtTown(town2);
	while(stationTo == null){stationTo = this.BuildAtTown(town2);}
		
	while(!AIStation.IsValidStation(AIStation.GetStationID(stationFrom))){
		stationFrom = this.HasStationAtTown(town1);
	}
		
	while(!AIStation.IsValidStation(AIStation.GetStationID(stationTo))){
		stationTo = this.HasStationAtTown(town2);
	}
		
	local vehicle = this.SelectValidPax(depot);
	while(vehicle == null){
		this.Sleep(10);
		vehicle = this.SelectValidPax(depot);
		//AILog.Info("n deu");
		continue;
	}
	AIOrder.AppendOrder(vehicle, stationFrom, AIOrder.OF_NON_STOP_FLAGS);
	AIOrder.AppendOrder(vehicle, stationTo, AIOrder.OF_NON_STOP_FLAGS);
	AIVehicle.StartStopVehicle(vehicle);
	
	this.routes.append([town1,town2]);
	return vehicle;
}

function ExpandAI::BuildDepot(town){
	
	local loc = AITown.GetLocation(town);
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
					AILog.Info("Deposito criado em "+ AITown.GetName(this.town) + ": " + tile);
					AIRoad.BuildRoad(tile,t1); AIRoad.BuildRoad(tile,t2);
					AIRoad.BuildRoad(tile,t3); AIRoad.BuildRoad(tile,t4); 
					return tile;
				}
			}
		}
		return 0X0;
	}
}

function ExpandAI::GetTownsNearRadius(tileIndex,radius){
	local IsTownUnderRadius = function(town_id,tileIndex,radius){
		return AIMap.DistanceSquare(AITown.GetLocation(town_id),tileIndex) <= radius;
	};
	return AITownList(IsTownUnderRadius,tileIndex,radius);
}

function ExpandAI::HasPaxRoute(town1, town2){
	for(local i = 0; i < this.routes.len(); i++){
		if(this.routes[i][0] == town1 && this.routes[i][1] == town2){return true;}
		if(this.routes[i][1] == town1 && this.routes[i][0] == town2){return true;}
	}
	return false; //TODO
}

function ExpandAI::Expand(radius){
	local towns = this.GetTownsNearRadius(AITown.GetLocation(this.town),radius);
	towns.RemoveItem(this.town);
	
	local town = towns.Begin();
	while(!towns.IsEnd()){
		local townsNearTown = this.GetTownsNearRadius(AITown.GetLocation(town),radius/2);
		townsNearTown.RemoveItem(this.town);
		townsNearTown.RemoveItem(town);
		
		if(townsNearTown.Count() <= 1){town = towns.Next(); continue;}
		
		local currentTown = townsNearTown.Begin();
		
		while(!townsNearTown.IsEnd()){
			//AILog.Info("THE G");
			if(this.HasPaxRoute(town,currentTown)){
				currentTown = townsNearTown.Next();
				continue;
			}
			
			this.BuildRoute(town,currentTown);
			currentTown = townsNearTown.Next();
		}
		
		town = towns.Next();
	}
}

function ExpandAI::Start() {
	AICompany.SetName("Mega2223 Inc.");
  
	AILog.Info("Rodando na " + AIController.GetVersion());
  
	AIRoad.SetCurrentRoadType (AIRoad.ROADTYPE_ROAD);
	
	this.town = SelectRandomTown();
	this.depot = BuildDepot(this.town);
	//BuildRoutes(depot);
	
	this.Sleep(50);
	
	while (true) {
		//AILog.Info("Tick " + this.GetTick());
		AILog.Info("Radius = " + this.radius)
		//AILog.Info("THE G");
		this.Expand(radius);
		this.Sleep(1);
		this.radius+=300;
	}
}