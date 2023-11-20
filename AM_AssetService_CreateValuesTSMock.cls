@isTest
global class AM_AssetService_CreateValuesTSMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();

        String assetId = 'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID;
        if (
            request.getEndpoint().contains('/assets/' + EncodingUtil.urlEncode(assetId, 'UTF-8') + '/valuesTimeSeries')
        ) {
            Map<String, Object> body = (Map<String, Object>) JSON.deserializeUntyped(request.getBody());

            if (body.get('assetId') == assetId && body.get('type') == 'Number') {
                response.setStatusCode(200);
                response.setBody('42');
            } else {
                response.setStatusCode(400);
            }
        } else {
            response.setStatusCode(400);
        }

        return response;
    }
}