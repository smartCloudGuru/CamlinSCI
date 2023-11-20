@isTest
global class AM_HistorianService_GetValuesMock implements HttpCalloutMock {
    public static final String VALUES = '[{"time":1650924800000,"value":1653923343000,"quality":128},{"time":1651424800000,"value":1653923343000},{"time":1651881600000,"value":1653923343000}]';

    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        if (request.getEndpoint().contains('getValues') && !request.getBody().contains('99999')) {
            response.setStatusCode(200);
            response.setBody(VALUES);
        } else if (request.getBody().contains('99999')) {
            response.setStatusCode(403);
        } else {
            response.setStatusCode(404);
        }

        return response;
    }
}