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

}
