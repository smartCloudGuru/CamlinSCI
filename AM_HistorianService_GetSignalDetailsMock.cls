@isTest
global class AM_HistorianService_GetSignalDetailsMock implements HttpCalloutMock {
    public static final String SIGNAL =
        '{' +
        '"streamId":100,' +
        '"signalId":3,' +
        '"time":1302084312000,' +
        '"sampleRate":12800,' +
        '"samplesNumber":12800,' +
        '"properties":{' +
        '"recordNum": 388,' +
        '"startSampleIndex": 1921,' +
        '"endSampleIndex": 3333,' +
        '"L1": {' +
        '"productNum": 100,' +
        '"serialNum": 125' +
        '},' +
        '"analysis": {' +
        '"Ltch": 24.297,' +
        '"Bffr": 28.516,' +
        '"Acon": 54.922,' +
        '"End": 105.078' +
        '}' +
        '}' +
        '}';

    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        if (request.getEndpoint().contains('signals/3')) {
            response.setStatusCode(200);
            response.setBody(SIGNAL);
        } else if (request.getEndpoint().contains('signals/99999')) {
            response.setStatusCode(403);
        } else {
            response.setStatusCode(404);
        }

        return response;
    }
}