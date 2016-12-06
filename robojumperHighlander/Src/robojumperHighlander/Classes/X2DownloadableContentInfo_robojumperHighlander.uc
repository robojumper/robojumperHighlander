//---------------------------------------------------------------------------------------
//  FILE:   X2DownloadableContentInfo_robojumperHighlander.uc                                    
//           
//	Use the X2DownloadableContentInfo class to specify unique mod behavior when the 
//  player creates a new campaign or loads a saved game.
//  
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------

class X2DownloadableContentInfo_robojumperHighlander extends X2DownloadableContentInfo;

var ForceFeedbackWaveform TestForm;

/// <summary>
/// This method is run if the player loads a saved game that was created prior to this DLC / Mod being installed, and allows the 
/// DLC / Mod to perform custom processing in response. This will only be called once the first time a player loads a save that was
/// create without the content installed. Subsequent saves will record that the content was installed.
/// </summary>
static event OnLoadedSavedGame()
{

}

/// <summary>
/// This method is run when the player loads a saved game directly into Strategy while this DLC is installed
/// </summary>
static event OnLoadedSavedGameToStrategy()
{

}

/// <summary>
/// Called when the player starts a new campaign while this DLC / Mod is installed. When a new campaign is started the initial state of the world
/// is contained in a strategy start state. Never add additional history frames inside of InstallNewCampaign, add new state objects to the start state
/// or directly modify start state objects
/// </summary>
static event InstallNewCampaign(XComGameState StartState)
{

}

/// <summary>
/// Called just before the player launches into a tactical a mission while this DLC / Mod is installed.
/// Allows dlcs/mods to modify the start state before launching into the mission
/// </summary>
static event OnPreMission(XComGameState StartGameState, XComGameState_MissionSite MissionState)
{

}

/// <summary>
/// Called when the player completes a mission while this DLC / Mod is installed.
/// </summary>
static event OnPostMission()
{

}

/// <summary>
/// Called when the player is doing a direct tactical->tactical mission transfer. Allows mods to modify the
/// start state of the new transfer mission if needed
/// </summary>
static event ModifyTacticalTransferStartState(XComGameState TransferStartState)
{

}

/// <summary>
/// Called after the player exits the post-mission sequence while this DLC / Mod is installed.
/// </summary>
static event OnExitPostMissionSequence()
{

}

/// <summary>
/// Called after the Templates have been created (but before they are validated) while this DLC / Mod is installed.
/// </summary>
static event OnPostTemplatesCreated()
{

}

/// <summary>
/// Called when the difficulty changes and this DLC is active
/// </summary>
static event OnDifficultyChanged()
{

}

simulated function EnableDLCContentPopupCallback(eUIAction eAction)
{

}

/// <summary>
/// Called when viewing mission blades with the Shadow Chamber panel, used primarily to modify tactical tags for spawning
/// Returns true when the mission's spawning info needs to be updated
/// </summary>
static function bool UpdateShadowChamberMissionInfo(StateObjectReference MissionRef)
{
	return false;
}

/// <summary>
/// Called from X2AbilityTag:ExpandHandler after processing the base game tags. Return true (and fill OutString correctly)
/// to indicate the tag has been expanded properly and no further processing is needed.
/// </summary>
static function bool AbilityTagExpandHandler(string InString, out string OutString)
{
	return false;
}
/// <summary>
/// Called from XComGameState_Unit:GatherUnitAbilitiesForInit after the game has built what it believes is the full list of
/// abilities for the unit based on character, class, equipment, et cetera. You can add or remove abilities in SetupData.
/// </summary>
static function FinalizeUnitAbilitiesForInit(XComGameState_Unit UnitState, out array<AbilitySetupData> SetupData, optional XComGameState StartState, optional XComGameState_Player PlayerState, optional bool bMultiplayerDisplay)
{

}

/// <summary>
/// robojumperHighlander: Called from X2BodyPartTemplateManager:InitTemplatesInternal once prior to creating templates
/// allows mods to make dynamic modifications
/// </summary>
static function OnPreBodyPartTemplatesCreated(out array<X2PartInfo> BodyPartTemplateConfig, out array<string> ValidPartTypes)
{
	local int i;

	for (i = BodyPartTemplateConfig.Length - 1; i >= 0; i--)
	{
		if (BodyPartTemplateConfig[i].DLCName != "")
		{
			BodyPartTemplateConfig.Remove(i, 1);
		}
	}
}

/// <summary>
/// robojumperHighlander: Called from UIPauseMenu:GatherEntries when building the pause menu
/// allows mods to add to the pause menu easily
/// WARNING: Applies to the debug start menu as well since it is a UIPauseMenu too
/// </summary>
static function AddAdditionalPauseMenuEntries(out array<UIPauseMenuEntry> Entries)
{
	Entries.AddItem(class'UIPauseMenu'.static.CreatePauseMenuEntry("Achievements", OnViewAchievements));
}

static function OnViewAchievements()
{
	class'WorldInfo'.static.GetWorldInfo().ConsoleCommand("ViewAchievements");
}

exec function TestRumble()
{
	local robojumperRumbleStack TheStack;

	TheStack = class'WorldInfo'.static.GetWorldInfo().Spawn(class'robojumperRumbleStack');
	TheStack.AddWaveForm(TestForm);
	//class'WorldInfo'.static.GetWorldInfo().GetALocalPlayerController().ForceFeedbackManager.PlayForceFeedbackWaveform(TestForm, none);
	
}

defaultproperties
{
	Begin Object Class=ForceFeedbackWaveform Name=ForceFeedbackWaveform0
		Samples(0)=(LeftAmplitude=100,RightAmplitude=100,LeftFunction=WF_LinearIncreasing,RightFunction=WF_LinearIncreasing,Duration=10)
		Samples(1)=(LeftAmplitude=100,RightAmplitude=100,LeftFunction=WF_LinearIncreasing,RightFunction=WF_LinearIncreasing,Duration=10)
		bIsLooping=true
	End Object

	TestForm=ForceFeedbackWaveform0
}