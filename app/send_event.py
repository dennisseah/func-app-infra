from azure.eventhub import EventData, EventHubProducerClient
from azure.identity import DefaultAzureCredential

p = EventHubProducerClient(
    fully_qualified_namespace="denz-infrafly-eventhub-ns.servicebus.windows.net",
    eventhub_name="denz-infrafly-eventhub",
    credential=DefaultAzureCredential(),
)

with p:
    b = p.create_batch()
    b.add(EventData('{"test": "hello"}'))
    p.send_batch(b)
    print("Event sent.")


#  az role assignment create \
#    --assignee $(az ad signed-in-user show --query id -o tsv) \
#    --role "Azure Event Hubs Data Sender" \
#    --scope $(az eventhubs namespace show \
#    --resource-group denz_infrafly_rg \
#    --name denz-infrafly-eventhub-ns --query id -o tsv)


# az monitor app-insights query \
#   --app denz-appinsights-infrafly-func-app \
#   --resource-group denz_infrafly_rg \
#   --analytics-query \
#   "traces | where timestamp > ago(2m) and message contains 'Event Hub trigger fired' \
#   | project timestamp, message, operation_Id"
