require("utils.nut");
require("route.nut");

local Utils = EAIUtils();

class ExpandAI extends AIController 
{

  radius = 0;
  town = 0;
  depot = 0;
  agressiveness = 0;
  
  function Start();
  function SelectRandomTown();
  function FindTown();
  function BuildPaxStationAtTown(town);
  function GetStationAtTown(town);
  function BuildDepot();
  function SelectValidPax(depot);
  function Expand();
  function GetTownsNearRadius();
  function HasPaxRoute(city1, city2);
  function DismantleUnprofitableRoutes();
  function GetPaxRouteFromVehicle(vehicle);
  function IsRouteBlacklisted(town1, town2);
  function WaitForFunds();
  
  routes = null;
  blacklistedRoutes = null;
  
  constructor(){
	this.routes = []; this.blacklistedRoutes = [];
	if(agressiveness == 0){
		agressiveness = AIBase.RandRange(9)+1;
		if(AIBase.RandRange(2) == 0){this.agressiveness *= -1;}
	}
	AILog.Info("Agressiveness = " + this.agressiveness);
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

function ExpandAI::GetStationAtTown(town){
	local stations = AIStationList(AIStation.STATION_BUS_STOP);
	for(local station = stations.Begin(); !stations.IsEnd(); station = stations.Next()){
		local closest = AIStation.GetNearestTown(station);
		if(closest == town){
			return station;
			//AILog.Info("wtf");
		}
	}
	return null;
}

function ExpandAI::IsRouteBlacklisted(town1, town2){
	for(local i = 0; i < this.blacklistedRoutes.len(); i++){
		local r = this.blacklistedRoutes[i];
		if((r.GetTownFrom() == town1 && r.GetTownTo() == town2) || (r.GetTownFrom() == town2 && r.GetTownTo() == town1)){return true;}
	}
	return false;
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

function ExpandAI::BuildPaxStationAtTown(town){
	local station = this.GetStationAtTown(town);
	if(station != null){return station;}
	local coord = AITown.GetLocation(town);
	local cx = AIMap.GetTileX(coord);
	local cz = AIMap.GetTileY(coord);
	local success = false;
	local tile = 0;
	AILog.Info("Building central pax at " + AITown.GetName(town));
	for(local r = 1; r < 16; r++){
		for(local x = 0; x < 32; x++){
				for(local z = 0; z < 32; z++){
					local tryX = x % 2 == 0 ? x/2 : -x/2;
					local tryZ = z % 2 == 0 ? z/2 : -z/2;
					local tileToTry = AIMap.GetTileIndex(cx+(r*tryX),cz+(r*tryZ));
					if(!AIRoad.IsRoadTile(tileToTry) || success){continue;}
					
					if(AICompany.GetBankBalance(AICompany.COMPANY_SELF) < 1000){
						AILog.Info("Not enough money :'(");
						return null;
					}
					
					local t1 = AIMap.GetTileIndex(cx+x+1,cz+z);
					local t2 = AIMap.GetTileIndex(cx+x-1,cz+z);
					local t3 = AIMap.GetTileIndex(cx+x,cz+z+1);
					local t4 = AIMap.GetTileIndex(cx+x,cz+z-1);
					
					success = success || AIRoad.BuildDriveThroughRoadStation(tileToTry,t1,AIRoad.ROADVEHTYPE_BUS,AIStation.STATION_NEW);
					success = success || AIRoad.BuildDriveThroughRoadStation(tileToTry,t2,AIRoad.ROADVEHTYPE_BUS,AIStation.STATION_NEW);
					success = success || AIRoad.BuildDriveThroughRoadStation(tileToTry,t3,AIRoad.ROADVEHTYPE_BUS,AIStation.STATION_NEW);
					success = success || AIRoad.BuildDriveThroughRoadStation(tileToTry,t4,AIRoad.ROADVEHTYPE_BUS,AIStation.STATION_NEW);
					if(success){
						AILog.Info("Built station " + AIStation.GetName(AIStation.GetStationID(tileToTry)));
						return AIStation.GetStationID(tileToTry);

					}
				}
			}
		}
	return null;
}

function ExpandAI::BuildRoute(town1, town2){
	
	local stationFrom = this.GetStationAtTown(town1);
	if(stationFrom == null){stationFrom = this.BuildPaxStationAtTown(town1);}
	
	local stationTo = this.GetStationAtTown(town2);
	if(stationTo == null){stationTo = this.BuildPaxStationAtTown(town2);}
	
	if(stationFrom == null || stationTo == null || !AIStation.IsValidStation(stationFrom) || !AIStation.IsValidStation(stationTo)){return null;}
	/*
	while(!AIStation.IsValidStation(AIStation.GetStationID(stationFrom))){
		stationFrom = this.GetStationAtTown(town1);
	}
		
	while(!AIStation.IsValidStation(AIStation.GetStationID(stationTo))){
		stationTo = this.GetStationAtTown(town2);
	}
	*/
	
	
	
	local route = EAIRoute(stationFrom,stationTo,"Passengers");
	local vehicle = route.BuyVehicle(null,this.depot);
	if(vehicle == null || !AIVehicle.IsValidVehicle(vehicle)){return null;}
	
	this.routes.append(route);
	AILog.Info("Built route " + route.AsString());
	return vehicle;
}

function ExpandAI::GetPaxRouteFromVehicle(vehicle){//TODO TODO TODO
	for(local i = 0; i < this.routes.len(); i++){
		if (this.routes[i][2] == vehicle){
			return this.routes[i];
		}
	}
	return null;
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
					AILog.Info("Built depot in "+ AITown.GetName(this.town) + ": " + tile);
					local hasConnected = AIRoad.BuildRoad(tile,t1) || AIRoad.BuildRoad(tile,t2) ||AIRoad.BuildRoad(tile,t3) || AIRoad.BuildRoad(tile,t4);
					if(!hasConnected){
						AILog.Info("Bad spot! Retrying...");
						AITile.DemolishTile(tile);
						continue;
					}
					return tile;
				}
			}
		}
		return 0X0;
	}
}

