class EAIRoute{

	station_from = null;
	station_to = null;
	cargo_type = null;
	
	vehicles = null;
	
	constructor(from,to,cargoType){
		this.station_from = from;
		this.station_to = to;
		this.vehicles = [];
		this.cargo_type = cargoType;
	}
	
	function equals(route){
		return ((this.city_from == route.city_from) && this.city_to == route.city_to) || (this.city_from == route.city_to && this.city_to == route.city_from));
	}
	
	function buyVehicle(engine, depot){
	
		local vehicle = AIVehicle.BuildVehicle(depot, engine);
		if(!AIVehicle.IsValidVehicle(vehicle) || vehicle == null){return null;}
		
		AIOrder.AppendOrder(vehicle, this.station_from, AIOrder.OF_NON_STOP_INTERMEDIATE);
		AIOrder.AppendOrder(vehicle, this.station_to, AIOrder.OF_NON_STOP_INTERMEDIATE);
		AIVehicle.StartStopVehicle(vehicle);
	
		this.vehicles.append(vehicle);
		return vehicle;
	}
	
	function selectIdealVehicle(){
		local distance = this.getDistance();
		AIEnginee
	}
	
	function getDistance(){
		local c1 = AIStation.GetLocation(this.station_from), c2 = AIStation.GetLocation(this.station_to);
		local x1 = AIMap.GetTileX(c1), y1 = AIMap.GetTileX(c1), x2 = AIMap.GetTileX(c2), y2 = AIMap.GetTileX(c2);
		return math.sqrt((x1-x2)*(x1-x2) + (y1-y2)*(y1-y2));
	}
}