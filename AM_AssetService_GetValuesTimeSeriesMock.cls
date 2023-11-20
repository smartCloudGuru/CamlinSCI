@isTest
global class AM_AssetService_GetValuesTimeSeriesMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();

        if (request.getBody().contains('1000')) {
            String bodyResponse =
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

                response.setStatusCode(200);
                response.setBody(bodyResponse);
        } else {
            response.setStatusCode(500);
        }

        return response;
    }
}