// This class is a stack for Controller rumbles, akin to the CameraStack
// it manages a list of ForceFeedbackWaveforms
// however, we can't combine them directly - we have to build our own parser and wave functions...

// it is safe to push a ForceFeedbackWaveForm multiple times
class robojumperRumbleStack extends Actor;

var array<robojumperRumbleContainer> PlayingWaveForms;

var ForceFeedbackWaveform OurWaveform;

static function robojumperRumbleStack GetRumbleStack()
{
	// how?
}


function AddWaveForm(ForceFeedbackWaveform Waveform)
{
	local robojumperRumbleContainer Container;
	Container = new class'robojumperRumbleContainer';
	Container.InitRumbleContainer(Waveform);
	PlayingWaveForms.AddItem(Container);
}

function RemoveWaveForm(ForceFeedbackWaveform Waveform)
{
	local int i;
	for (i = PlayingWaveForms.Length - 1; i >= 0; i--)
	{
		if (PlayingWaveForms[i].ffCurrentWaveform == Waveform) 
		{
			PlayingWaveForms.Remove(i, 1);
			return;
		}
	}
}

function Tick(float fDeltaTime)
{
	local int i;
	local int CurrentAmplitudeLeft, CurrentAmplitudeRight, CheckAmplitudeLeft, CheckAmplitudeRight;

	local float fScaleFactor;
	if (GetFFManager().bIsPaused)
	{
		return;
	}
	for (i = PlayingWaveForms.Length - 1; i >= 0; i--)
	{
		PlayingWaveForms[i].Update(fDeltaTime);
		if (PlayingWaveForms[i].RanOut())
		{
			PlayingWaveForms.Remove(i, 1);
			continue;
		}
		PlayingWaveForms[i].GetCurrentRumbleStrength(CheckAmplitudeLeft, CheckAmplitudeRight);
		CurrentAmplitudeLeft += CheckAmplitudeLeft;
		CurrentAmplitudeRight += CheckAmplitudeRight;
	}
	// amplitudes might be larger than 100. Normalize amplitudes and set the general scale in the ForceFeedbackManager
	//fScaleFactor = Max(CurrentAmplitudeLeft, CurrentAmplitudeRight) / 100;
	//CurrentAmplitudeLeft *= fScaleFactor;
	//CurrentAmplitudeRight *= fScaleFactor;

	OurWaveform.Samples[0].LeftAmplitude = CurrentAmplitudeLeft;
	OurWaveform.Samples[0].RightAmplitude = CurrentAmplitudeRight;

	//GetFFManager().ScaleAllWaveformsBy = fScaleFactor;
	GetFFManager().PlayForceFeedbackWaveform(OurWaveform, none);
}


function ForceFeedbackManager GetFFManager()
{
	return GetALocalPlayerController().ForceFeedbackManager;
}

defaultproperties
{
	Begin Object Class=ForceFeedbackWaveform Name=OurFFWF
		Samples(0)=(LeftAmplitude=0,RightAmplitude=0,LeftFunction=WF_Constant,RightFunction=WF_Constant,Duration=.1)
	End Object

	OurWaveform=OurFFWF

}