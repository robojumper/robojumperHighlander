// The purpose of this class is to not break the data layout of native classes
class robojumperHighlander extends Object abstract;


var array<name> NativeTargetStyles;

var bool bUseRumble;

var array<string> AdditionalDropshipInteriorMatinees;


static function robojumperHighlander GetConfig()
{
	return robojumperHighlander(class'XComEngine'.static.GetClassDefaultObject(default.Class));
}


defaultproperties
{

	// MultiTargetStyles
	NativeTargetStyles[0]="X2AbilityMultiTarget_AllAllies"
	NativeTargetStyles[1]="X2AbilityMultiTarget_AllUnits"
	NativeTargetStyles[2]="X2AbilityMultiTarget_BlazingPinions"
	NativeTargetStyles[3]="X2AbilityMultiTarget_BurstFire"
	NativeTargetStyles[4]="X2AbilityMultiTarget_Cone"
	NativeTargetStyles[5]="X2AbilityMultiTarget_Cylinder"
	NativeTargetStyles[6]="X2AbilityMultiTarget_Line"
	NativeTargetStyles[7]="X2AbilityMultiTarget_Loot"
	NativeTargetStyles[8]="X2AbilityMultiTarget_Radius"
	NativeTargetStyles[9]="X2AbilityMultiTarget_SoldierBonusRadius"
	// TargetStyles
	NativeTargetStyles[10]="X2AbilityTarget_Cursor"
	NativeTargetStyles[11]="X2AbilityTarget_MovingMelee"
	NativeTargetStyles[12]="X2AbilityTarget_Path"
	NativeTargetStyles[13]="X2AbilityTarget_Self"
	NativeTargetStyles[14]="X2AbilityTarget_Single"

	bUseRumble = true;
}