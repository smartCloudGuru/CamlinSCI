@isTest
global class AM_HistorianService_GetSinglePointMock implements HttpCalloutMock {
    public static final String SINGLE_POINT_VALUES = '{"1000":42.32,"1001":1650924800000,"1002":"Antani"}';

    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        if (request.getEndpoint().contains('getSinglePointValues') && !request.getBody().contains('99999')) {
            response.setStatusCode(200);
            response.setBody(SINGLE_POINT_VALUES);
        } else if (request.getBody().contains('99999')) {
            response.setStatusCode(403);
        } else {
            response.setStatusCode(404);
        }

        return response;
    }
}