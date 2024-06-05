require("utils.nut");
 
class EAIRoute{

	station_from = null;
	station_to = null;
	tile_from = null;
	tile_to = null;
	cargo_type = null;
	Utils = EAIUtils();
	
	vehicles = null;
	
	constructor(from,to,cargoType){
		this.station_from = from;
		this.station_to = to;
		this.tile_from = AIStation.GetLocation(from);
		this.tile_to = AIStation.GetLocation(to);
		this.vehicles = [];
		this.cargo_type = cargoType;
	}
	
	function Equals(route){
		return ((this.city_from == route.city_from && this.city_to == route.city_to) || (this.city_from == route.city_to && this.city_to == route.city_from)) && route.cargo_type == this.cargo_type;
	}
	
	function BuyVehicle(engine, depot){
		
		if(engine == null){engine = this.SelectIdealVehicle();}
		
		local vehicle = AIVehicle.BuildVehicle(depot, engine);
		if(!AIVehicle.IsValidVehicle(vehicle) || vehicle == null){return null;}
		
		AIOrder.AppendOrder(vehicle, this.tile_from, AIOrder.OF_NON_STOP_INTERMEDIATE);
		AIOrder.AppendOrder(vehicle, this.tile_to, AIOrder.OF_NON_STOP_INTERMEDIATE);
		AIVehicle.StartStopVehicle(vehicle);
	
		this.vehicles.append(vehicle);
		return vehicle;
	}
	
	function IsCompatible(engine){
		return AICargo.GetName(AIEngine.GetCargoType(engine)) == this.cargo_type;
	}
	
	function SelectIdealVehicle(){
		local distance = this.GetDistance();
		local engines = AIEngineList(AIVehicle.VT_ROAD);
		
		local strongestPreference = 0.0;
		local bestEngine = null;
		
		for(local engine = engines.Begin(); !engines.IsEnd(); engine = engines.Next()){
			if(!this.IsCompatible(engine)){continue;}
			local enginePreference = this.GetDistance() * this.GetDistance() * AIEngine.GetCapacity(engine) * AIEngine.GetMaxSpeed(engine) / AIEngine.GetRunningCost(engine);
			//AILog.Info(this.GetDistance());
			if(enginePreference > strongestPreference){
				enginePreference = strongestPreference;
				bestEngine = engine;
			}
		}
	
		if(bestEngine == null){
			AILog.Info("Failed to choose vehicle :(");
			AILog.Info("Route " + this.AsString());
			AILog.Info("Distance = " + this.GetDistance())
		}
		return bestEngine;
	}
	
	function Decomission(){
		for(local i = 0; i < this.vehicles.len(); i++){
			local vehicle = this.vehicles[i];
			if(!AIVehicle.IsInDepot(vehicle) && AIOrder.IsCurrentOrderPartOfOrderList(vehicle)){
				AIVehicle.SendVehicleToDepot(vehicle);
			}
		}
		
	}
	
	function GetDistance(){
		local x1 = AIMap.GetTileX(this.tile_from); local y1 = AIMap.GetTileX(this.tile_from);
		local x2 = AIMap.GetTileX(this.tile_to); local  y2 = AIMap.GetTileX(this.tile_to);
		local dist = sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2));
		return dist == 0 ? 0.001 : dist;
	}

	function ProfitsThisYear(){
		local sum = 0;
		for(local i = 0; i < this.vehicles.len(); i++){
			//TODO individual vehicles may be deleted but not the whole route?
			sum += AIVehicle.GetProfitThisYear(this.vehicles[i]);
		}
		return sum;
	}
	
	function ProfitsLastYear(){
		local sum = 0;
		for(local i = 0; i < this.vehicles.len(); i++){
			//TODO individual vehicles may be deleted but not the whole route?
			sum += AIVehicle.GetProfitLastYear(this.vehicles[i]);
		}
		return sum;
	}
	
	function Age(){
		if(this.vehicles.len() == 0){return -1;}
		local oldest = AIVehicle.GetAge(this.vehicles[0]);
		for(local i = 0; i < this.vehicles.len(); i++){
			local age = AIVehicle.GetAge(this.vehicles[i]);
			oldest = oldest > age ? oldest : age;
		}
		return oldest;
	}
	
	function YoungestAge(){
		if(this.vehicles.len() == 0){return -1;}
		local youngest = AIVehicle.GetAge(this.vehicles[0]);
		for(local i = 0; i < this.vehicles.len(); i++){
			local age = AIVehicle.GetAge(this.vehicles[i]);
			youngest = youngest < age ? youngest : age;
		}
		return youngest;
	}
	
	function AsString(){
		return AIStation.GetName(this.station_from) + " <-> " + AIStation.GetName(this.station_to) + " (" + this.cargo_type + ")";
	}
	
	function GetCargoWaitingAmount(){
		local cargoID = Utils.GetCargoTypeFromName(this.cargo_type);
		local sum = AIStation.GetCargoWaitingVia(station_from,station_to,cargoID) +
					AIStation.GetCargoWaitingVia(station_to,station_from,cargoID) +
					AIStation.GetCargoWaitingVia(station_from,AIStation.STATION_INVALID,cargoID) +
					AIStation.GetCargoWaitingVia(station_from,AIStation.STATION_INVALID,cargoID); 
		return sum;
	}
	
	function GetTownFrom(){
		return AITile.GetClosestTown(this.tile_from);
	}
	
	function GetTownTo(){
		return AITile.GetClosestTown(this.tile_to);
	}
}