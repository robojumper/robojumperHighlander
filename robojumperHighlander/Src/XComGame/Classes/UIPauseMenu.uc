//---------------------------------------------------------------------------------------
//  *********   FIRAXIS SOURCE CODE   ******************
//  FILE:    UIPauseMenu
//  AUTHOR:  Brit Steiner       -- 02/26/09
//           Tronster Hartley   -- 04/14/09
//  PURPOSE: Controls the game side of the pause menu UI screen.
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//--------------------------------------------------------------------------------------- 
// robojumperHighlander: This code is a mess. Make it modular and extensible
class UIPauseMenu extends UIScreen;

struct UIPauseMenuEntry
{
	var string strText;
	var bool bEnabled;
	var string strDisabledText;
	var delegate<OnItemClickedDelegate> OnClickDelegate;
};

var array<UIPauseMenuEntry> Entries;

var int       m_iCurrentSelection;
var int       MAX_OPTIONS;
var bool      m_bIsIronman;
var bool      m_bAllowSaving;

var UIList List;
var UIText Title;

var localized string m_sPauseMenu;
var localized string m_sSaveGame;
var localized string m_sReturnToGame;
var localized string m_sSaveAndExitGame;
var localized string m_sLoadGame;
var localized string m_sControllerMap;
var localized string m_sInputOptions;
var localized string m_sAbortMission;
var localized string m_sExitGame;
var localized string m_sQuitGame;
var localized string m_sAccept;
var localized string m_sCancel;
var localized string m_sAcceptInvitations;
var localized string m_kExitGameDialogue_title;
var localized string m_kExitGameDialogue_body;
var localized string m_kExitMPRankedGameDialogue_body;
var localized string m_kExitMPUnrankedGameDialogue_body;
var localized string m_kQuitGameDialogue_title;
var localized string m_kQuitGameDialogue_body;
var localized string m_kQuitMPRankedGameDialogue_body;
var localized string m_kQuitMPUnrankedGameDialogue_body;
var localized string m_sRestartLevel;
var localized string m_sRestartConfirm_title;
var localized string m_sRestartConfirm_body;
var localized string m_sChangeDifficulty;
var localized string m_sViewSecondWave;
var localized string m_sUnableToSaveTitle;
var localized string m_sUnableToSaveBody;
var localized string m_sSavingIsInProgress;
var localized string m_sUnableToAbortTitle;
var localized string m_sUnableToAbortBody;
var localized string m_kSaveAndExitGameDialogue_title;
var localized string m_kSaveAndExitGameDialogue_body;

var int m_optReturnToGame;
var int m_optSave;
var int m_optLoad;
var int m_optRestart;
var int m_optChangeDifficulty;
var int m_optViewSecondWave;
var int m_optControllerMap;
var int m_optOptions;
var int m_optExitGame;
var int m_optQuitGame;
var int m_optAcceptInvite;
var bool bWasInCinematicMode;
var protectedwrite UINavigationHelp NavHelp;
delegate OnCancel();

delegate OnItemClickedDelegate();
//</workshop>

