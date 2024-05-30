class TesteAI extends AIInfo {
  function GetAuthor()      { return "Mega2223"; }
  function GetName()        { return "TesteAI"; }
  function GetDescription() { return "AI que faz algo :)"; }
  function GetVersion()     { return 1; }
  function GetDate()        { return "2024-05-30"; }
  function CreateInstance() { return "TesteAI"; }
  function GetShortName()   { return "XXXX"; }
  function GetAPIVersion()  { return "12"; }
}

RegisterAI(TesteAI());