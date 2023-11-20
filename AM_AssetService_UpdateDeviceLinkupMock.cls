@isTest
global class AM_AssetService_UpdateDeviceLinkupMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();

        String assetId = 'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID;
        if (
            request.getMethod() == 'POST' &&
            request.getEndpoint().contains('/assets/' + EncodingUtil.urlEncode(assetId, 'UTF-8')) &&
            request.getEndpoint().contains('?deviceId=') &&
            (request.getEndpoint().contains('/setDeviceLinkupActivationTime') ||
            request.getEndpoint().contains('/setDeviceLinkupDeactivationTime'))
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