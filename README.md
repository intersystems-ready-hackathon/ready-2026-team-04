# TEAM 04 - [ Clinical Trial Effectiveness Assessment ] 

- Anthony (collaboration, design, and build)
- Himanshu (collaboration)
- Jacob (collaboration, design, and build)
- MikeM (collaboration, design)
- MikeY (collaboration, scribe)

## Project Summary 

Agent to look at clinical-trial data and assess impact by patient.  Output will be based on predefined categories.

Leverage "dataset-health" provided by InterSystem.

Focus on Hepititis B - mortality risk - generate a ranking of patient status/progress using clinical trial treatment plan

Mortailty Risk - Impact Assessment Scores:
- low - no change in treatment plan
- medium - modification of treatment plan?
- high - focus on quality of life

Stretch Goals:
- Agent Feedback loop / Recommendations


## Technical Details

- Data
- Built model based on Hepititis B
- Built matrix for agent to use
- added class file to help agent get the data out
- python script to run the data through the model
Chat-based Agent (leveraged Claude to create Agent template class)
- Extended %AI.Toolset
- Create an MCP Service class (extended %AI.MCP.Service)

## Setup Instructions [Optional]

[ If you have time, please add details on how someone else can start using your
project here ]

```
set $NAMESPACE = "IRISAPP"
zpm "install dataset-health"
```

## Publicly accessible statement

**Delete as appropriate**: 
- We are happy for our project to be publicly visable after the event (you will remain repo admins) 
- We would like our project to be made private at the end of the event


# Template Instructions (feel free to delete)


This repo provides a template to kickstart development with AI Hub. 

## Contents

- **./skills** - agent skills with information on using AI hub for AI agents. Move these to a suitable location for your preferred AI coding agent. 
- **./src/Sample** - Basic sample classes for tools, toolsets, agents and MCP servers. These are installed with zpm when the container is build.  
- **./src/Python** - An example stdio MCP server defined in Python and used in the IRIS Toolsets 
- **Datasets.md** - Notes on some datasets or tools to import datasets available on Open Exchange for easy install 

## Using the template

### Download AI Hub Container


