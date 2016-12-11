//---------------------------------------------------------------------------------------
//  FILE:    XComGameState_KismetVariable.uc
//  AUTHOR:  David Burchanowski  --  1/15/2014
//  PURPOSE: This object represents the instance data for kismet
//           
//---------------------------------------------------------------------------------------
//  Copyright (c) 2016 Firaxis Games, Inc. All rights reserved.
//---------------------------------------------------------------------------------------
// robojumperHighlander: make it moddable!
class XComGameState_KismetVariable extends XComGameState_BaseObject native(Core);

/// <summary>
// variable name of this kismet variable.
/// </summary>
var privatewrite string VarName;

// only one of these will be filled out, depending on var type.
// what a lovely place for a union.
var int IntValue;
var float FloatValue;
var bool BoolValue;
var string StringValue;
var vector VectorValue;
var string ObjectName;

native function string ToString(optional bool bAllFields);

DefaultProperties
{	
}
