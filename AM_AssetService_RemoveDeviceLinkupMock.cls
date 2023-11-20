@isTest
global class AM_AssetService_RemoveDeviceLinkupMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();

        String assetId = 'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID;
        if (
            request.getEndpoint().contains('assets/' + EncodingUtil.urlEncode(assetId, 'UTF-8') + '/removeDeviceLinkup')
        ) {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(request.getBody());

            if (request.getMethod() == 'POST' && body.get('assetId') == assetId) {
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