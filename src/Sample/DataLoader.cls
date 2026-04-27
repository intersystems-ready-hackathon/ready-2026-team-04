/// Seeds Sample.HepatitisPatient from ml_pipeline/hepatitis.csv on container startup.
/// Idempotent: if the table already has rows, this is a no-op.
Class Sample.DataLoader Extends %RegisteredObject
{

Parameter CSVPATH = "/home/irisowner/dev/ml_pipeline/hepatitis.csv";

ClassMethod Run() As %Status
{
    Set count = ..%CountPatients()
    If count > 0 {
        Write "Sample.HepatitisPatient already has ", count, " rows; skipping seed.", !
        Quit $$$OK
    }
    Write "Seeding Sample.HepatitisPatient from CSV...", !
    Set inserted = ..%LoadCSV(..#CSVPATH)
    Write "Inserted ", inserted, " hepatitis patients.", !
    Quit $$$OK
}

ClassMethod %CountPatients() As %Integer
{
    Set stmt = ##class(%SQL.Statement).%New()
    Do stmt.%Prepare("SELECT COUNT(*) AS C FROM Sample.HepatitisPatient")
    Set rs = stmt.%Execute()
    If rs.%Next() Quit rs.%Get("C")
    Quit 0
}

/// Loads the CSV via Embedded Python (pandas + iris) and inserts into the persistent class.
ClassMethod %LoadCSV(path As %String) As %Integer [ Language = python ]
{
    import iris
    import pandas as pd
    import math

    BOOL_COLS = [
        "steroid", "antivirals", "fatigue", "malaise", "anorexia",
        "liverbig", "liverfirm", "spleenpalpable", "spiders",
        "ascites", "varices", "histology",
    ]

    df = pd.read_csv(path)
    # Sex: female=0, male=1
    df["sex"] = df["sex"].astype(str).str.lower().map({"female": 0, "male": 1}).fillna(0)
    # Booleans -> 0/1
    for c in BOOL_COLS:
        df[c] = df[c].astype(str).str.lower().map(
            {"true": 1, "false": 0, "1": 1, "0": 0}
        ).fillna(0)
    # Numeric columns: fill missing with column median
    NUMERIC_COLS = ["age", "bilirubin", "alkphosphate", "sgot", "albumin", "protime"]
    for c in NUMERIC_COLS:
        df[c] = pd.to_numeric(df[c], errors="coerce")
        med = df[c].median()
        df[c] = df[c].fillna(med if not math.isnan(med) else 0)

    HepatitisPatient = iris.cls("Sample.HepatitisPatient")
    inserted = 0
    for _, row in df.iterrows():
        p = HepatitisPatient._New()
        p.Age = int(row["age"])
        p.Sex = int(row["sex"])
        p.Steroid = int(row["steroid"])
        p.Antivirals = int(row["antivirals"])
        p.Fatigue = int(row["fatigue"])
        p.Malaise = int(row["malaise"])
        p.Anorexia = int(row["anorexia"])
        p.LiverBig = int(row["liverbig"])
        p.LiverFirm = int(row["liverfirm"])
        p.SpleenPalpable = int(row["spleenpalpable"])
        p.Spiders = int(row["spiders"])
        p.Ascites = int(row["ascites"])
        p.Varices = int(row["varices"])
        p.Bilirubin = float(row["bilirubin"])
        p.AlkPhosphate = float(row["alkphosphate"])
        p.SGOT = float(row["sgot"])
        p.Albumin = float(row["albumin"])
        p.ProTime = float(row["protime"])
        p.Histology = int(row["histology"])
        p.PredictionStatus = "pending"
        sc = p._Save()
        if iris.cls("%SYSTEM.Status").IsOK(sc):
            inserted += 1
    return inserted
}

}
