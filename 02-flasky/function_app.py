import azure.functions as func  # Import Azure Functions library for creating function apps
from azure.functions import HttpRequest, HttpResponse  # Import HttpRequest and HttpResponse for handling HTTP requests and responses
from azure.cosmos import CosmosClient, exceptions  # Import Cosmos DB client and exceptions for database operations
from azure.identity import DefaultAzureCredential  # Import DefaultAzureCredential for authentication with Azure resources
from azure.identity import ClientSecretCredential  # Import ClientSecretCredential for authentication (alternative method)

import os  # Import OS library to interact with environment variables
import logging  # Import logging library for capturing logs
import socket  # Import socket library to retrieve hostname and IP information
import json  # Import JSON library for handling JSON data

# Azure Cosmos DB Configuration
COSMOS_ENDPOINT = os.environ.get("COSMOS_ENDPOINT", "")
# Cosmos DB endpoint, retrieved from environment variables or defaults to a predefined URL
DATABASE_NAME = os.environ.get("COSMOS_DATABASE_NAME", "CandidateDatabase")  # Name of the Cosmos DB database
CONTAINER_NAME = os.environ.get("COSMOS_CONTAINER_NAME", "Candidates")  # Name of the Cosmos DB container

# Initialize Azure credentials for secure access to Azure resources
credential = DefaultAzureCredential()

# Instantiate the Cosmos DB client using the endpoint and credentials
cosmos_client = CosmosClient(COSMOS_ENDPOINT, credential=credential)

# Access the specified database from the Cosmos DB account
database = cosmos_client.get_database_client(DATABASE_NAME)

# Access the specified container within the database
container = database.get_container_client(CONTAINER_NAME)

# Get hostname and IP address of the container running this Function App
hostname = socket.gethostname()  # Retrieve the hostname of the current instance

# Create an Azure FunctionApp instance with anonymous HTTP access level
app = func.FunctionApp(http_auth_level=func.AuthLevel.ANONYMOUS)

# Route to retrieve a candidate by name (GET method)
@app.route(route="candidate/{name}", methods=["GET"])
def candidate_get(req: HttpRequest) -> HttpResponse:
    # Extract the candidate name from the URL parameters
    name = req.route_params.get("name")

    try:
        # Query the Cosmos DB container to find the candidate with the given name
        query = "SELECT c.CandidateName FROM c WHERE c.CandidateName = @name"
        parameters = [{"name": "@name", "value": name}]
        response = list(container.query_items(query=query, parameters=parameters, enable_cross_partition_query=True))

        # If no response is returned, raise an exception
        if not response:
            raise Exception

        # Return the candidate's data as a JSON response with a 200 status code
        return HttpResponse(json.dumps(response), status_code=200)
    except Exception as e:
        # Handle any errors, returning a 404 status code and an error message
        return HttpResponse(f"ERROR: {name} NOT FOUND", status_code=404)

# Route to add or update a candidate by name (POST method)
@app.route(route="candidate/{name}", methods=["POST"])
def candidate_post(req: HttpRequest) -> HttpResponse:
    # Extract the candidate name from the URL parameters
    name = req.route_params.get("name")

    try:
        # Create or update a candidate record in the Cosmos DB container
        item = {"id": name, "CandidateName": name}
        container.upsert_item(item)

        # Prepare and return a JSON response with the candidate's data
        data = {"CandidateName": name}
        return HttpResponse(json.dumps(data), status_code=200)
    except exceptions.CosmosHttpResponseError as ex:
        # Handle Cosmos DB-specific errors, returning a 500 status code and the error message
        return HttpResponse(f"Error: {ex}", status_code=500)

# Route to retrieve all candidates (GET method)
@app.route(route="candidates", methods=["GET"])
def candidates(req: HttpRequest) -> HttpResponse:
    try:
        # Query the Cosmos DB container to retrieve all candidates
        query = "SELECT c.CandidateName FROM c"
        response = list(container.query_items(query=query, enable_cross_partition_query=True))

        # Return the list of candidates as a JSON response with a 200 status code
        return HttpResponse(json.dumps(response), status_code=200)
    except Exception as e:
        # Handle any errors, returning a 404 status code and the error message
        return HttpResponse(f"Error: {e}", status_code=404)

# Route for health check (GET method)
@app.route(route="gtg", methods=["GET"])
def gtg(req: HttpRequest) -> HttpResponse:
    try:
        # Check for 'details' parameter in the request
        details = req.params.get('details')

        if details:
            # If 'details' parameter exists, return instance connectivity and hostname details
            data = {"connected": "true", "hostname": hostname}
            return HttpResponse(json.dumps(data), status_code=200)
        else:
            # If no 'details' parameter, return a simple success response
            return HttpResponse("", status_code=200)
    except Exception as e:
        # Handle any errors, returning a 500 status code and the error message
        return HttpResponse(f"Error: {e}", status_code=500)