simulated function InitScreen(XComPlayerController InitController, UIMovie InitMovie, optional name InitName)
{
	bWasInCinematicMode = InitMovie.Stack.bCinematicMode;
	InitMovie.Stack.bCinematicMode = false;
	super.InitScreen(InitController, InitMovie, InitName);
	
	Movie.Pres.OnPauseMenu(true);
	Movie.Pres.StopDistort(); 

	if( `XWORLDINFO.GRI != none && `TACTICALGRI != none && `BATTLE != none )
		`BATTLE.m_bInPauseMenu = true;

	if (!IsA('UIShellStrategy') && !`XENGINE.IsMultiplayerGame())
	{
		PC.SetPause(true);
	}
	
	List = Spawn(class'UIList', self);
	List.InitList('ItemList', , , 415, 450);
	List.OnItemClicked = OnChildClicked;
	List.OnSelectionChanged = SetSelected; 
	List.OnItemDoubleClicked = OnChildClicked;

	XComTacticalController(PC).GetCursor().SetForceHidden(false);
	`PRES.m_kUIMouseCursor.Show();
	if (IsA('UIShellStrategy'))
	{
		NavHelp = InitController.Pres.GetNavHelp();
	}
	else if( XComHQPresentationLayer(Movie.Pres) != none)
	{
		NavHelp =`HQPRES.m_kAvengerHUD.NavHelp;
	}
	else
	{
		NavHelp = Spawn(class'UINavigationHelp', self).InitNavHelp();
	}

	UpdateNavHelp();
}

//----------------------------------------------------------------------------
//	Set default values.
//
simulated function OnInit()
{
	local bool bInputBlocked; 
	local bool bInputGateRaised;

	super.OnInit();

	GatherEntries();
	
	BuildMenu();
	
	SetSelected(List, 0);
	List.SetSelectedIndex(0);

	//If you've managed to fire up the pause menu while the state was transitioning to block input, get back out of here. 
	bInputBlocked = XComTacticalInput(PC.PlayerInput) != none && XComTacticalInput(PC.PlayerInput).m_bInputBlocked;
	bInputGateRaised = Movie != none && Movie.Stack != none &&  Movie.Stack.IsInputBlocked;
	if( bInputBlocked || bInputGateRaised )
	{
		`log("UIPauseMenu: you've got in to a bad state where the input is blocked but the pause menu just finished async loading in. Killing the pause menu now. -bsteiner");
		OnUCancel();
	}
}

simulated function UpdateNavHelp()
{
	NavHelp.ClearButtonHelp();
	NavHelp.bIsVerticalHelp = `ISCONTROLLERACTIVE;
	NavHelp.AddBackButton(CloseScreen);

	if( `ISCONTROLLERACTIVE )
		NavHelp.AddSelectNavHelp();
}

/*simulated function bool IsGameComplete()
{
	return class'GameEngine'.static.GetOnlineSubsystem().GameDownloadInterface.IsGameComplete();
}*/

simulated event ModifyHearSoundComponent(AudioComponent AC)
{
	AC.bIsUISound = true;
}

simulated function bool OnUnrealCommand(int ucmd, int ActionMask)
{
	// Ignore releases, only pay attention to presses.
	if ( !CheckInputIsReleaseOrDirectionRepeat(ucmd, ActionMask) )
		return true;

	switch(ucmd)
	{
		case class'UIUtilities_Input'.const.FXS_BUTTON_A:
		case class'UIUtilities_Input'.const.FXS_KEY_ENTER:
		case class'UIUtilities_Input'.const.FXS_KEY_SPACEBAR:
			OnChildClicked(List, m_iCurrentSelection);
			break;
		
		case class'UIUtilities_Input'.const.FXS_BUTTON_B:
		case class'UIUtilities_Input'.const.FXS_KEY_ESCAPE:
		case class'UIUtilities_Input'.const.FXS_BUTTON_START:
		case class'UIUtilities_Input'.const.FXS_R_MOUSE_DOWN:
			OnUCancel();
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_UP:
		case class'UIUtilities_Input'.const.FXS_ARROW_UP:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_UP:
		case class'UIUtilities_Input'.const.FXS_KEY_W:
			OnUDPadUp();
			break;

		case class'UIUtilities_Input'.const.FXS_DPAD_DOWN:
		case class'UIUtilities_Input'.const.FXS_ARROW_DOWN:
		case class'UIUtilities_Input'.const.FXS_VIRTUAL_LSTICK_DOWN:
		case class'UIUtilities_Input'.const.FXS_KEY_S:
			OnUDPadDown();
			break;

		default:
			// Do not reset handled, consume input since this
			// is the pause menu which stops any other systems.
			break;			
	}

	return super.OnUnrealCommand(ucmd, ActionMask);
}

simulated function OnMouseEvent(int cmd, array<string> args)
{
	switch( cmd )
	{
		case class'UIUtilities_Input'.const.FXS_L_MOUSE_IN:
			//Update the selection based on what the mouse rolled over
			//SetSelected( int(Split( args[args.Length - 1], "option", true)) );
			break;

		case class'UIUtilities_Input'.const.FXS_L_MOUSE_UP:
			//Update the selection based on what the mouse clicked
			m_iCurrentSelection = int(Split( args[args.Length - 1], "option", true));
			OnChildClicked(List, m_iCurrentSelection);
			break;
	}
}

simulated public function OnChildClicked(UIList ContainerList, int ItemIndex)
{		
	local delegate<OnItemClickedDelegate> Del;
	Movie.Pres.PlayUISound(eSUISound_MenuSelect);

	SetSelected(ContainerList, ItemIndex);

	if (m_iCurrentSelection >= MAX_OPTIONS)
	{
		`warn("Pause menu cannot accept an unexpected index of:" @ m_iCurrentSelection);
	}
	else
	{
		if (Entries[m_iCurrentSelection].OnClickDelegate != none)
		{
			Del = Entries[m_iCurrentSelection].OnClickDelegate;
			Del();
		}
	}

}

simulated function GatherEntries()
{
	// robojumperHighlander: Allow dynamically adding Pause Menu Entries
	local array<X2DownloadableContentInfo> DLCInfos;
	local X2DownloadableContentInfo DLCInfo;
	
	local XComMPTacticalGRI kMPGRI;	

	kMPGRI = XComMPTacticalGRI(WorldInfo.GRI);

	// return to game
	Entries.AddItem(CreatePauseMenuEntry(m_sReturnToGame, OnUCancel));


	// no save/load in multiplayer -tsmith 
	if (kMPGRI == none && !`ONLINEEVENTMGR.bIsChallengeModeGame)
	{
		if( m_bAllowSaving )
		{
			Entries.AddItem(CreatePauseMenuEntry(m_bIsIronman ? m_sSaveAndExitGame : m_sSaveGame, OnSave, `TUTORIAL == none, class'XGLocalizedData'.default.SaveDisabledForTutorial));
		}
		// in ironman, you cannot load at any time that saving would normally be disabled
		if( m_bAllowSaving || !m_bIsIronman )
		{
			Entries.AddItem(CreatePauseMenuEntry(m_sLoadGame, OnLoad));
		}
	}

	if (`ISCONTROLLERACTIVE)
	{
		Entries.AddItem(CreatePauseMenuEntry(m_sControllerMap, Movie.Pres.UIControllerMap));
	}


	Entries.AddItem(CreatePauseMenuEntry(m_sInputOptions, OnPCOptions));

	// no restart in multiplayer -tsmith 
	if( kMPGRI == none &&
		!m_bIsIronman &&
		XComPresentationLayer(Movie.Pres) != none &&
		XGBattle_SP(`BATTLE).m_kDesc != None &&
		(XGBattle_SP(`BATTLE).m_kDesc.m_iMissionType == eMission_Final || XGBattle_SP(`BATTLE).m_kDesc.m_bIsFirstMission || XGBattle_SP(`BATTLE).m_kDesc.m_iMissionType == eMission_HQAssault) && //Only visible in temple ship or first mission, per Jake. -bsteiner 6/12/12
		!`ONLINEEVENTMGR.bIsChallengeModeGame )
	{
		Entries.AddItem(CreatePauseMenuEntry(m_sRestartLevel, OnRestart));
	}

	// Only allow changing difficulty if in an active single player game and only at times where saving is permitted
	if( Movie.Pres.m_eUIMode != eUIMode_Shell && kMPGRI == none && m_bAllowSaving && !`ONLINEEVENTMGR.bIsChallengeModeGame)
	{
		Entries.AddItem(CreatePauseMenuEntry(m_sChangeDifficulty, OnChangeDifficulty));
	}

	// Only show second wave options in single player
	if ( `XPROFILESETTINGS.Data.IsSecondWaveUnlocked() && Movie.Pres.m_eUIMode != eUIMode_Shell && kMPGRI == none )
	{
		Entries.AddItem(CreatePauseMenuEntry(m_sViewSecondWave, OnSecondWave));
	}
	
	Entries.AddItem(CreatePauseMenuEntry(m_sExitGame, OnExitGame));

	// no quit game on console or in MP. MP we only want exit so it will record a loss for you. -tsmith 
	if (`XPROFILESETTINGS != none )
	{
		Entries.AddItem(CreatePauseMenuEntry(m_sQuitGame, OnQuitGame));
	}



	// give DLC's a chance
	DLCInfos = `ONLINEEVENTMGR.GetDLCInfos(false);
	foreach DLCInfos(DLCInfo)
	{
		DLCInfo.AddAdditionalPauseMenuEntries(Entries);
	}
}


simulated static function UIPauseMenuEntry CreatePauseMenuEntry(string strText, delegate<OnItemClickedDelegate> callback, optional bool bEnabled = true, optional string strDisabled = "")
{
	local UIPauseMenuEntry Entry;

	Entry.strText = strText;
	Entry.bEnabled = bEnabled;
	Entry.strDisabledText = strDisabled;
	Entry.OnClickDelegate = callback;

	return Entry;
}

simulated function BuildMenu()
{
	local int iCurrent; 
	
	local UIPauseMenuEntry CurrentEntry;
	local UIListItemString CurrentPanel;

	MC.FunctionString("SetTitle", m_sPauseMenu);

	List.ClearItems();

	for (iCurrent = 0; iCurrent < Entries.Length; iCurrent++)
	{
		CurrentEntry = Entries[iCurrent];
		CurrentPanel = UIListItemString(List.CreateItem());
		CurrentPanel.InitListItem(CurrentEntry.strText);
		if (CurrentEntry.bEnabled == false)
		{
			CurrentPanel.DisableListItem(CurrentEntry.strDisabledText);
		}
	}

	MAX_OPTIONS = iCurrent;

	MC.FunctionVoid("AnimateIn");
}

simulated function OnLoseFocus()
{
	super.OnLoseFocus();
	NavHelp.ClearButtonHelp();
}

simulated function OnReceiveFocus() 
{
	super.OnReceiveFocus();
	SetSelected(List, 0);
	SetSelected(List, m_iCurrentSelection);
	UpdateNavHelp();
}

simulated event Destroyed()
{
	local int iCurrent;

	for (iCurrent = 0; iCurrent < Entries.Length; iCurrent++)
	{
		Entries[iCurrent].OnClickDelegate = none;
	}

	super.Destroyed();
	PC.SetPause(false);
}

function OnSave()
{
	if (`TUTORIAL == none)
	{
		if (Movie.Pres.PlayerCanSave() && !`ONLINEEVENTMGR.SaveInProgress())
		{
			if (m_bIsIronman)
				IronmanSaveAndExitDialogue();
			else
			{
				Movie.Pres.UISaveScreen();
			}
		}
		else
		{
			UnableToSaveDialogue(`ONLINEEVENTMGR.SaveInProgress());
		}
	}
}

function OnLoad()
{
	if( m_bIsIronman )
		`AUTOSAVEMGR.DoAutosave();

	Movie.Pres.UILoadScreen();
}

function OnChangeDifficulty()
{
	Movie.Pres.UIDifficulty( true );
}

function OnSecondWave()
{
	Movie.Pres.UISecondWave( true );
}

function OnPCOptions()
{
	Movie.Pres.UIPCOptions();
}

function OnRestart()
{
	if (`BATTLE != none && WorldInfo.NetMode == NM_Standalone && !m_bIsIronman)
		RestartMissionDialogue();
}

