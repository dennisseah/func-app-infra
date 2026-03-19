import logging

import azure.functions as func

app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)


@app.route(route="health", methods=["GET"])
def health(req: func.HttpRequest) -> func.HttpResponse:
    return func.HttpResponse("OK", status_code=200)


@app.event_hub_message_trigger(
    arg_name="event",
    event_hub_name="%EVENT_HUB_NAME%",
    connection="EventHubConnection",
)
def eventhub_trigger(event: func.EventHubEvent):
    logging.info("Event Hub trigger fired. Event: %s", event.get_body().decode("utf-8"))
