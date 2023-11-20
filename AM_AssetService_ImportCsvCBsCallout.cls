@isTest
global class AM_AssetService_ImportCsvCBsCallout implements HttpCalloutMock {
    Integer statusCode;

    public AM_AssetService_ImportCsvCBsCallout(Integer statusCode) {
        this.statusCode = statusCode;
    }

    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();

        if (statusCode == 200) {
            String bodyResponse = '{"succeeded": [{"row": 1, "assetId": "assetId1", "substationName": "SUB1", "breakerOrgId": "BRKR_MODEL_1"}, {"row": 2, "assetId": "assetId2", "substationName": "SUB2", "breakerOrgId": "BRKR_MODEL_2"}], "failed": [{"row": 2, "reasons": ["reason 1", "reason 2"]}, {"row": 3, "reasons": ["reason 11", "reason 22"]}]}';
            response.setStatusCode(200);
            response.setBody(bodyResponse);
        }
        if (statusCode == 400) {
            String bodyResponse = '{"failed": [{"row": 2, "reasons": ["reason 1", "reason 2"]}, {"row": 3, "reasons": ["reason 11", "reason 22"]}]}';
            response.setStatusCode(400);
            response.setBody(bodyResponse);
        }
        if (statusCode == 500) {
            response.setStatusCode(500);
        }

        return response;
    }
}