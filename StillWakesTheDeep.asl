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
	switch (modules.First().ModuleMemorySize)
	{
		case (163450880):
			version = "Patch 1";
			break;
		case (163495936):
			version = "Patch 3";
			break;
		case (174006272):
			version = "DLC";
			break;
		case (174096384):
			version = "25 June 25";
			break;
		default:
			version = "Release";
			break;
	}
	
	IntPtr gEngine = vars.Helper.ScanRel(3, "48 89 05 ???????? 48 85 c9 74 ?? e8 ???????? 48 8d 4d");
	IntPtr gSyncLoad = vars.Helper.ScanRel(21, "33 C0 0F 57 C0 F2 0F 11 05");
	IntPtr fNames = vars.Helper.ScanRel(3, "48 8d 0d ?? ?? ?? ?? e8 ?? ?? ?? ?? c6 05 ?? ?? ?? ?? ?? 0f 10 07");
	
	
	if (version == "Release" || version == "Patch 1"){
		vars.Helper["isLoading"] = vars.Helper.Make<bool>(gSyncLoad);
		vars.Helper["Level"] = vars.Helper.MakeString(gEngine, 0xB98, 0x0);
		vars.Helper["Level"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
		vars.Helper["isPaused"] = vars.Helper.Make<byte>(gEngine, 0xB93);
		vars.Helper["BlackScreen"] = vars.Helper.Make<float>(gEngine, 0xA58, 0x490, 0x2F8, 0x26C);
		vars.Helper["localPlayer"] = vars.Helper.Make<ulong>(gEngine, 0x1080, 0x38, 0x0, 0x30, 0x18);
		vars.Helper["localPlayer"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
		vars.Helper["isCutscene"] = vars.Helper.Make<bool>(gEngine, 0x1080, 0x38, 0x0, 0x30, 0x8CD);
	}
	else{
		vars.Helper["isLoading"] = vars.Helper.Make<bool>(gSyncLoad);
		vars.Helper["Level"] = vars.Helper.MakeString(gEngine, 0xBC0, 0x0);
		vars.Helper["Level"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
		vars.Helper["isPaused"] = vars.Helper.Make<byte>(gEngine, 0xBBB);
		vars.Helper["BlackScreen"] = vars.Helper.Make<float>(gEngine, 0xA80, 0x490, 0x318, 0x26C);
		vars.Helper["localPlayer"] = vars.Helper.Make<ulong>(gEngine, 0x10A8, 0x38, 0x0, 0x30, 0x18);
		vars.Helper["localPlayer"].FailAction = MemoryWatcher.ReadFailAction.SetZeroOrNull;
		vars.Helper["isCutscene"] = vars.Helper.Make<bool>(gEngine, 0x10A8, 0x38, 0x0, 0x30, 0x8CD);
	}
		
	vars.completedSplits = new HashSet<string>();
	
	vars.Engine = gEngine;
	
	vars.FNameToString = (Func<ulong, string>)(fName =>
	{
		var nameIdx  = (fName & 0x000000000000FFFF) >> 0x00;
		var chunkIdx = (fName & 0x00000000FFFF0000) >> 0x10;
		var number   = (fName & 0xFFFFFFFF00000000) >> 0x20;

		IntPtr chunk = vars.Helper.Read<IntPtr>(fNames + 0x10 + (int)chunkIdx * 0x8);
		IntPtr entry = chunk + (int)nameIdx * sizeof(short);

		int length = vars.Helper.Read<short>(entry) >> 6;
		string name = vars.Helper.ReadString(length, ReadStringType.UTF8, entry + sizeof(short));

		return number == 0 ? name : name + "_" + number;
	});
	
	vars.FNameToShortString = (Func<ulong, string>)(fName =>
	{
		string name = vars.FNameToString(fName);

		int dot = name.LastIndexOf('.');
		int slash = name.LastIndexOf('/');

		return name.Substring(Math.Max(dot, slash) + 1);
	});
	
	vars.FNameToShortString2 = (Func<ulong, string>)(fName =>
	{
		string name = vars.FNameToString(fName);

		int under = name.IndexOf('_');

		return name.Substring(0, under + 1);
	});
	
	vars.FNameToShortString3 = (Func<ulong, string>)(fName =>
	{
		string name = vars.FNameToString(fName);

		int under = name.LastIndexOf('_');

		return name.Substring(0, under + 1);
	});
}

update
{
	//print(modules.First().ModuleMemorySize.ToString());
	
	vars.Helper.Update();
	vars.Helper.MapPointers();
	
	//print(vars.FNameToShortString2(current.story));
}

onStart
{
	vars.completedSplits.Clear();
	
	// This makes sure the timer always starts at 0.00
	timer.IsGameTimePaused = true;
}

start
{
	if((current.Level == "/Game/Habitat/Maps/Story/Persistent/20_Intro/Intro_Accom_Interior_P" || current.Level == "/Game/HabitatDLC/Maps/Story_DLC/Persistent/DLC_P") 
		&& !current.isCutscene && old.isCutscene){
			return true;
	}
}

split
{  
	string setting = "";
	
	if(current.Level != old.Level){
		setting = current.Level;
	}

	if(current.Level == "/Game/Habitat/Maps/Story/Persistent/30_Event/Event_Accom_Interior_P" && old.Level == "/Game/Habitat/Maps/Story/Persistent/30_Event/Event_Accom_Exterior_P"){
		setting = "Accom_Revist";
	}
	
	if(current.Level == "/Game/Habitat/Maps/Story/Persistent/30_Event/Event_Admin_Exterior_P" && old.Level == "/Game/Habitat/Maps/Story/Persistent/30_Event/Event_Legs_P"){
		setting = "Admin_Ex_Revisit";
	}
	
	if (settings.ContainsKey(setting) && settings[setting] && vars.completedSplits.Add(setting)){
		return true;
	}
}

isLoading
{
	return current.Level == "/Game/Habitat/Maps/Minimal/startup" || current.Level == "/Game/Habitat/Maps/Story/Persistent/Menu_P" || current.isCutscene || current.isLoading ||
		vars.FNameToShortString3(current.localPlayer) != "BP_HabitatControllerInGame_C_" && vars.FNameToShortString3(current.localPlayer) != "BP_HabitatControllerInGame_DLC_C_" || 
		current.BlackScreen == 1f && current.isPaused != 1;
	
	//current.BlackScreen == 1f && current.isPaused != 1
}

exit
{
	 //pauses timer if the game crashes
	timer.IsGameTimePaused = true;
}

