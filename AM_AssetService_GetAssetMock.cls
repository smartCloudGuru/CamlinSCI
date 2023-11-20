@isTest
global class AM_AssetService_GetAssetMock implements HttpCalloutMock {
    public static final String TIME_ZONE = 'Europe/Rome';
    public static final String ASSET_TR =
        '{' +
        '"assetId": "TST002-000054@SUGAR;' +
        SCI_CommonUtilsMocks.COMPANY_ID +
        '",' +
        '"name": "TR1",' +
        '"category": "Transformer",' +
        '"type": "Mascetti",' +
        '"startTime": 1302082806000,' +
        '"endTime": 1302084312000,' +
        '"properties": {' +
        '"path": "",' +
        '"substationId": "SUGAR",' +
        '"timeZone": "' +
        TIME_ZONE +
        '"' +
        '}' +
        '}';
    public static final String ASSET_CB =
        '{' +
        '"assetId": "CBF@SUGAR;' +
        SCI_CommonUtilsMocks.COMPANY_ID +
        '",' +
        '"name": "CBF",' +
        '"category": "CircuitBreaker",' +
        '"type": "Reyrolle",' +
        '"startTime": 1302082806000,' +
        '"endTime": 1302084312000,' +
        '"properties": {' +
        '"path": "",' +
        '"substationId": "SUGAR",' +
        '"timeZone": "' +
        TIME_ZONE +
        '"' +
        '}' +
        '}';

    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        if (
            request.getEndpoint()
                .contains(
                    '/assets/' +
                    EncodingUtil.urlEncode('TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID, 'UTF-8')
                )
        ) {
            response.setStatusCode(200);
            response.setBody(ASSET_TR);
        } else if (
            request.getEndpoint()
                .contains('/assets/' + EncodingUtil.urlEncode('CBF@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID, 'UTF-8'))
        ) {
            response.setStatusCode(200);
            response.setBody(ASSET_CB);
        } else {
            response.setStatusCode(404);
        }

        return response;
    }
}