function OnExitGame()
{
	if( m_bIsIronman )
		`AUTOSAVEMGR.DoAutosave();
	ExitGameDialogue();
}

function SaveAndExit()
{
	`AUTOSAVEMGR.DoAutosave(OnSaveGameComplete);

	XComPresentationLayer(Movie.Pres).GetTacticalHUD().Hide();
	Hide();

	Movie.RaiseInputGate();
}

function OnQuitGame()
{
	if( m_bIsIronman )
		`AUTOSAVEMGR.DoAutosave();
				
	QuitGameDialogue();
}

function OnSaveGameComplete(bool bWasSuccessful)
{
	Movie.LowerInputGate();

	if( bWasSuccessful )
	{
		Disconnect();
	}
	else
	{
		`RedScreen("[@Systems] Save failed to complete");
	}
}

function Disconnect()
{
	if (`REPLAY.bInTutorial)
	{
		`FXSLIVE.AnalyticsGameTutorialExited( );
	}

	Movie.Pres.UIEndGame();
	`XCOMHISTORY.ResetHistory();
	ConsoleCommand("disconnect");
}

function ExitGameDialogue() 
{
	local TDialogueBoxData      kDialogData;
	local XComMPTacticalGRI     kMPGRI;

	kMPGRI = XComMPTacticalGRI(WorldInfo.GRI);

	kDialogData.eType = eDialog_Warning;

	if(kMPGRI != none)
	{
		if(kMPGRI.m_bIsRanked)
		{
			kDialogData.strText = m_kExitMPRankedGameDialogue_body; 
		}
		else
		{
			kDialogData.strText = m_kExitMPUnrankedGameDialogue_body; 
		}
		kDialogData.fnCallback = ExitMPGameDialogueCallback;
	}
	else
	{
		kDialogData.strText = m_kExitGameDialogue_body; 
		kDialogData.fnCallback = ExitGameDialogueCallback;
	}

	kDialogData.strTitle = m_kExitGameDialogue_title;
	kDialogData.strAccept = m_sAccept; 
	kDialogData.strCancel = m_sCancel; 

	Movie.Pres.UIRaiseDialog( kDialogData );
}

simulated public function ExitGameDialogueCallback(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);

		// Hide the UI so the user knows their input was accepted
		XComPresentationLayer(Movie.Pres).GetTacticalHUD().Hide();
		Hide();

		SetTimer(0.15, false, 'Disconnect'); // Give time for the UI to hide before disconnecting
	}
	else if( eAction == eUIAction_Cancel )
	{
		Movie.Pres.PlayUISound(eSUISound_MenuClose);
	}
}

simulated public function ExitMPGameDialogueCallback(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		Movie.Pres.PlayUISound(eSUISound_MenuSelect);
		Movie.Pres.UIEndGame();
		XComTacticalController(PC).AttemptExit();
	}
	else if( eAction == eUIAction_Cancel )
	{
		//Nothing
	}
}

function IronmanSaveAndExitDialogue()
{
	local TDialogueBoxData kDialogData;

	kDialogData.eType       = eDialog_Warning;
	kDialogData.strTitle    = m_kSaveAndExitGameDialogue_title;
	kDialogData.strText     = m_kSaveAndExitGameDialogue_body; 
	kDialogData.strAccept   = m_sAccept; 
	kDialogData.strCancel   = m_sCancel; 
	kDialogData.fnCallback  = IronmanSaveAndExitDialogueCallback;

	Movie.Pres.UIRaiseDialog( kDialogData );
}

simulated public function IronmanSaveAndExitDialogueCallback(EUIAction eAction)
{	
	if (eAction == eUIAction_Accept)
	{
		SaveAndExit();
	}
	else if( eAction == eUIAction_Cancel )
	{
		//Nothing
	}
}


function UnableToSaveDialogue(bool bSavingInProgress)
{
	local TDialogueBoxData kDialogData;

	kDialogData.eType       = eDialog_Warning;
	kDialogData.strTitle    = m_sUnableToSaveTitle;
	if( bSavingInProgress )
	{
		kDialogData.strText = m_sSavingIsInProgress;
	}
	else
	{
		kDialogData.strText = m_sUnableToSaveBody;
	}
	kDialogData.strAccept   = m_sAccept;	

	Movie.Pres.UIRaiseDialog( kDialogData );
}

function UnableToAbortDialogue()
{
	local TDialogueBoxData kDialogData;

	kDialogData.eType       = eDialog_Warning;
	kDialogData.strTitle    = m_sUnableToAbortTitle;
	kDialogData.strText     = m_sUnableToAbortBody; 
	kDialogData.strAccept   = m_sAccept;	

	Movie.Pres.UIRaiseDialog( kDialogData );
}

function RestartMissionDialogue()
{
	local TDialogueBoxData kDialogData;

	kDialogData.eType       = eDialog_Warning;
	kDialogData.strTitle    = m_sRestartConfirm_title;
	kDialogData.strText     = m_sRestartConfirm_body; 
	kDialogData.strAccept   = m_sAccept; 
	kDialogData.strCancel   = m_sCancel; 
	kDialogData.fnCallback  = RestartMissionDialgoueCallback;

	Movie.Pres.UIRaiseDialog( kDialogData );
}

simulated public function RestartMissionDialgoueCallback(EUIAction eAction)
{	
	if (eAction == eUIAction_Accept)
	{
		`PRES.m_kNarrative.RestoreNarrativeCounters();
		PC.RestartLevel();
	}
}

