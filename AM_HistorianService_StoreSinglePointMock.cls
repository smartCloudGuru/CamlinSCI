@isTest
global class AM_HistorianService_StoreSinglePointMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();

        if (request.getEndpoint().contains('storeSinglePointValues') && !request.getBody().contains('"99999":')) {
            response.setStatusCode(204);
        } else if (request.getEndpoint().contains('storeSinglePointValues') && request.getBody().contains('"99999":')) {
            response.setStatusCode(403);
        } else {
            response.setStatusCode(404);
        }

        return response;
    }
}