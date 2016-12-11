//---------------------------------------------------------------------------------------
//  FILE:    X2Action_ATT.uc
//  AUTHOR:  Dan Kaplan  --  4/28/2015
//  PURPOSE: Starts and controls the ATT sequence when dropping off reinforcements
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
// robojumperHighlander: this is getting an overhaul to make it similar to the DropshipIntro
// multiple Matinees layed over each other
class X2Action_ATT extends X2Action_PlayMatinee config(GameData);

struct ATTMapping
{
	var name CharacterGroupName;
	var string MatineePrefixPath;
};

var config array<ATTMapping> ATTMappings;

var const config string MatineeCommentPrefix;
var const config int NumDropSlots;

var private array<StateObjectReference> MatineeUnitRefs;

function Init(const out VisualizationTrack InTrack)
{
	// need to find the matinee before calling super, which will init it
	FindATTMatinee();

	super.Init(InTrack);

	AddUnitsToMatinee(StateChangeContext);

	SetMatineeBase('CIN_Advent_Base');
	SetMatineeLocation(XComGameState_AIReinforcementSpawner(InTrack.StateObject_NewState).SpawnInfo.SpawnLocation);
}

private function AddUnitsToMatinee(XComGameStateContext InContext)
{
	local XComGameState_Unit GameStateUnit;
	local int UnitIndex;
	local string Prefix, Check;
	local array<string> AllPrefixes;

	UnitIndex = 1;
	GetAllIntroSlotPrefixes(AllPrefixes);

	foreach InContext.AssociatedState.IterateByClassType(class'XComGameState_Unit', GameStateUnit)
	{
		foreach AllPrefixes(Check)
		{
			AddUnitToMatinee(name(Check $ UnitIndex), GetPrefixForCharacter(GameStateUnit.GetMyTemplate()) == Check ? GameStateUnit : none);
		}
	
		UnitIndex++;

		MatineeUnitRefs.AddItem(GameStateUnit.GetReference());
	}

	while(UnitIndex < NumDropSlots)
	{
		foreach AllPrefixes(Check)
		{
			AddUnitToMatinee(name(Check $ UnitIndex), none);
		}
		UnitIndex++;
	}
}

function string GetPrefixForCharacter(X2CharacterTemplate Template)
{
	local int i;
	i = ATTMappings.Find('CharacterGroupName', Template.CharacterGroupName);
	if (i != INDEX_NONE)
	{
		return ATTMappings[i].MatineePrefixPath;
	}
	else
	{
		return "Advent";
	}
}

//We never time out
function bool IsTimedOut()
{
	return false;
}

private function FindATTMatinee()
{
	SelectMatineeByTag(MatineeCommentPrefix);
}

simulated state Executing
{
	simulated event BeginState(name PrevStateName)
	{
		super.BeginState(PrevStateName);
		
		`BATTLE.SetFOW(false);
	}

	simulated event EndState(name NextStateName)
	{
		local int i;
		local StateObjectReference UnitRef;

		super.EndState(NextStateName);

		// Send intertrack messages
		for (i = 0; i < MatineeUnitRefs.Length; ++i )
		{
			UnitRef = MatineeUnitRefs[i];
			VisualizationMgr.SendInterTrackMessage( UnitRef );
		}

		`BATTLE.SetFOW(true);
	}
}

function GetAllIntroSlotPrefixes(out array<string> Names)
{
	local int i;
	Names.AddItem("Advent");
	for (i = 0; i < ATTMappings.Length; i++)
	{
		if (Names.Find(ATTMappings[i].MatineePrefixPath) == INDEX_NONE)
		{
			Names.AddItem(ATTMappings[i].MatineePrefixPath);
		}
	}
}


DefaultProperties
{
}
