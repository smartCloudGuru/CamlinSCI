@isTest
global class AM_HistorianService_GetSignalMock implements HttpCalloutMock {
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
        '},' +
        '"mlData": {' +
        '"dc_current_metrics": {' +
        '"key_point_time": {' +
        '"buffer": 28.516,' +
        '"acon": 54.922,' +
        '"end": 105.078' +
        '},' +
        '"metric": {' +
        '"buffer_delay": 0.8452643171806162,' +
        '"acon_delay": -6.445484581497794,' +
        '"plateau_current_fluctuations": 0.03294284021893581,' +
        '"plateau_current_value": 7.132000000000001,' +
        '"peak_current": 7.2369384765625' +
        '},' +
        '"status": {' +
        '"buffer_delay": 1,' +
        '"acon_delay": 1,' +
        '"plateau_current_fluctuations": 0,' +
        '"colours": [' +
        '[28.516, 1],' +
        '[54.922, 1],' +
        '[105.078, 0]' +
        ']' +
        '},' +
        '"plateau_current_value": 0,' +
        '"current_voltage_ratio": 0,' +
        '"peak_current": 0' +
        '},' +
        '"ac_current_metrics": {' +
        '"metric": {' +
        '"mcon": 37.55841121495328,' +
        '"acon_mcon_difference": -0.4490362149532814' +
        '},' +
        '"status": {' +
        '"mcon": 0' +
        '}' +
        '},' +
        '"dc_voltage_metrics": {' +
        '"metric": {' +
        '"voltage_drop": 1.2769990648745304,' +
        '"ac_ripple": 0.12594985741527537' +
        '},' +
        '"status": {' +
        '"voltage_drop": 1,' +
        '"ac_ripple": 0' +
        '}' +
        '},' +
        '"issues": [' +
        '{' +
        '"descr": "cbCauseGreenBuffer",' +
        '"colour": "cbGroupColG",' +
        '"defect": "cbDefectNone",' +
        '"action": "cbActionPolicy",' +
        '"notes": "cbNotesNone",' +
        '"status": 4,' +
        '"metric": "buffer_delay"' +
        '},' +
        '{' +
        '"descr": "cbCauseGreenAcon",' +
        '"colour": "cbGroupColG",' +
        '"defect": "cbDefectNone",' +
        '"action": "cbActionPolicy",' +
        '"notes": "cbNotesNone",' +
        '"status": 2,' +
        '"metric": "acon_delay"' +
        '},' +
        '{' +
        '"descr": "cbGroupUnknown",' +
        '"colour": "cbGroupColK",' +
        '"defect": "cbGroupUnknown",' +
        '"action": "cbGroupUnknown",' +
        '"notes": "cbNotesNone",' +
        '"status": 0,' +
        '"metric": "plateau_current_fluctuations"' +
        '},' +
        '{' +
        '"descr": "cbGroupUnknown",' +
        '"colour": "cbGroupColK",' +
        '"defect": "cbGroupUnknown",' +
        '"action": "cbGroupUnknown",' +
        '"notes": "cbNotesNone",' +
        '"status": 0,' +
        '"metric": "mcon"' +
        '},' +
        '{' +
        '"descr": "cbCauseGreenDCVoltDrop",' +
        '"colour": "cbGroupColG",' +
        '"defect": "cbDefectNone",' +
        '"action": "cbActionPolicy",' +
        '"notes": "cbNotesNone",' +
        '"status": 1,' +
        '"metric": "voltage_drop"' +
        '},' +
        '{' +
        '"descr": "cbGroupUnknown",' +
        '"colour": "cbGroupColK",' +
        '"defect": "cbGroupUnknown",' +
        '"action": "cbGroupUnknown",' +
        '"notes": "cbNotesNone",' +
        '"status": 0,' +
        '"metric": "ac_ripple"' +
        '}' +
        '],' +
        '"condition_group": {' +
        '"status": 1,' +
        '"group": "cbGroupGood",' +
        '"colour": "cbGroupColG",' +
        '"action": "cbActionPolicy",' +
        '"notes": ["cbNotesNone", "cbNotesNone", "cbNotesNone"]' +
        '},' +
        '"circuit_breaker": {' +
        '"error_code": 0,' +
        '"error_text": null,' +
        '"version_ml_model": "0.1.9",' +
        '"breaker_type": "SE3B SDO30125",' +
        '"operation_type": "trip"' +
        '}' +
        '}' +
        '}' +
        '}';

    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        if (request.getEndpoint().contains('streams/100/signals') && request.getEndpoint().contains('1302084312000')) {
            response.setStatusCode(200);
            response.setBody(SIGNAL);
        } else if (request.getEndpoint().contains('streams/99999/signals')) {
            response.setStatusCode(403);
        } else {
            response.setStatusCode(404);
        }

        return response;
    }
}