@isTest
global class AM_AssetService_UpdateMinMaxValueMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();

        if (
            request.getMethod() == 'PATCH' &&
            (request.getEndpoint().contains('/valuesTimeSeries/1000/min') ||
            request.getEndpoint().contains('/valuesTimeSeries/1001/min') ||
            request.getEndpoint().contains('/valuesTimeSeries/1002/min') ||
            request.getEndpoint().contains('/valuesTimeSeries/1000/max') ||
            request.getEndpoint().contains('/valuesTimeSeries/1001/max') ||
            request.getEndpoint().contains('/valuesTimeSeries/1002/max'))
        ) {
            try {
                Double.valueOf(request.getBody());
            } catch (Exception e) {
                response.setStatusCode(400);
            }

            response.setStatusCode(204);
        } else {
            response.setStatusCode(404);
        }

        return response;
    }
}