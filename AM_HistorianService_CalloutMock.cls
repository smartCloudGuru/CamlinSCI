@isTest
global class AM_HistorianService_CalloutMock implements HttpCalloutMock {
    global HTTPResponse respond(HTTPRequest request) {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');

        String endPoint = request.getEndpoint();

        if (request.getMethod() == 'POST') {
            if (endPoint.contains('/historian/api/1/streams/getValues')) {
                return endPoint.contains('downSample=raw')
                    ? new AM_HistorianService_GetCursorValuesMock().respond(request)
                    : new AM_HistorianService_GetValuesMock().respond(request);
            }

            if (endPoint.contains('/historian/api/1/streams/getSinglePointValues')) {
                return new AM_HistorianService_GetSinglePointMock().respond(request);
            }

            if (endPoint.contains('AM_Services/asset/api/1/valuesTimeSeries/get')) {
                return new AM_AssetService_GetValuesTimeSeriesMock().respond(request);
            }

            if (endPoint.contains('/historian/api/1/streams/storeSinglePointValues')) {
                return new AM_HistorianService_StoreSinglePointMock().respond(request);
            }

            response.setStatusCode(404);
            return response;
        }

        if (request.getMethod() == 'PATCH') {
            if (endPoint.contains('/historian/api/1/streams') && endPoint.contains('/values?')) {
                response.setStatusCode(204);
            } else {
                response.setStatusCode(404);
            }

            return response;
        }

        if (endPoint.contains('/asset/api/1/assets/')) {
            if (endPoint.contains('/startTime?')) {
                return new AM_AssetService_UpdateStartEndTimeMock().respond(request);
            }

            if (endPoint.contains('/endTime?')) {
                return new AM_AssetService_UpdateStartEndTimeMock().respond(request);
            }

            response.setStatusCode(404);
            return response;
        }

        if (endPoint.contains('/asset/api/1/signalsTimeSeries/')) {
            return new AM_AssetService_GetSignalsTSDetailsMock().respond(request);
        }

        if (endPoint.contains('/asset/api/1/valuesTimeSeries/')) {
            if (endPoint.contains('/min?')) {
                return new AM_AssetService_UpdateMinMaxValueMock().respond(request);
            }

            if (endPoint.contains('/max?')) {
                return new AM_AssetService_UpdateMinMaxValueMock().respond(request);
            }

            return new AM_AssetService_GetValuesTSDetailsMock().respond(request);
        }

        if (endPoint.contains('/asset/api/1/signalsTimeSeries')) {
            return new AM_AssetService_GetSignalsTSMock().respond(request);
        }

        if (endPoint.contains('/asset/api/1/valuesTimeSeries')) {
            return new AM_AssetService_GetValuesTSMock().respond(request);
        }

        if (endPoint.contains('/historian/api/1/signals/')) {
            if (request.getEndpoint().contains('/waveforms?'))
                return new AM_HistorianService_GetWaveformsMock().respond(request);

            return new AM_HistorianService_GetSignalDetailsMock().respond(request);
        }

        if (endPoint.contains('/historian/api/1/streams/')) {
            if (endPoint.contains('/signals?')) {
                return new AM_HistorianService_GetSignalsMock().respond(request);
            }

            if (endPoint.contains('/signals/')) {
                return new AM_HistorianService_GetSignalMock().respond(request);
            }
        }

        response.setStatusCode(404);
        return response;
    }
}