function QuitGameDialogue() 
{
	local TDialogueBoxData kDialogData; 
	local XComMPTacticalGRI     kMPGRI;

	kMPGRI = XComMPTacticalGRI(WorldInfo.GRI);

	if(kMPGRI != none && kMPGRI.m_bIsRanked)
	{
		kDialogData.strText     = m_kQuitMPRankedGameDialogue_body; 
		kDialogData.fnCallback  = QuitGameMPRankedDialogueCallback;
	}
	else
	{
		if(kMPGRI != none )
			kDialogData.strText     = m_kQuitMPUnrankedGameDialogue_body; 
		else
			kDialogData.strText     = m_kQuitGameDialogue_body; 
		kDialogData.fnCallback  = QuitGameDialogueCallback;
	}

	kDialogData.eType       = eDialog_Warning;
	kDialogData.strTitle    = m_kQuitGameDialogue_title;
	kDialogData.strAccept   = m_sAccept; 
	kDialogData.strCancel   = m_sCancel; 

	Movie.Pres.UIRaiseDialog( kDialogData );
}

simulated public function QuitGameDialogueCallback(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		Movie.Pres.UIEndGame();
		ConsoleCommand("exit");
	}
	else if( eAction == eUIAction_Cancel )
	{
		//Nothing
	}
}

