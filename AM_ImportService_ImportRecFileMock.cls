@isTest
global class AM_ImportService_ImportRecFileMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        if (request.getEndpoint().contains('&circuitBreakerType=')) {
            response.setStatusCode(202);
            response.setBody('"1234567890"');
        } else {
            response.setStatusCode(500);
        }

        return response;
    }
}