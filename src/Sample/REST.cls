/// REST API for the hepatitis patient dashboard.
///
/// Endpoints (all under /api which is registered by Sample.RESTSetup):
///   GET  /api/health            - readiness probe
///   GET  /api/patients          - list every patient + latest prediction
///   GET  /api/patients/:id      - full feature record for one patient
///   POST /api/predict/:id       - run ML prediction for one patient and persist it
///   POST /api/predict-all       - run ML prediction for every patient, return summary
///   POST /api/chat              - body {"message": "..."} -> agent reply
Class Sample.REST Extends %CSP.REST
{

Parameter HandleCorsRequest = 1;

Parameter CONVERTINPUTSTREAM = 1;

Parameter CHARSET = "utf-8";

XData UrlMap [ XMLNamespace = "http://www.intersystems.com/urlmap" ]
{
<Routes>
    <Route Url="/health" Method="GET" Call="Health"/>
    <Route Url="/patients" Method="GET" Call="GetAllPatients"/>
    <Route Url="/patients/:id" Method="GET" Call="GetPatient"/>
    <Route Url="/predict/:id" Method="POST" Call="PredictMortality"/>
    <Route Url="/predict-all" Method="POST" Call="PredictAll"/>
    <Route Url="/chat" Method="POST" Call="ChatWithAgent"/>
</Routes>
}

/// Permissive CORS so the Vite dev server (or any browser) can hit the API.
ClassMethod OnHandleCorsRequest(pUrl As %String) As %Status
{
    Set origin = $Get(%request.CgiEnvs("HTTP_ORIGIN"), "*")
    Do %response.SetHeader("Access-Control-Allow-Origin", origin)
    Do %response.SetHeader("Vary", "Origin")
    Do %response.SetHeader("Access-Control-Allow-Credentials", "true")
    Do %response.SetHeader("Access-Control-Allow-Methods", "GET, POST, PUT, DELETE, OPTIONS")
    Do %response.SetHeader("Access-Control-Allow-Headers", "Content-Type, Authorization, Accept")
    Do %response.SetHeader("Access-Control-Max-Age", "86400")
    Quit $$$OK
}

ClassMethod Health() As %Status
{
    Set %response.ContentType = "application/json"
    Write {"status": "ok", "service": "hepatitis-rest"}.%ToJSON()
    Quit $$$OK
}

ClassMethod GetAllPatients() As %Status
{
    Set %response.ContentType = "application/json"
    Set patients = []
    Set sql = "SELECT PatientId, Age, Sex, Bilirubin, AlkPhosphate, SGOT, Albumin, ProTime, "
        _ "MortalityProbability, RiskLevel, PredictionStatus "
        _ "FROM Sample.HepatitisPatient ORDER BY PatientId"
    Set stmt = ##class(%SQL.Statement).%New()
    Set sc = stmt.%Prepare(sql)
    If $$$ISERR(sc) {
        Set %response.Status = 500
        Write {"error": ($System.Status.GetErrorText(sc))}.%ToJSON()
        Quit $$$OK
    }
    Set rs = stmt.%Execute()
    While rs.%Next() {
        Do patients.%Push({
            "patientId": (rs.%Get("PatientId")),
            "age": (rs.%Get("Age")),
            "sex": (rs.%Get("Sex")),
            "bilirubin": (rs.%Get("Bilirubin")),
            "alkPhosphate": (rs.%Get("AlkPhosphate")),
            "sgot": (rs.%Get("SGOT")),
            "albumin": (rs.%Get("Albumin")),
            "proTime": (rs.%Get("ProTime")),
            "mortalityProbability": (rs.%Get("MortalityProbability")),
            "riskLevel": (rs.%Get("RiskLevel")),
            "predictionStatus": (rs.%Get("PredictionStatus"))
        })
    }
    Write patients.%ToJSON()
    Quit $$$OK
}

ClassMethod GetPatient(id As %String) As %Status
{
    Set %response.ContentType = "application/json"
    Set patient = ##class(Sample.HepatitisPatient).%OpenId(id)
    If '$IsObject(patient) {
        Set %response.Status = 404
        Write {"error": "Patient not found", "patientId": (id)}.%ToJSON()
        Quit $$$OK
    }
    Write ..%PatientToJSON(patient).%ToJSON()
    Quit $$$OK
}