simulated public function QuitGameMPRankedDialogueCallback(eUIAction eAction)
{
	if (eAction == eUIAction_Accept)
	{
		Movie.Pres.UIEndGame();
		ConsoleCommand("exit");
	}
	else if( eAction == eUIAction_Cancel )
	{
		//Nothing
	}
}

// Lower pause screen
simulated public function OnUCancel()
{
	if( !bIsInited )
		return;

	if( `XWORLDINFO.GRI != none && `TACTICALGRI != none && `BATTLE != none )
		`BATTLE.m_bInPauseMenu = false;
	if (OnCancel != none)
	{
		OnCancel();
	}

	Movie.Pres.PlayUISound(eSUISound_MenuClose);
	Movie.Stack.Pop(self);
}

simulated public function OnUDPadUp()
{
	PlaySound( SoundCue'SoundUI.MenuScrollCue', true );

	--m_iCurrentSelection;
	if (m_iCurrentSelection < 0)
		m_iCurrentSelection = MAX_OPTIONS-1;

	SetSelected(List, m_iCurrentSelection);
}


simulated public function OnUDPadDown()
{
	PlaySound( SoundCue'SoundUI.MenuScrollCue', true );

	++m_iCurrentSelection;
	if (m_iCurrentSelection >= MAX_OPTIONS)
		m_iCurrentSelection = 0;

	SetSelected( List, m_iCurrentSelection );
}

simulated function SetSelected(UIList ContainerList, int ItemIndex)
{
	m_iCurrentSelection = ItemIndex;
}


simulated function int GetSelected()
{
	return  m_iCurrentSelection; 
}

simulated function OnRemoved()
{
	Movie.Stack.bCinematicMode = bWasInCinematicMode;
	Movie.Pres.OnPauseMenu(false);
}

simulated function OnExitButtonClicked(UIButton button)
{
	CloseScreen();
}

simulated function CloseScreen()
{
	super.CloseScreen();
	NavHelp.ClearButtonHelp();
}

event Tick( float deltaTime )
{
	local XComTacticalController XTC;

	super.Tick( deltaTime );

	XTC = XComTacticalController(PC);
	if (XTC != none && XTC.GetCursor().bHidden)
	{
		XTC.GetCursor().SetVisible(true);
	}
	
}

DefaultProperties
{
	m_iCurrentSelection = 0;
	MAX_OPTIONS = -1;
	m_bIsIronman = false;

	Package   = "/ package/gfxPauseMenu/PauseMenu";
	MCName      = "thePauseMenu";

	InputState= eInputState_Consume;
	bConsumeMouseEvents = true;

	bAlwaysTick = true
	bShowDuringCinematic = true
}
