import json
import logging
import os
import uuid

import azure.functions as func
from azure.cosmos import CosmosClient
from azure.identity import DefaultAzureCredential

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

# Singleton Cosmos DB client (reused across invocations).
_credential = DefaultAzureCredential()
_cosmos_client = CosmosClient(os.environ["COSMOSDB_ENDPOINT"], credential=_credential)
_status_container = _cosmos_client.get_database_client(
    "infrafly-db"
).get_container_client("status")


@app.route(route="health", methods=["GET"])
def health(req: func.HttpRequest) -> func.HttpResponse:
    return func.HttpResponse("OK", status_code=200)


@app.event_hub_message_trigger(
    arg_name="event",
    event_hub_name="%EVENT_HUB_NAME%",
    connection="EventHubConnection",
)
def eventhub_trigger(event: func.EventHubEvent):
    body = event.get_body().decode("utf-8")
    logging.info("Event Hub trigger fired. Event: %s", body)

    content = json.loads(body)
    content["status"] = "processing"
    item = {"id": str(uuid.uuid4()), "content": content}
    _status_container.upsert_item(item)
    logging.info("Written to Cosmos DB status container. id=%s", item["id"])
