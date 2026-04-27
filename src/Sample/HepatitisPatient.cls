Class Sample.HepatitisPatient Extends %Persistent
{

Property PatientId As %Integer [ Identity ];

Property Age As %Integer;

Property Sex As %Integer;

Property Steroid As %Integer;

Property Antivirals As %Integer;

Property Fatigue As %Integer;

Property Malaise As %Integer;

Property Anorexia As %Integer;

Property LiverBig As %Integer;

Property LiverFirm As %Integer;

Property SpleenPalpable As %Integer;

Property Spiders As %Integer;

Property Ascites As %Integer;

Property Varices As %Integer;

Property Bilirubin As %Float;

Property AlkPhosphate As %Float;

Property SGOT As %Float;

Property Albumin As %Float;

Property ProTime As %Float;

Property Histology As %Integer;

Property MortalityProbability As %Float;

Property RiskLevel As %String;

Property PredictionStatus As %String [ InitialExpression = "pending" ];

Property PredictionTimestamp As %TimeStamp;

Storage Default
{
<Data name="HepatitisPatientDefaultData">
<Value name="1">
<Value>%%CLASSNAME</Value>
</Value>
<Value name="2">
<Value>Age</Value>
</Value>
<Value name="3">
<Value>Sex</Value>
</Value>
<Value name="4">
<Value>Steroid</Value>
</Value>
<Value name="5">
<Value>Antivirals</Value>
</Value>
<Value name="6">
<Value>Fatigue</Value>
</Value>
<Value name="7">
<Value>Malaise</Value>
</Value>
<Value name="8">
<Value>Anorexia</Value>
</Value>
<Value name="9">
<Value>LiverBig</Value>
</Value>
<Value name="10">
<Value>LiverFirm</Value>
</Value>
<Value name="11">
<Value>SpleenPalpable</Value>
</Value>
<Value name="12">
<Value>Spiders</Value>
</Value>
<Value name="13">
<Value>Ascites</Value>
</Value>
<Value name="14">
<Value>Varices</Value>
</Value>
<Value name="15">
<Value>Bilirubin</Value>
</Value>
<Value name="16">
<Value>AlkPhosphate</Value>
</Value>
<Value name="17">
<Value>SGOT</Value>
</Value>
<Value name="18">
<Value>Albumin</Value>
</Value>
<Value name="19">
<Value>ProTime</Value>
</Value>
<Value name="20">
<Value>Histology</Value>
</Value>
<Value name="21">
<Value>MortalityProbability</Value>
</Value>
<Value name="22">
<Value>RiskLevel</Value>
</Value>
<Value name="23">
<Value>PredictionStatus</Value>
</Value>
<Value name="24">
<Value>PredictionTimestamp</Value>
</Value>
</Data>
<DataLocation>^Sample.HepatitisPatientD</DataLocation>
<DefaultData>HepatitisPatientDefaultData</DefaultData>
<IdLocation>^Sample.HepatitisPatientD</IdLocation>
<IndexLocation>^Sample.HepatitisPatientI</IndexLocation>
<StreamLocation>^Sample.HepatitisPatientS</StreamLocation>
<Type>%Storage.Persistent</Type>
}

}
