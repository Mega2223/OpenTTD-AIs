class TesteAI extends AIController 
{
  function Start();
}

function TesteAI::Start()
{
  local teste = 1;
  AICompany.SetName("Mega2223 Inc.");
  AILog.Info("Rodando na " + AIController.GetVersion());
  
  AIRoad.SetCurrentRoadType (AIRoad.ROADTYPE_ROAD);
  AILog.Info(AIRoad.BuildRoad(0X185658,0X185659));
  
  
  while (true) {
    AILog.Info("Oi " + this.GetTick());
	
    this.Sleep(50);
  }
}