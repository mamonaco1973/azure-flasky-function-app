import azure.functions as func
from azure.functions import HttpRequest, HttpResponse

import logging

# Create a FunctionApp instance with Anonymous access by default
app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

@app.route(route="candidate/{name}", methods=["GET"])
def candidate_get(req: HttpRequest) -> HttpResponse:
    name = req.route_params.get("name")
    message = f"Name: {name}"
    return HttpResponse(message)


@app.route(route="candidate/{name}", methods=["POST"])
def candidate_post(req: HttpRequest) -> HttpResponse:
    name = req.route_params.get("name")
    message = f"Name: {name}"
    return HttpResponse(message)

@app.route(route="candidates", methods=["GET"])
def candidates(req: HttpRequest) -> HttpResponse:
    message = f"Get all candidates"
    return HttpResponse(message)

@app.route(route="gtg", methods=["GET"])
def gtg(req: HttpRequest) -> HttpResponse:
    message = f"health check"
    return HttpResponse(message)