# Salesforce Service Cloud + Agentforce ticketing project

## salesforce-dx/
- `CreateCaseAction`, `GetCaseStatusAction`, `EscalateCaseAction`: invocable Apex, one per class (an Apex rule), usable as Agentforce actions.
- `CaseTrigger` + `CaseTriggerHandler`: derives `Customer_Tier__c` from Account revenue and sets Priority from tier x sentiment (bulk-safe).
- Six custom fields on Case, LWC `aiCaseInsights`, permission set `Agentforce_Support_Agent`, and tests.

Deploy:
    sf org login web --alias support-org --set-default
    sf project deploy start
    sf apex run test --class-names AgentforceCaseActionsTest CaseTriggerHandlerTest --code-coverage --result-format human
    sf org assign permset --name Agentforce_Support_Agent

Not included (create in the org): the Agent, Topics and Actions in Agent Builder, a Prompt Builder template, queues and assignment rules. Add the LWC to the Case record page in Lightning App Builder.
Escalated status must exist in the Case Status picklist.

## web-app/
Mock simulator, not the real Atlas engine: `pip install -r requirements.txt && python app.py`, then open http://localhost:8000.