function ExpandAI::GetTownsNearRadius(tileIndex,radius){
	local IsTownUnderRadius = function(town_id,tileIndex,radius){
		return AIMap.DistanceMax(AITown.GetLocation(town_id),tileIndex) <= radius;
	};
	return AITownList(IsTownUnderRadius,tileIndex,radius);
}

function ExpandAI::HasPaxRoute(town1, town2){
	local station1 = this.GetStationAtTown(town1);
	local station2 = this.GetStationAtTown(town2);
	if(station1 == null || station2 == null){return false;}
	//TODO TODO TODO TODO 
	for(local i = 0; i < this.routes.len(); i++){
		local act = this.routes[i];
		if(act.cargo_type != "Passengers"){continue;}
		if(act.station_from == station1 && act.station_to == station2){return true;}
		if(act.station_to == station1 && act.station_from == station2){return true;}
	}
	return false; //TODO
}

function ExpandAI::Expand(radius){
	local towns = this.GetTownsNearRadius(AITown.GetLocation(this.town),radius);
	towns.RemoveItem(this.town);
	
	local town = towns.Begin();
	while(!towns.IsEnd()){
		local rang = this.agressiveness < 0 ? - radius / this.agressiveness : radius * this.agressiveness; 
	
		local townsNearTown = this.GetTownsNearRadius(AITown.GetLocation(town),rang);
		//townsNearTown.RemoveItem(this.town);
		townsNearTown.RemoveItem(town);
		
		if(townsNearTown.Count() <= 1){town = towns.Next(); continue;}
		
		local currentTown = townsNearTown.Begin();
		
		while(!townsNearTown.IsEnd()){
			//AILog.Info("THE G");
			if(this.HasPaxRoute(town,currentTown) || this.IsRouteBlacklisted(town,currentTown)){
				currentTown = townsNearTown.Next();
				continue;
			}
			
			local vehicle = this.BuildRoute(town,currentTown);
			currentTown = townsNearTown.Next();
			if(vehicle == null){return false;} else {return true;}
		}
		
		town = towns.Next();
	}
	return true;
}

