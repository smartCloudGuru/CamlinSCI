@isTest
global class AM_ImportService_ValidateRecFileMock implements HttpCalloutMock {
    public static final String VALIDATION_MODEL =
        '{' +
        '"overallStatus": "WARNING",' +
        '"comment": "P3_VALID_ADD_DATA",' +
        '"substationId": "BOLOGNA",' +
        '"substationIdStatus": "VALID",' +
        '"proposedSubstationIdValues": [' +
        '"BOLOGNA",' +
        '"LISBURN",' +
        '"PARMA"' +
        '],' +
        '"circuitBreakerId": "Luca",' +
        '"circuitBreakerIdStatus": "VALID",' +
        '"circuitBreakerType": "Full Stack Developer",' +
        '"circuitBreakerTypeStatus": "VALID",' +
        '"circuitId": "Windows 10",' +
        '"circuitIdStatus": "VALID",' +
        '"timeZone": "Europe/Rome",' +
        '"timeZoneStatus": "VALID",' +
        '"timestamp": 1616112000000,' +
        '"timestampStatus": "VALID",' +
        '"circuitBreakerTypeValueByAssetId" : {' +
        '"Luca@Bologna": "Full Stack Developer",' +
        '"Giuseppe@Bologna": "Java Engineer",' +
        '"Nigel@Lisburn": "Project Manager",' +
        '"Raja@Lisburn": "Full Stack Developer",' +
        '"Federico@Parma": "Data Scientist",' +
        '"Vincenzo@Parma": "Data Scientist",' +
        '"Luca@Parma": "Data Scientist"' +
        '},' +
        '"circuitIdValueByAssetId": {' +
        '"Luca@Bologna": "Windows 10",' +
        '"Giuseppe@Bologna": "Ubuntu",' +
        '"Nigel@Lisburn": "Windows 10",' +
        '"Raja@Lisburn": "CentOS",' +
        '"Federico@Parma": "Ubuntu",' +
        '"Vincenzo@Parma": "Ubuntu",' +
        '"Luca@Parma": "Ubuntu"' +
        '},' +
        '"timeZoneValueByAssetId": {' +
        '"Luca@Bologna": "Europe/Rome",' +
        '"Giuseppe@Bologna": "Europe/Rome",' +
        '"Nigel@Lisburn": "UTC",' +
        '"Raja@Lisburn": "UTC",' +
        '"Federico@Parma": "US/Hawaii",' +
        '"Vincenzo@Parma": "US/Hawaii",' +
        '"Luca@Parma": "US/Hawaii"' +
        '},' +
        '"circuitBreakerIdValuesBySubstation": {' +
        '"Bologna": [' +
        '"Luca",' +
        '"Giuseppe"' +
        '],' +
        '"Lisburn": [' +
        '"Nigel",' +
        '"Raja"' +
        '],' +
        '"Parma": [' +
        '"Federico",' +
        '"Vincenzo",' +
        '"Luca"' +
        ']' +
        '},' +
        '"circuitBreakerTypeValuesBySubstation": {' +
        '"Bologna": [' +
        '"Full Stack Developer",' +
        '"Java Engineer"' +
        '],' +
        '"Lisburn": [' +
        '"Project Manager",' +
        '"Full Stack Developer"' +
        '],' +
        '"Parma": [' +
        '"Data Scientist"' +
        ']' +
        '},' +
        '"circuitIdValuesBySubstation": {' +
        '"Bologna": [' +
        '"Windows 10",' +
        '"Ubuntu"' +
        '],' +
        '"Lisburn": [' +
        '"Windows 10",' +
        '"CentOS"' +
        '],' +
        '"Parma": [' +
        '"Ubuntu"' +
        ']' +
        '}' +
        '}';

    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        if (request.getEndpoint().contains('&substationId=')) {
            response.setStatusCode(200);
            response.setBody(VALIDATION_MODEL);
        } else {
            response.setStatusCode(500);
        }

        return response;
    }
}