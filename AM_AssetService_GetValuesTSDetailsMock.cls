@isTest
global class AM_AssetService_GetValuesTSDetailsMock implements HttpCalloutMock {
    public static final String VALUES_TIME_SERIES_1000 =
        '{' +
        '"streamId": 1000,' +
        '"assetId": "TST002-000054@SUGAR;' +
        SCI_CommonUtilsMocks.COMPANY_ID +
        '",' +
        '"name": "DGA/H2",' +
        '"type": "Number",' +
        '"properties": {}' +
        '}';
    public static final String VALUES_TIME_SERIES_1001 =
        '{' +
        '"streamId": 1001,' +
        '"assetId": "TST002-000054@SUGAR;' +
        SCI_CommonUtilsMocks.COMPANY_ID +
        '",' +
        '"name": "MainTank/Offline/DGA/Measured/AGC/CH4",' +
        '"type": "Number",' +
        '"properties": {}' +
        '}';
    public static final String VALUES_TIME_SERIES_1002 =
        '{' +
        '"streamId": 1002,' +
        '"assetId": "TST002-000054@SUGAR;' +
        SCI_CommonUtilsMocks.COMPANY_ID +
        '",' +
        '"name": "MainTank/Offline/DGA/Measured/AGC/C2H2",' +
        '"type": "String",' +
        '"properties": {}' +
        '}';

    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        if (request.getEndpoint().endsWith('/valuesTimeSeries/1000')) {
            response.setStatusCode(200);
            response.setBody(VALUES_TIME_SERIES_1000);
        } else if (request.getEndpoint().endsWith('/valuesTimeSeries/1001')) {
            response.setStatusCode(200);
            response.setBody(VALUES_TIME_SERIES_1001);
        } else if (request.getEndpoint().endsWith('/valuesTimeSeries/1002')) {
            response.setStatusCode(200);
            response.setBody(VALUES_TIME_SERIES_1002);
        } else {
            response.setStatusCode(404);
        }

        return response;
    }
}