state("StillWakesTheDeep"){}
state("Habitat-WinGDK-Shipping"){}

startup
{
    Assembly.Load(File.ReadAllBytes("Components/asl-help")).CreateInstance("Basic");
	vars.Helper.Settings.CreateFromXml("Components/SWtD.Settings.xml");
	vars.Helper.GameName = "Still Wakes the Deep (2024)";
}

init
{
	IntPtr gWorld = vars.Helper.ScanRel(3, "48 8B 05 ???????? 48 3B C? 48 0F 44 C? 48 89 05 ???????? E8");
	IntPtr gEngine = vars.Helper.ScanRel(3, "48 89 05 ???????? 48 85 c9 74 ?? e8 ???????? 48 8d 4d");
	
	vars.Helper["Level"] = vars.Helper.MakeString(gEngine, 0xB98, 0x24);
	vars.Helper["Level"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	
	vars.Helper["isPaused"] = vars.Helper.Make<byte>(gEngine, 0x1080, 0x38, 0x0, 0x78, 0x128, 0xB70);
	vars.Helper["BlackScreen"] = vars.Helper.Make<float>(gEngine, 0x1080, 0x38, 0x0, 0x78, 0x490, 0x2F8, 0x26C);
	
	vars.Helper["isCutscene"] = vars.Helper.Make<byte>(gEngine, 0x1080, 0x38, 0x0, 0x30, 0x8B8, 0x2FC);
	//vars.Helper["isSkipInput"] = vars.Helper.Make<bool>(gEngine, 0x1080, 0x38, 0x0, 0x30, 0x8B8, 0x380, 0x40);
	//vars.Helper["isSkipPrompt"] = vars.Helper.Make<byte>(gEngine, 0x1080, 0x38, 0x0, 0x30, 0x8B8, 0x38C);
	
	vars.Helper["localPlayer"] = vars.Helper.Make<long>(gWorld, 0x1B8, 0x38, 0x0, 0x30);
	vars.Helper["localPlayer"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
	
	vars.completedSplits = new HashSet<string>();
	
	vars.Engine = gEngine;
}

update
{
	vars.Helper.Update();
	vars.Helper.MapPointers();
	
	if(current.isCutscene == 3 && old.isCutscene == 1){
		game.WriteValue<byte>(game.ReadPointer(game.ReadPointer(game.ReadPointer(game.ReadPointer(game.ReadPointer(game.ReadPointer(game.ReadPointer((IntPtr)vars.Engine) + 0x1080) + 0x38) + 0x0) + 0x30) + 0x8B8) + 0x380) + 0x40, 0);
	}
}

onStart
{
	vars.completedSplits.Clear();
	
	// This makes sure the timer always starts at 0.00
	timer.IsGameTimePaused = true;
}

start
{
	return current.Level == "/Story/Persistent/20_Intro/Intro_Accom_Interior_P" && current.isCutscene == 3 && old.isCutscene == 1;
}

split
{  
	string setting = "";
	
	if(current.Level != old.Level){
		setting = current.Level;
	}

	if(current.Level == "/Story/Persistent/30_Event/Event_Accom_Interior_P" && old.Level == "/Story/Persistent/30_Event/Event_Accom_Exterior_P"){
		setting = "Accom_Revist";
	}
	
	if(current.Level == "/Story/Persistent/30_Event/Event_Admin_Exterior_P" && old.Level == "/Story/Persistent/30_Event/Event_Legs_P"){
		setting = "Admin_Ex_Revisit";
	}
	
	if (settings.ContainsKey(setting) && settings[setting] && vars.completedSplits.Add(setting)){
		return true;
	}
}

isLoading
{
	//return current.Level == "/Minimal/startup" || current.Level == "/Story/Persistent/Menu_P" || current.localPlayer == null || current.isCutscene == 1 && current.isSkipPrompt == 0 || current.isCutscene == 1 && current.isSkipInput || current.BlackScreen == 1f && current.isPaused != 1;
	return current.Level == "/Minimal/startup" || current.Level == "/Story/Persistent/Menu_P" || current.localPlayer == null || current.isCutscene == 1 || current.BlackScreen == 1f && current.isPaused != 1;
}

exit
{
	 //pauses timer if the game crashes
	timer.IsGameTimePaused = true;
}
