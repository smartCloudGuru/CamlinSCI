@isTest
global class AM_AssetService_GetValuesTSMock implements HttpCalloutMock {
    public static final String VALUES_TIME_SERIES =
        '[' +
        '{' +
        '"streamId": 1000,' +
        '"assetId": "TST002-000054@SUGAR;' +
        SCI_CommonUtilsMocks.COMPANY_ID +
        '",' +
        '"name": "MainTank/Offline/DGA/Measured/AGC/H2",' +
        '"type": "Number",' +
        '"properties": {}' +
        '},' +
        '{' +
        '"streamId": 1001,' +
        '"assetId": "TST002-000054@SUGAR;' +
        SCI_CommonUtilsMocks.COMPANY_ID +
        '",' +
        '"name": "MainTank/Offline/DGA/Measured/AGC/CH4",' +
        '"type": "Number",' +
        '"properties": {}' +
        '},' +
        '{' +
        '"streamId": 1002,' +
        '"assetId": "TST002-000054@SUGAR;' +
        SCI_CommonUtilsMocks.COMPANY_ID +
        '",' +
        '"name": "MainTank/Offline/DGA/Measured/AGC/C2H2",' +
        '"type": "Number",' +
        '"properties": {}' +
        '}' +
        ']';

    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        if (
            request.getEndpoint()
                .contains(
                    '/assets/' +
                    EncodingUtil.urlEncode('TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID, 'UTF-8') +
                    '/valuesTimeSeries'
                )
        ) {
            response.setStatusCode(200);
            response.setBody(VALUES_TIME_SERIES);
        } else {
            response.setStatusCode(404);
        }

        return response;
    }
}