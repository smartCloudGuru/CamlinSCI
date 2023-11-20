@isTest
global class AM_AssetService_GetSignalsTSMock implements HttpCalloutMock {
    public static final String SIGNALS_TIME_SERIES =
        '[' +
        '{' +
        '"streamId": 100,' +
        '"assetId": "CBF@SUGAR;' +
        SCI_CommonUtilsMocks.COMPANY_ID +
        '",' +
        '"name": "ProfileP3Data",' +
        '"type": "P3",' +
        '"properties": {' +
        '"maxMU": 32768' +
        '}' +
        '}' +
        ']';

    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        if (
            request.getEndpoint()
                .contains(
                    EncodingUtil.urlEncode('CBF@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID, 'UTF-8') +
                    '/signalsTimeSeries'
                ) || request.getEndpoint().contains('/signalsTimeSeries/100')
        ) {
            response.setStatusCode(200);
            response.setBody(SIGNALS_TIME_SERIES);
        } else {
            response.setStatusCode(404);
        }

        return response;
    }
}