ClassMethod PredictMortality(id As %String) As %Status
{
    Set %response.ContentType = "application/json"
    Set patient = ##class(Sample.HepatitisPatient).%OpenId(id)
    If '$IsObject(patient) {
        Set %response.Status = 404
        Write {"error": "Patient not found", "patientId": (id)}.%ToJSON()
        Quit $$$OK
    }

    Set features = ..%PatientToFeatures(patient)
    Set resultJson = ..%PredictJSON(features.%ToJSON())
    Set result = {}.%FromJSON(resultJson)

    If result.error '= "" {
        Set %response.Status = 500
        Write resultJson
        Quit $$$OK
    }

    // Persist for fast list display
    Set patient.MortalityProbability = result.%Get("mortality_probability")
    Set patient.RiskLevel = result.%Get("risk_level")
    Set patient.PredictionStatus = "completed"
    Set patient.PredictionTimestamp = $ZDateTime($Horolog, 3)
    Do patient.%Save()

    Do result.%Set("patientId", id)
    Write result.%ToJSON()
    Quit $$$OK
}

ClassMethod PredictAll() As %Status
{
    Set %response.ContentType = "application/json"
    Set summary = {
        "processed": 0,
        "standardTreatment": 0,
        "clinicalTrialCandidate": 0,
        "critical": 0,
        "errors": 0
    }
    Set details = []

    Set stmt = ##class(%SQL.Statement).%New()
    Do stmt.%Prepare("SELECT PatientId FROM Sample.HepatitisPatient ORDER BY PatientId")
    Set rs = stmt.%Execute()
    While rs.%Next() {
        Set pid = rs.%Get("PatientId")
        Set patient = ##class(Sample.HepatitisPatient).%OpenId(pid)
        If '$IsObject(patient) Continue

        Set features = ..%PatientToFeatures(patient)
        Set resultJson = ..%PredictJSON(features.%ToJSON())
        Set result = {}.%FromJSON(resultJson)
        If result.error '= "" {
            Do summary.%Set("errors", summary.errors + 1)
            Continue
        }

        Set patient.MortalityProbability = result.%Get("mortality_probability")
        Set patient.RiskLevel = result.%Get("risk_level")
        Set patient.PredictionStatus = "completed"
        Set patient.PredictionTimestamp = $ZDateTime($Horolog, 3)
        Do patient.%Save()

        Do summary.%Set("processed", summary.processed + 1)
        Set rl = result.%Get("risk_level")
        If rl = "STANDARD_TREATMENT" Do summary.%Set("standardTreatment", summary.standardTreatment + 1)
        If rl = "CLINICAL_TRIAL_CANDIDATE" Do summary.%Set("clinicalTrialCandidate", summary.clinicalTrialCandidate + 1)
        If rl = "CRITICAL" Do summary.%Set("critical", summary.critical + 1)

        Do details.%Push({
            "patientId": (pid),
            "mortalityProbability": (result.%Get("mortality_probability")),
            "riskLevel": (rl)
        })
    }

    Do summary.%Set("details", details)
    Write summary.%ToJSON()
    Quit $$$OK
}

/// Body: {"message": "..."}.
/// Response: {"response": "..."}.
ClassMethod ChatWithAgent() As %Status
{
    Set %response.ContentType = "application/json"
    Try {
        Set body = {}.%FromJSON(%request.Content)
        Set message = body.message
        If message = "" {
            Set %response.Status = 400
            Write {"error": "message is required"}.%ToJSON()
            Quit
        }

        Set agent = ##class(Sample.Agent).%New()
        Set sc = agent.%CreateProvider()
        If $$$ISERR(sc) {
            Set %response.Status = 500
            Write {"error": ($System.Status.GetErrorText(sc))}.%ToJSON()
            Quit
        }

        Set session = agent.CreateSession()
        Set response = agent.Chat(session, message)

        Write {"response": (response.Content)}.%ToJSON()

    } Catch ex {
        Set %response.Status = 500
        Write {"error": (ex.DisplayString())}.%ToJSON()
    }
    Quit $$$OK
}

