# Volunteering Open Data Infrastructure

This repository holds code for modeling and accessing open data for volunteering.


## Data Model

1. [Volunteering Data Model](https://model.volunteeringdata.io/)
1. [Data Model Visualisation](https://service.tib.eu/webvowl/#opts=doc=0;filter_sco=true;mode_compact=true;iri=https://service.tib.eu/webvowl/#iri=https://api.volunteeringdata.io/schema.ttl)


## API

1. [OpenAPI description document](https://api.volunteeringdata.io/openapi.json)
1. [Swagger UI](https://api.volunteeringdata.io/swagger)
1. [JSON-LD context document](https://api.volunteeringdata.io/context/v1)
1. [SPARQL UI](https://api.volunteeringdata.io/sparql)


## How To

### Set up and understand the infrastructure

The infrastructure consists of a Container Registry and two app services: 1 for the API and 1 for the database.

Some infrastructure as code (IaC) in the form of ARM templates is here to help out.

See the [infrastructure README](`./infrastructure/README.md`) for details.


### Deploy the API and Data

Both Data and API are continuously deployed via [GitHub actions](./github/workflows).


### Transform Data

#### Run automated data transformation for DoIt Data sample

```zsh
dotnet run ./data/doit/activities.json ./data/doit/data.ttl --project ./transform/DoIt/
```


### Publish Data

You can simply build the data container ([fuseki](https://jena.apache.org/documentation/fuseki2/)) using [this Dockerfile](./Dockerfile) and publish it to a container registry of your choice.

A WebHook can automatically deploys the latest data container version available to an Azure App Service for example.

The data container is a readonly triplestore with a public sparql endpoint containing the latest data (including this repos' `.ttl` files).

#### Login

```zsh
source .env
az login
az acr login --name $INFRASTRUCTURE_CONTAINER_REGISTRY_NAME
```

#### Publishing the container

```zsh
docker build --tag $INFRASTRUCTURE_DATA_CONTAINER .
docker push $INFRASTRUCTURE_DATA_CONTAINER
```


### Run the Data Container Locally

```zsh
source .env
docker run --rm -p 3030:3030 $INFRASTRUCTURE_DATA_CONTAINER
```

SPARQL endpoint accessible at http://localhost:3030/sparql.

Example Query (URI encode the query and use it as parameter to http://localhost:3030/sparql?query=):
- Get all activities `CONSTRUCT { ?s <https://ns.volunteeringdata.io/activityTitle> ?o } WHERE { ?s <https://ns.volunteeringdata.io/activityTitle> ?o }`
- Get all statements `CONSTRUCT { ?s ?p ?o } WHERE { ?s ?p ?o }`
- Get the vocabulary `CONSTRUCT { ?s ?p ?o . } WHERE { ?s ?p ?o ; <http://www.w3.org/2000/01/rdf-schema#isDefinedBy> <https://id.volunteeringdata.io/schema> . }`


### Run the API Locally

#### Configuring User Secrets

Manage user secrets (right click Query.csproj > Manage User Secrets) and set the SparqlEndpointUri.

The `secrets.json` file should look like this:

```json
{
  "QueryService": {
    "SparqlEndpointUri": "https://sparql.volunteeringdata.io/sparql"
  }
}
```

#### Running the Project

```zsh
dotnet run --project Query
```

Go to the [swagger endpoint on localhost](http://localhost:5199/swagger).
Or go to the [SPARQL UI on localhost](http://localhost:5199/sparql).


## Configuring the MCP Server

See for example [Claude's Documentation](https://modelcontextprotocol.io/docs/develop/connect-local-servers#installing-the-filesystem-server)), and add the following local config:

```json
{
    "mcpServers": {
        "volunteering": {
            "args": [
                "mcp-remote",
                "https://api.volunteeringdata.io/mcp"
            ],
            "command": "npx"
        }
    }
}
```


## Endpoints Examples

Organisations:
- https://api.volunteeringdata.io/organisation
- https://api.volunteeringdata.io/organisation_all
- https://api.volunteeringdata.io/organisation_count.html
- https://api.volunteeringdata.io/organisation_by_name?name=green~
- https://api.volunteeringdata.io/organisation_by_id?id=68764a5c8e328c6f50449046
- https://api.volunteeringdata.io/organisation_list.html
- https://api.volunteeringdata.io/organisation_by_location.html?lat=51.509&lon=-0.118&within=10
- https://api.volunteeringdata.io/organisation_search.html?query=technology

Activities:
- https://api.volunteeringdata.io/activity_count.html
- https://api.volunteeringdata.io/activity_by_name?name=green~
- https://api.volunteeringdata.io/activity_by_id?id=670d3d31919ca4dbd11aa03d
- https://api.volunteeringdata.io/activity_by_location.html?lat=51.509&lon=-0.118&within=10
- https://api.volunteeringdata.io/activity_search.html?query=technology

Taxonomy:
- https://api.volunteeringdata.io/cause
- https://api.volunteeringdata.io/requirement


# License

This work is [licensed under MIT](./LICENSE.md).

`SPDX-License-Identifier: MIT`


---------------------------------
---------------------------------

# TODO

Enable CORS:
- Test CORS is correctly configured for our purpose (MCP, API)

IO optimisation:
- JSON input
- CSV input
- Optimised RDF formats (TriG/TriX/BinaryRDF)

Validator service:
- Based on a SHACL document
- Give it a URI for the SHACL doc
- Give it a URI for the data

Data Portal endpoints:
- DCAT
- Croissant (TODO: Fix endpoint !important)
- DCAT-AP
- MLDCAT-AP

Infrastructure as Code:
- Create service principal for CD
- Export full arm template from Resource Group, or
- Improve modular ARM templates

Documentation:
- Serve LODE documentation
- Serve WebVOWL

Modeling:
- Improve model
- Map ontologies (alignment)

Search:
- Improve geo location search (GeoSPARQL Query not supported)
- Improve Lucene indexing

Endpoints modeling:
- Improve response formats of endpoints
- Improve OpenAPI description
