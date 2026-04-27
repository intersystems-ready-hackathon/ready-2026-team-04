Class CTEA.Tool Extends %AI.Tool
{

Parameter DESCRIPTION = "Retrieves and analyses hepatitis patient records including demographics, lab values, clinical signs, treatments, and survival outcome.";

/// Returns all hepatitis patient records.
Query GetAllPatients() As %SQLQuery(ROWSPEC = "age:%Integer,albumin:%Double,alkphosphate:%Integer,anorexia:%Boolean,antivirals:%Boolean,ascites:%Boolean,bilirubin:%Double,fatigue:%Boolean,histology:%Boolean,liverbig:%Boolean,liverfirm:%Boolean,malaise:%Boolean,outcome:%String,protime:%String,sex:%String,sgot:%Integer,spiders:%Boolean,spleenpalpable:%Boolean,steroid:%Boolean,varices:%Boolean") [ SqlProc ]
{
    SELECT
        age, albumin, alkphosphate, anorexia, antivirals, ascites,
        bilirubin, fatigue, histology, liverbig, liverfirm, malaise,
        outcome, protime, sex, sgot, spiders, spleenpalpable, steroid, varices
    FROM dc_data_health.Hepatitis
}

Query CountPatients() As %SQLQuery(ROWSPEC = "patient_count:%Integer") [ SqlProc ]
{
    SELECT COUNT(*) AS patient_count
    FROM dc_data_health.Hepatitis
}

/// Search patients with optional filters. Pass empty string for outcome/sex to return all. Pass 0 for minAge/maxAge to skip age filtering.
Query SearchPatients(outcome As %String, sex As %String, minAge As %Integer, maxAge As %Integer) As %SQLQuery(ROWSPEC = "age:%Integer,sex:%String,outcome:%String,bilirubin:%Double,albumin:%Double,sgot:%Integer,alkphosphate:%Integer,protime:%String,ascites:%Boolean,varices:%Boolean,spiders:%Boolean,fatigue:%Boolean,anorexia:%Boolean,liverbig:%Boolean,liverfirm:%Boolean,spleenpalpable:%Boolean,malaise:%Boolean,antivirals:%Boolean,steroid:%Boolean,histology:%Boolean") [ SqlProc ]
{
    SELECT age, sex, outcome,
           bilirubin, albumin, sgot, alkphosphate, protime,
           ascites, varices, spiders, fatigue, anorexia,
           liverbig, liverfirm, spleenpalpable, malaise,
           antivirals, steroid, histology
    FROM dc_data_health.Hepatitis
    WHERE (:outcome = '' OR outcome = :outcome)
      AND (:sex = '' OR sex = :sex)
      AND (:minAge = 0 OR age >= :minAge)
      AND (:maxAge = 0 OR age <= :maxAge)
    ORDER BY age
}

/// Aggregate statistics grouped by outcome (live/die): count, average age, and average lab values.
Query GetOutcomeStats() As %SQLQuery(ROWSPEC = "outcome:%String,patient_count:%Integer,avg_age:%Double,avg_bilirubin:%Double,avg_albumin:%Double,avg_sgot:%Double,avg_alkphosphate:%Double,avg_protime:%Double") [ SqlProc ]
{
    SELECT outcome,
           COUNT(*) AS patient_count,
           AVG(age) AS avg_age,
           AVG(bilirubin) AS avg_bilirubin,
           AVG(albumin) AS avg_albumin,
           AVG(sgot) AS avg_sgot,
           AVG(alkphosphate) AS avg_alkphosphate,
           AVG(protime) AS avg_protime
    FROM dc_data_health.Hepatitis
    GROUP BY outcome
}

/// Count of each clinical risk factor and symptom grouped by outcome (live/die).
Query GetRiskFactorCounts() As %SQLQuery(ROWSPEC = "outcome:%String,total_patients:%Integer,ascites_count:%Integer,varices_count:%Integer,spiders_count:%Integer,liverbig_count:%Integer,liverfirm_count:%Integer,spleenpalpable_count:%Integer,fatigue_count:%Integer,anorexia_count:%Integer,malaise_count:%Integer") [ SqlProc ]
{
    SELECT outcome,
           COUNT(*) AS total_patients,
           SUM(CASE WHEN ascites = 1 THEN 1 ELSE 0 END) AS ascites_count,
           SUM(CASE WHEN varices = 1 THEN 1 ELSE 0 END) AS varices_count,
           SUM(CASE WHEN spiders = 1 THEN 1 ELSE 0 END) AS spiders_count,
           SUM(CASE WHEN liverbig = 1 THEN 1 ELSE 0 END) AS liverbig_count,
           SUM(CASE WHEN liverfirm = 1 THEN 1 ELSE 0 END) AS liverfirm_count,
           SUM(CASE WHEN spleenpalpable = 1 THEN 1 ELSE 0 END) AS spleenpalpable_count,
           SUM(CASE WHEN fatigue = 1 THEN 1 ELSE 0 END) AS fatigue_count,
           SUM(CASE WHEN anorexia = 1 THEN 1 ELSE 0 END) AS anorexia_count,
           SUM(CASE WHEN malaise = 1 THEN 1 ELSE 0 END) AS malaise_count
    FROM dc_data_health.Hepatitis
    GROUP BY outcome
}

/// Runs the trained hepatitis mortality ML model (scikit-learn ensemble, 87% accuracy)
/// on every patient in dc_data_health.Hepatitis.
///
/// Returns a JSON string with:
///   total_patients: int
///   counts: { STANDARD_TREATMENT, CLINICAL_TRIAL_CANDIDATE, CRITICAL }
///   thresholds: probability cutoffs used for each bucket
///   patients: list of { row, age, sex, outcome, probability, risk_level }
///
/// Risk buckets:
///   STANDARD_TREATMENT       — mortality probability < 0.50
///   CLINICAL_TRIAL_CANDIDATE — 0.50 <= probability <= 0.85
///   CRITICAL                 — probability > 0.85
ClassMethod PredictMortalityForAllPatients() As %String [ Language = python ]
{
    import sys, json, traceback
    try:
        if "/home/irisowner/dev" not in sys.path:
            sys.path.insert(0, "/home/irisowner/dev")
        from ml_pipeline.model_optimized import OptimizedHepatitisModel
        import pandas as pd
        import iris

        global _cte_hep_model
        try:
            _cte_hep_model
        except NameError:
            _cte_hep_model = None
        if _cte_hep_model is None:
            m = OptimizedHepatitisModel()
            m.load_model("/home/irisowner/dev/ml_pipeline/best_hepatitis_optimized.pkl")
            _cte_hep_model = m
        model = _cte_hep_model

        feature_cols = model.feature_names  # order as trained

        select_cols = ", ".join(feature_cols + ["outcome"])
        rs = iris.sql.exec(f"SELECT {select_cols} FROM dc_data_health.Hepatitis")
        rows = [list(r) for r in rs]
        if not rows:
            return json.dumps({"error": "No patients found in dc_data_health.Hepatitis"})

        df = pd.DataFrame(rows, columns=feature_cols + ["outcome"])
        outcomes = df["outcome"].tolist()
        ages = df["age"].tolist()
        sexes = df["sex"].tolist()

        X = df[feature_cols].copy()

        # Apply saved label encoders for any non-numeric columns.
        for col, le in model.label_encoders.items():
            if col not in X.columns:
                continue
            known = set(le.classes_.tolist())
            def _encode(v):
                if v is None:
                    v = "missing"
                s = str(v)
                if s in known:
                    return s
                # common bool normalisation
                low = s.strip().lower()
                if low in ("true", "t", "1", "yes"): s2 = "True"
                elif low in ("false", "f", "0", "no"): s2 = "False"
                else: s2 = s
                if s2 in known:
                    return s2
                if "missing" in known:
                    return "missing"
                return le.classes_[0]
            X[col] = X[col].apply(_encode)
            X[col] = le.transform(X[col])

        # Numeric: coerce + fill medians
        for col in X.columns:
            if col in model.label_encoders:
                continue
            X[col] = pd.to_numeric(X[col], errors="coerce")
            med = X[col].median()
            X[col] = X[col].fillna(med if pd.notna(med) else 0)

        X = X[feature_cols]
        probs = model.predict_mortality_probability(X)

        counts = {"STANDARD_TREATMENT": 0, "CLINICAL_TRIAL_CANDIDATE": 0, "CRITICAL": 0}
        patients = []
        for i, p in enumerate(probs):
            p = float(p)
            if p > 0.85:
                lvl = "CRITICAL"
            elif p >= 0.50:
                lvl = "CLINICAL_TRIAL_CANDIDATE"
            else:
                lvl = "STANDARD_TREATMENT"
            counts[lvl] += 1
            patients.append({
                "row": i + 1,
                "age": int(ages[i]) if ages[i] is not None else None,
                "sex": sexes[i],
                "actual_outcome": outcomes[i],
                "probability": round(p, 4),
                "risk_level": lvl,
            })

        return json.dumps({
            "total_patients": len(patients),
            "counts": counts,
            "thresholds": {
                "STANDARD_TREATMENT": "probability < 0.50",
                "CLINICAL_TRIAL_CANDIDATE": "0.50 <= probability <= 0.85",
                "CRITICAL": "probability > 0.85",
            },
            "patients": patients,
        })

    except Exception as ex:
        return json.dumps({
            "error": f"{type(ex).__name__}: {ex}",
            "traceback": traceback.format_exc(),
        })
}

/// Runs the mortality ML model for a single hepatitis patient whose feature values
/// are supplied directly. Returns a JSON string with probability, percentage,
/// risk level, and a recommendation.
///
/// Arg conventions (matching training data):
///   sex: "male" or "female"
///   boolean args (steroid, antivirals, fatigue, malaise, anorexia, liverbig,
///     liverfirm, spleenpalpable, spiders, ascites, varices, histology):
///     pass "True" / "False"
///   numeric args (age, bilirubin, alkphosphate, sgot, albumin, protime):
///     pass as numbers
ClassMethod PredictMortalityForPatient(age As %Integer, sex As %String, steroid As %String, antivirals As %String, fatigue As %String, malaise As %String, anorexia As %String, liverbig As %String, liverfirm As %String, spleenpalpable As %String, spiders As %String, ascites As %String, varices As %String, bilirubin As %Double, alkphosphate As %Double, sgot As %Double, albumin As %Double, protime As %Double, histology As %String) As %String [ Language = python ]
{
    import sys, json, traceback
    try:
        if "/home/irisowner/dev" not in sys.path:
            sys.path.insert(0, "/home/irisowner/dev")
        from ml_pipeline.model_optimized import OptimizedHepatitisModel
        import pandas as pd

        global _cte_hep_model
        try:
            _cte_hep_model
        except NameError:
            _cte_hep_model = None
        if _cte_hep_model is None:
            m = OptimizedHepatitisModel()
            m.load_model("/home/irisowner/dev/ml_pipeline/best_hepatitis_optimized.pkl")
            _cte_hep_model = m
        model = _cte_hep_model

        raw = {
            "age": age, "sex": sex, "steroid": steroid, "antivirals": antivirals,
            "fatigue": fatigue, "malaise": malaise, "anorexia": anorexia,
            "liverbig": liverbig, "liverfirm": liverfirm,
            "spleenpalpable": spleenpalpable, "spiders": spiders,
            "ascites": ascites, "varices": varices, "bilirubin": bilirubin,
            "alkphosphate": alkphosphate, "sgot": sgot, "albumin": albumin,
            "protime": protime, "histology": histology,
        }
        df = pd.DataFrame({k: [v] for k, v in raw.items()})

        for col, le in model.label_encoders.items():
            if col not in df.columns:
                continue
            known = set(le.classes_.tolist())
            def _norm(v):
                if v is None:
                    v = "missing"
                s = str(v).strip()
                if s in known:
                    return s
                low = s.lower()
                if low in ("true", "t", "1", "yes"): s2 = "True"
                elif low in ("false", "f", "0", "no"): s2 = "False"
                else: s2 = s
                if s2 in known:
                    return s2
                if "missing" in known:
                    return "missing"
                return le.classes_[0]
            df[col] = df[col].apply(_norm)
            df[col] = le.transform(df[col])

        for col in df.columns:
            if col in model.label_encoders:
                continue
            df[col] = pd.to_numeric(df[col], errors="coerce").fillna(0)

        df = df[model.feature_names]
        prob = float(model.predict_mortality_probability(df)[0])

        if prob > 0.85:
            lvl = "CRITICAL"
            rec = "Mortality risk >85%. Focus on patient care and quality of life."
        elif prob >= 0.50:
            lvl = "CLINICAL_TRIAL_CANDIDATE"
            rec = "Mortality risk 50-85%. Patient is a candidate for clinical trial enrollment."
        else:
            lvl = "STANDARD_TREATMENT"
            rec = "Mortality risk <50%. Continue standard treatment protocol."

        return json.dumps({
            "mortality_probability": round(prob, 4),
            "mortality_percentage": f"{prob * 100:.2f}%",
            "risk_level": lvl,
            "recommendation": rec,
        })

    except Exception as ex:
        return json.dumps({
            "error": f"{type(ex).__name__}: {ex}",
            "traceback": traceback.format_exc(),
        })
}

}