function ExpandAI::GetVehicleRoute(vehicle){
	for(local r = 0; r < this.routes.len(); r++){
		local act = this.routes[r];
		if(act[2] == vehicle){return act;}
	}
	return null;
}

function ExpandAI::DismantleUnprofitableRoutes(){
	for(local r = 0; r < this.routes.len(); r++){
		local route = this.routes[r];
		if(route.Age() > 256 && route.ProfitsLastYear() < -200 && route.ProfitsThisYear() < -200){
			AILog.Info("Decomissioning route: " + route.AsString());
			route.Decomission();
			this.blacklistedRoutes.append(route);
			this.routes.remove(r);
			break;
		}
	}
	local vehicles = AIVehicleList();
	for(local v = vehicles.Begin();!vehicles.IsEnd(); v = vehicles.Next()){
		if(AIVehicle.IsStoppedInDepot(v)){
			local name = AIVehicle.GetName(v);
			AIVehicle.SellVehicle(v);
			AILog.Info(name + " sold");
		}
	}
}

function ExpandAI::ExpandRoutesAsNeeded(){
	for(local r = 0; r < this.routes.len(); r++){
		local route = this.routes[r];
		//AILog.Info(route.AsString() + ": " + route.ProfitsLastYear() + " " + route.GetCargoWaitingAmount() + " " + route.YoungestAge());
		if(route.ProfitsLastYear() > 1000 && route.GetCargoWaitingAmount() > 750 && route.YoungestAge() > 180){
			AILog.Info("Expanding route: " + route.AsString());
			route.BuyVehicle(null,this.depot);
		}
	}
}

function ExpandAI::WaitForFunds(){
	local amountToKeep = AICompany.GetQuarterlyIncome(AICompany.COMPANY_SELF,AICompany.CURRENT_QUARTER)/3;
	amountToKeep = amountToKeep < 3000 ? 3000 : amountToKeep;
	local hasWaited = false;
	if(AICompany.GetBankBalance(AICompany.COMPANY_SELF) < amountToKeep){
		AILog.Info("Waiting for " + amountToKeep + " in funds");
		hasWaited = true;
	}
	
	while(AICompany.GetBankBalance(AICompany.COMPANY_SELF) < amountToKeep){
		this.Sleep(100);
		this.DismantleUnprofitableRoutes();
		if(AICompany.GetBankBalance(AICompany.COMPANY_SELF) > AICompany.GetLoanAmount() && AICompany.GetLoanAmount() > 0){
			AILog.Info("Paying Loan :D");
			AICompany.SetLoanAmount(0);
		}
	}
	
	if(hasWaited){
		AILog.Info("Wait done");
	}
}

function ExpandAI::Start() {
	AICompany.SetName("Mega2223 Inc. " + this.agressiveness);
  
	AILog.Info("Rodando na " + AIController.GetVersion());
  
	AIRoad.SetCurrentRoadType(AIRoad.ROADTYPE_ROAD);
	
	this.town = SelectRandomTown();
	this.depot = BuildDepot(this.town);
	//BuildRoutes(depot);
	
	this.Sleep(50);
	local count = 0;
	
	while (true) {
		this.WaitForFunds();
		this.DismantleUnprofitableRoutes();
		this.ExpandRoutesAsNeeded();
		//AILog.Info("Tick " + AIController.GetTick());
		
		if(this.Expand(radius)){
			local addValue = this.radius / 150;//this.radius/50;
			if(this.radius <= AIMap.GetMapSizeX()*10 && this.radius <= AIMap.GetMapSizeY()*10){
				this.radius += addValue > 0 ? addValue : 1;
				if(count%10 == 0){
					AILog.Info("Radius = " + this.radius);
				}
			}
			this.radius = this.radius < 0 ? 0 : this.radius;
		}
		this.Sleep(1);
		count++;
	}
}