ClassMethod %PatientToJSON(patient As Sample.HepatitisPatient) As %DynamicObject
{
    Quit {
        "patientId": (patient.PatientId),
        "age": (patient.Age),
        "sex": (patient.Sex),
        "steroid": (patient.Steroid),
        "antivirals": (patient.Antivirals),
        "fatigue": (patient.Fatigue),
        "malaise": (patient.Malaise),
        "anorexia": (patient.Anorexia),
        "liverBig": (patient.LiverBig),
        "liverFirm": (patient.LiverFirm),
        "spleenPalpable": (patient.SpleenPalpable),
        "spiders": (patient.Spiders),
        "ascites": (patient.Ascites),
        "varices": (patient.Varices),
        "bilirubin": (patient.Bilirubin),
        "alkPhosphate": (patient.AlkPhosphate),
        "sgot": (patient.SGOT),
        "albumin": (patient.Albumin),
        "proTime": (patient.ProTime),
        "histology": (patient.Histology),
        "mortalityProbability": (patient.MortalityProbability),
        "riskLevel": (patient.RiskLevel),
        "predictionStatus": (patient.PredictionStatus),
        "predictionTimestamp": (patient.PredictionTimestamp)
    }
}

/// Build a feature %DynamicObject in the column order the trained model expects.
ClassMethod %PatientToFeatures(patient As Sample.HepatitisPatient) As %DynamicObject
{
    Quit {
        "age": (patient.Age),
        "sex": (patient.Sex),
        "steroid": (patient.Steroid),
        "antivirals": (patient.Antivirals),
        "fatigue": (patient.Fatigue),
        "malaise": (patient.Malaise),
        "anorexia": (patient.Anorexia),
        "liverbig": (patient.LiverBig),
        "liverfirm": (patient.LiverFirm),
        "spleenpalpable": (patient.SpleenPalpable),
        "spiders": (patient.Spiders),
        "ascites": (patient.Ascites),
        "varices": (patient.Varices),
        "bilirubin": (patient.Bilirubin),
        "alkphosphate": (patient.AlkPhosphate),
        "sgot": (patient.SGOT),
        "albumin": (patient.Albumin),
        "protime": (patient.ProTime),
        "histology": (patient.Histology)
    }
}

/// Embedded Python predictor. Receives a JSON feature dict and returns a JSON
/// result string.  Caches the model in a module global so the pickle is only
/// loaded once per IRIS process.
ClassMethod %PredictJSON(featuresJson As %String) As %String [ Language = python ]
{
    import json
    import sys

    try:
        if "/home/irisowner/dev" not in sys.path:
            sys.path.insert(0, "/home/irisowner/dev")

        from ml_pipeline.model_optimized import OptimizedHepatitisModel
        import pandas as pd

        global _hepatitis_model
        try:
            _hepatitis_model
        except NameError:
            _hepatitis_model = None

        if _hepatitis_model is None:
            m = OptimizedHepatitisModel()
            m.load_model("/home/irisowner/dev/ml_pipeline/best_hepatitis_optimized.pkl")
            _hepatitis_model = m

        feature_dict = json.loads(featuresJson)
        # Replace any None with 0 so the scaler does not blow up.
        feature_dict = {k: [0 if v is None else v] for k, v in feature_dict.items()}
        df = pd.DataFrame(feature_dict)

        prob = float(_hepatitis_model.predict_mortality_probability(df)[0])

        if prob > 0.85:
            risk = "CRITICAL"
            rec = "CRITICAL: Focus on patient care and quality of life. Mortality risk >85%."
        elif prob >= 0.50:
            risk = "CLINICAL_TRIAL_CANDIDATE"
            rec = "RECOMMEND CLINICAL TRIAL: Patient is a candidate for clinical trial enrollment. Mortality risk 50-85%."
        else:
            risk = "STANDARD_TREATMENT"
            rec = "CONTINUE STANDARD TREATMENT: Patient should continue on current treatment protocol. Mortality risk <50%."

        return json.dumps({
            "mortality_probability": prob,
            "mortality_percentage": f"{prob * 100:.2f}%",
            "risk_level": risk,
            "recommendation": rec,
            "error": "",
        })

    except Exception as ex:
        return json.dumps({
            "mortality_probability": -1.0,
            "mortality_percentage": "ERROR",
            "risk_level": "ERROR",
            "recommendation": "",
            "error": f"{type(ex).__name__}: {ex}",
        })
}

}
