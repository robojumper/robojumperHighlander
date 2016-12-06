// This is an object that contains a single ForceFeedbackWaveform
// it is responsible for calculating the current rumble strength
class robojumperRumbleContainer extends Object;

var protectedwrite ForceFeedbackWaveform ffCurrentWaveform;
var protected float fCurrTime;


// cached
var protected float fMaxTime;
var protected bool bIsLooping;

function robojumperRumbleContainer InitRumbleContainer(ForceFeedbackWaveform inWaveForm)
{
	local int i;
	ffCurrentWaveform = inWaveForm;

	for (i = 0; i < ffCurrentWaveform.Samples.Length; i++)
	{
		fMaxTime += ffCurrentWaveform.Samples[i].Duration;
	}
	if (fMaxTime == 0.0f)
	{
		`REDSCREEN("robojumperRumbleContainer: Inited a waveform without a running time. ScriptTrace:" @ GetScriptTrace());
	}
	bIsLooping = ffCurrentWaveform.bIsLooping;

	return self;
}

function Update(float fDeltaTime)
{
	fCurrTime += fDeltaTime;
	while (fCurrTime > fMaxTime && bIsLooping)
	{
		fCurrTime -= fMaxTime;
	}
}

function bool RanOut()
{
	return fCurrTime > fMaxTime;
}

protected function GetCurrentSampleWithPlayingTime(out WaveformSample Sample, out float Time)
{
	local int i;

	Time = fCurrTime;
	i = 0;
	Sample = ffCurrentWaveform.Samples[0];
	while (Time > Sample.Duration)
	{
		Time -= Sample.Duration;
		Sample = ffCurrentWaveform.Samples[i++];
	}	
}
// 0-100
function GetCurrentRumbleStrength(out int LeftStrength, out int RightStrength)
{
	local WaveformSample Sample;
	local float fTime;

	GetCurrentSampleWithPlayingTime(Sample, fTime);
	fTime = fTime / Sample.Duration;

	LeftStrength = GetStrengthForSample(Sample.LeftAmplitude, Sample.LeftFunction, fTime);
	RightStrength = GetStrengthForSample(Sample.RightAmplitude, Sample.RightFunction, fTime);

}

// progress from [0,1]
protected static function int GetStrengthForSample(int iStrength, EWaveformFunction eFunc, float fProgress)
{
	switch (eFunc)
	{
		case WF_Constant:
			return iStrength;
		case WF_LinearIncreasing:
			return iStrength * fProgress;
		case WF_LinearDecreasing:
			return iStrength * (1 - fProgress);
		case WF_Sin0to90:
			return iStrength * Sin(fProgress * (Pi / 2));
		case WF_Sin90to180:
			return iStrength * Sin((fProgress * (Pi / 2)) + (Pi / 2));
		case WF_Sin0to180:
			return iStrength * Sin(fProgress * Pi);
		case WF_Noise:
			return Rand(iStrength);
		default:
			`REDSCREEN("Unhandled WF_" @ eFunc);
	}
}