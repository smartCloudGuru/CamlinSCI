@isTest
global class AM_AssetService_MergeAssetMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();

        String assetId = 'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID;
        if (request.getEndpoint().contains('assets/' + EncodingUtil.urlEncode(assetId, 'UTF-8'))) {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(request.getBody());

            if (
                request.getMethod() == 'PATCH' &&
                body.get('assetId') == assetId &&
                request.getEndpoint().endsWith('/properties')
            ) {
                response.setStatusCode(204);
            } else {
                response.setStatusCode(400);
            }
        } else {
            response.setStatusCode(400);
        }

        return response;
    }
}