@isTest
global class AM_AssetService_UpdateStartEndTimeMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();

        String assetId = 'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID;
        if (
            request.getMethod() == 'PATCH' &&
            request.getEndpoint().contains('/assets/' + EncodingUtil.urlEncode(assetId, 'UTF-8')) &&
            (request.getEndpoint().endsWith('/startTime') || request.getEndpoint().endsWith('/endTime'))
        ) {
            Long timestamp = Long.valueOf(request.getBody());

            if (timestamp != null && timestamp > 0L) {
                response.setStatusCode(204);
            } else {
                response.setStatusCode(400);
            }
        } else {
            response.setStatusCode(404);
        }

        return response;
    }
}