1. Download an AI Hub container from the [Early Access Program Portal](https://evaluation.intersystems.com/Eval/early-access/AIHub). The docker-containers end with `docker.tar.gz`, ensure you choose the version suitable for your operating system (arm64 for macOS).

OR 

1. Copy AI Hub Container from your Flash Drive

2. Load the image with: 

    ```bash
    docker load -i /path/to/irishealth-community-2026.2.0AI.158.0-docker.tar.gz
    ```

    Once it's complete you should see `Loaded image: docker.iscinternal.com/docker-intersystems/intersystems/iris-community:2026.2.0AI.158.0` (if not you can use `docker images` to find the image name). 

3. Change the Image name in the [Dockerfile](./Dockerfile) to match your version and operating system (image name printed above).



### Build Template Repo

4. Clone this repo: 

```bash
git clone https://github.com/intersystems-ready-hackathon/ready-2026-team-04.git
cd ready-2026-team-04
```

5. (Optional) Add an OPENAI_API_KEY to a file called .env in this repo. You can see an example in .env.example.

6. Build the container with: 

```bash
docker-compose up -d --build 
```

## Using IRIS AI Hub Container

### Accessing IRIS 

You can find the Management Portal at http://localhost:52773/csp/sys/UtilHome.csp.

Login with: 
    - SuperUser / SYS

You can access the IRIS Terminal with:

```objectscript
docker-compose exec -it iris iris session iris
```

or the bash terminal with:

```bash
docker-compose exec -it iris iris session iris
```

### Testing Sample agent 

There is a basic agent in src/Sample.Agent, a simple way to use it from objectscript is to run the following (note this does require an OPENAI_API_KEY to be added to .env before running th container). 

```objectscript
set $NAMESPACE= "IRISAPP"
Set agent = ##class(CTEA.Agent).%New()
Set sc = agent.%Init()
write:sc'=1 $SYSTEM.Status.GetErrorText(sc), !
Set session = agent.CreateSession()
Set request = "Using the CountPatients tool, how many total patients do we have?"
Set response = agent.Chat(session, request)
write response.Content
```

For debugging, please use this command:
```Objectscript
do $SYSTEM.AI.Shell("openai",$System.Util.GetEnviron("OPENAI_API_KEY"),,"CTEA.ToolSet")
```
For help use `/help`

### Test MCP Server

The build process installs an MCP server web application at http://localhost:52773/mcp/sample. You can check this MCP server is running by going to http://localhost:52773/mcp/sample/v1/services. 

For the MCP Server to be usable, there is an additional step of starting this via a Rust binary which connects to IRIS through the web gateway protocol. The Binary is installed in `/usr/irissys/bin` (should already be in PATH).  

A sample configuration is shown in [config.toml](./config.toml), which serves a remote HTTP server on port 8080 (which is exposed by the docker-compose file). 

To start the transport, open a bash terminal within the container: 

```bash
docker-compose exec -it iris bash 
```

Then start the `iris-mcp-server`

```bash 
iris-mcp-server -c config.toml run 
```

You can now connect the MCP server to your MCP Client of choice (e.g. coding agents like claude code) using the address: http://localhost:8080/mcp/sample. 

An example python MCP client is shown in test_mcp_connection.py, which uses Langchain's MCP adapters module. To try this, run: 

```bash
pip install langchain-mcp-adapters
python test_mcp.py
```


# DEMO

1. Create .env file with OPENAI_API_KEY

2. Run container

```sh
docker compose up -d
```

3. Load example health data

```sh
docker-compose exec -it iris iris session iris
```
```ObjectScript
set $NAMESPACE = "IRISAPP"
zpm "install dataset-health"
```

4. Run the demo:

```ObjectScript
do $SYSTEM.AI.Shell("openai",$System.Util.GetEnviron("OPENAI_API_KEY"),,"CTEA.ToolSet")
```

Example Interaction:

```
You> How many patients lived?
┃ Authorization Request
┃ Tool:      CountPatients
┃ Arguments: {}
┃     Allow execution? (Y/n/A) Y

┃ OK CountPatients → {"columns":[{"name":"patient_count","type":"INTEGER"}],"rows":[{"patient_count":"155"}],"row_coun... [1ms]

AI> There are 155 patients in total.  
If you’d like, I can break this down further (e.g., by sex, age range, or risk factors) using the outcomes data.

Elapsed: 8.32s

You> Yes, please break this data down further
┃ Authorization Request
┃ Tool:      GetOutcomeStats
┃ Arguments: {}
┃     Allow execution? (Y/n/A) Y

┃ OK GetOutcomeStats → {"columns":[{"name":"outcome","type":"VARCHAR"},{"name":"patient_count","type":"INTEGER"},{"name"... [60ms]

┃ Authorization Request
┃ Tool:      GetRiskFactorCounts
┃ Arguments: {}
┃     Allow execution? (Y/n/A) Y

┃ OK GetRiskFactorCounts → {"columns":[{"name":"outcome","type":"VARCHAR"},{"name":"total_patients","type":"INTEGER"},{"name... [46ms]

AI> Here’s a breakdown of the outcomes and some key characteristics.
Outcome counts
Out of 155 total patients:
- Lived: 123  
- Died: 32  
Average values by outcome
Patients who lived (123)
- Average age: 39.8 years  
- Average bilirubin: 1.15  
- Average albumin: 3.98  
- Average SGOT: 82.4  
- Average alkaline phosphatase: 101.3  
- Average prothrombin time: 66.6  
Patients who died (32)
- Average age: 46.6 years  
- Average bilirubin: 2.54  
- Average albumin: 3.15  
- Average SGOT: 99.8  
- Average alkaline phosphatase: 122.4  
- Average prothrombin time: 43.5  
So, on average, the patients who died were older and had more abnormal lab values (higher bilirubin, higher enzymes, 
lower albumin, shorter prothrombin time).
Risk factor / symptom counts
For the categorical risk factors and symptoms we have here (ascites, varices, spiders, liver big, liver firm, spleen 
palpable, fatigue, anorexia, malaise), the stored counts are:
- All listed risk factors/symptoms show count 0 for both:
  - Outcome = LIVE (123 patients)
  - Outcome = DIE (32 patients)
This likely means these particular fields were not recorded/populated in this dataset, rather than truly being absent
clinically.
―――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――――
If you tell me what you’re most interested in (e.g., age-specific survival, lab value thresholds, or filtering by 
sex), I can run more targeted searches over this patient set.

Elapsed: 11.41s
```