public with sharing class AM_HistorianService {
    private static String checkSignalAuthorisation(Integer streamId) {
        String signalsTSDetails = AM_AssetService.getSignalsTimeSeriesDetails(streamId);

        if (signalsTSDetails.startsWith('{"statusCode":')) {
            return signalsTSDetails.contains('404') ? null : signalsTSDetails;
        }

        Map<String, Object> signalsTSDetailsMap = (Map<String, Object>) JSON.deserializeUntyped(signalsTSDetails);

        if (!SCI_CommonUtils.checkAssetIdAuthorisation((String) signalsTSDetailsMap.get('assetId'))) {
            return '{"statusCode":403}';
        }

        return null;
    }

    /**
        The method retuns a string with the value of '{"statusCode": 200}'' in case that the user is authorized.
        In any other case, the status that we retrieve from the middleware is returned (is different from 200.

        More specifically:

        - if the user is internal or SME then the user is authorized (a string with the value of '{"statusCode": 200}'' is returned.)

        - if for some reason the method fails to retrieve the asset ids from the stream ids,
        then the user is not authorized (returns the status code taht middleware send)

        - if the user is not authorize for a specific asset id (retrieved from stream ids),
          then a string with value '{"statusCode":403}' returned.

        @param streams stream ids array (Integer array)
        @return a string that includes the authorization status in the form of json.
                If the user is authorized a string with the value of '{"statusCode": 200}'' is returned.
                In any other case, the status that we retrieve from the middleware is returned.
    */
    public static String getUserAuthorizationStatus(Integer[] streams) {
        String successStatus = '{"statusCode": 200 }';

        // if user is internal or SME the user is auhtorized
        if (SCI_CommonUtils.isCurrentUserMemberOfCiPermSets()) {
            System.debug('SCI_CommonUtils.isCurrentUserMemberOfCiPermSets result: succcess');
            return successStatus;
        }

        // if middleware responds with failue response and not an array of asset ids
        // user is not authorized
        String assetIdsResponse = AM_AssetService.getValuesTimeSeriesFor(streams);
        System.debug('AM_AssetService.getValuesTimeSeriesFor result:' + assetIdsResponse);
        if (assetIdsResponse.contains('statusCode')) {
            return assetIdsResponse;
        }

        // check asset id authorization for the current user
        String companyId = SCI_CommonUtils.getUserCompanyId();
        List<Object> assetIdResponse = (List<Object>) JSON.deserializeUntyped(assetIdsResponse);
        for (Object assetIdObj : assetIdResponse) {
            Map<String, Object> data = (Map<String, Object>) assetIdObj;
            String assetId = (String) data.get('assetId');
            System.debug('SCI_CommonUtils.isNotCurrentUserAuthorizedFor with assetId:' + assetId);
            if (assetId != null && SCI_CommonUtils.isNotCurrentUserAuthorizedFor(assetId, companyId)) {
                return '{"statusCode":403}';
            }
        }

        return successStatus;
    }

    // This method must be public
    public static String getSignalDetails(Integer signalid) {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('callout:AM_Services/historian/api/1/signals/' + signalId);

        System.debug('GET: ' + 'callout:AM_Services/historian/api/1/signals/' + signalId);

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 200) {
            return response.getBody();
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
    }

    @AuraEnabled(cacheable=true)
    public static String getCursorValues(Integer[] streams, Long cursorTimestamp, Long cursorTimespanWidth) {

        for (Integer streamId : streams) {
            System.debug('getCursorValues current streamId: ' + streamId);    
        }
        System.debug('getCursorValues streams: ' + streams);
        System.debug('getCursorValues cursorTimestamp: ' + cursorTimestamp);
        System.debug('getCursorValues cursorTimespanWidth: ' + cursorTimespanWidth);
        
        System.debug('getCursorValues');
        String authorizationStatus = getUserAuthorizationStatus(streams);
        if (!authorizationStatus.contains('200')) {
            return authorizationStatus;
        }

        
        Long searchTimespan = (cursorTimespanWidth != null ? cursorTimespanWidth / 2 : 0);
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(
            'callout:AM_Services/historian/api/1/streams/getValues' +
            '?startTime=' +
            Math.floor(cursorTimestamp - searchTimespan).longValue() +
            '&endTime=' +
            Math.ceil(cursorTimestamp + searchTimespan).longValue() +
            '&downSample=raw'
        );

        System.debug(
            'POST: ' +
            'callout:AM_Services/historian/api/1/streams/getValues' +
            '?startTime=' +
            Math.floor(cursorTimestamp - searchTimespan).longValue() +
            '&endTime=' +
            Math.ceil(cursorTimestamp + searchTimespan).longValue() +
            '&downSample=raw'
        );

        request.setHeader('Content-Type', 'application/json');

        JSONGenerator jsonGen = JSON.createGenerator(false);
        jsonGen.writeStartArray();

        for (Integer streamId : streams) {
            jsonGen.writeNumber(streamId);
        }

        jsonGen.writeEndArray();
        request.setBody(jsonGen.getAsString());

        HttpResponse response = new Http().send(request);

        System.debug('response in get getCursorValues: ' + response);

        if (response.getStatusCode() == 200) {
            System.debug('response in get getCursorValues body: ' + response.getBody());
            return response.getBody();
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
        //return AM_HistorianService_GetCursorValuesMock.VALUES;
    }

    @AuraEnabled(cacheable=false)
    public static String getSinglePointValues(Integer[] streams, Long timestamp) {
        System.debug('getSinglePointValues');
        String authorizationStatus = getUserAuthorizationStatus(streams);
        if (!authorizationStatus.contains('200')) {
            return authorizationStatus;
        }

        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('callout:AM_Services/historian/api/1/streams/getSinglePointValues?time=' + timestamp);
        request.setHeader('Content-Type', 'application/json');

        System.debug('POST: ' + 'callout:AM_Services/historian/api/1/streams/getSinglePointValues?time=' + timestamp);

        JSONGenerator jsonGen = JSON.createGenerator(false);
        jsonGen.writeStartArray();

        for (Integer streamId : streams) {
            jsonGen.writeNumber(streamId);
        }

        jsonGen.writeEndArray();
        request.setBody(jsonGen.getAsString());

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 200) {
            return response.getBody();
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
        //return AM_HistorianService_GetSinglePointMock.SINGLE_POINT_VALUES;
    }

    @AuraEnabled(cacheable=true)
    public static String getSignal(Integer streamId, Long timestamp) {
        System.debug('getSignal');
        String authorisationOutcome = checkSignalAuthorisation(streamId);

        if (authorisationOutcome != null) {
            return authorisationOutcome;
        }

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('callout:AM_Services/historian/api/1/streams/' + streamId + '/signals/' + timestamp + '');
        System.debug(
            'GET: ' +
            'callout:AM_Services/historian/api/1/streams/' +
            streamId +
            '/signals/' +
            timestamp +
            ''
        );

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 200) {
            return response.getBody();
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
        //return AM_HistorianService_GetSignalsMock.SIGNAL;
    }

    @AuraEnabled(cacheable=true)
    public static String getSignals(Integer streamId, Long startTime, Long endTime) {
        System.debug('getSignals');
        String authorisationOutcome = checkSignalAuthorisation(streamId);

        if (authorisationOutcome != null) {
            return authorisationOutcome;
        }

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(
            'callout:AM_Services/historian/api/1/streams/' +
            streamId +
            '/signals' +
            '?startTime=' +
            (startTime == null ? 'null' : '' + startTime) +
            '&endTime=' +
            (endTime == null ? 'null' : '' + endTime)
        );

        System.debug(
            'GET: ' +
            'callout:AM_Services/historian/api/1/streams/' +
            streamId +
            '/signals' +
            '?startTime=' +
            (startTime == null ? 'null' : '' + startTime) +
            '&endTime=' +
            (endTime == null ? 'null' : '' + endTime)
        );

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 200) {
            return response.getBody();
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
        //return AM_HistorianService_GetSignalsMock.SIGNALS;
    }

    @AuraEnabled(cacheable=true)
    public static String getStreamsData(Integer[] streams, Long startTime, Long endTime, Integer maxItems) {
        System.debug('getStreamsData with streams: ' + streams);
        String authorizationStatus = getUserAuthorizationStatus(streams);
        if (!authorizationStatus.contains('200')) {
            return authorizationStatus;
        }

        HttpRequest request = new HttpRequest();
        request.setMethod('POST');

        String endpoint = 'callout:AM_Services/historian/api/1/streams/getValues' +
        '?startTime=' +
        (startTime != null ? String.valueOf(startTime) : 'null') +
        '&endTime=' +
        (endTime != null ? String.valueOf(endTime) : 'null') +
        '&downSample=' +
        (maxItems != null ? String.valueOf(maxItems) : 'raw');

        request.setEndpoint(endpoint);
        System.debug(endpoint);

        request.setHeader('Content-Type', 'application/json');

        JSONGenerator jsonGen = JSON.createGenerator(false);
        jsonGen.writeStartArray();

        for (Integer streamId : streams) {
            jsonGen.writeNumber(streamId);
        }

        jsonGen.writeEndArray();
        request.setBody(jsonGen.getAsString());

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 200) {
            return response.getBody();
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
    }

    @AuraEnabled(cacheable=true)
    public static String getWaveforms(
        Integer signalId,
        List<String> channels,
        Integer startIndex,
        Integer endIndex,
        Integer maxItems
    ) {
        System.debug('getWaveforms');
        String signalDetails = getSignalDetails(signalId);

        if (signalDetails.startsWith('{"statusCode":'))
            return signalDetails;

        Map<String, Object> signalDetailsMap = (Map<String, Object>) JSON.deserializeUntyped(signalDetails);

        String authorisationOutcome = checkSignalAuthorisation((Integer) signalDetailsMap.get('streamId'));

        if (authorisationOutcome != null)
            return authorisationOutcome;

        String[] channelParams = new List<String>();
        if (channels != null) {
            for (String c : channels) {
                channelParams.add(EncodingUtil.urlEncode(c, 'UTF-8'));
            }
        }

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(
            'callout:AM_Services/historian/api/1/signals/' +
            signalId +
            '/waveforms' +
            '?startIndex=' +
            (startIndex == null ? 'null' : '' + startIndex) +
            '&endIndex=' +
            (endIndex == null ? 'null' : '' + endIndex) +
            '&limit=' +
            (maxItems == null ? '0' : '' + maxItems) +
            (channelParams.isEmpty() ? '' : '&channel=' + String.join(channelParams, '&channel='))
        );

        System.debug(
            'GET: ' +
            'callout:AM_Services/historian/api/1/signals/' +
            signalId +
            '/waveforms' +
            '?startIndex=' +
            (startIndex == null ? 'null' : '' + startIndex) +
            '&endIndex=' +
            (endIndex == null ? 'null' : '' + endIndex) +
            '&limit=' +
            (maxItems == null ? '0' : '' + maxItems) +
            (channelParams.isEmpty() ? '' : '&channel=' + String.join(channelParams, '&channel='))
        );

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 200) {
            return response.getBody();
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
    }

    @AuraEnabled(cacheable=false)
    public static String storeSinglePointValues(Long timestamp, String data) {
        System.debug('storeSinglePointValues');
        Map<String, Object> dataMap = (Map<String, Object>) JSON.deserializeUntyped(data);

        List<Integer> streams = getStreamIdsFs(dataMap);

        String authorizationStatus = getUserAuthorizationStatus(streams);
        if (!authorizationStatus.contains('200')) {
            return authorizationStatus;
        }

        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('callout:AM_Services/historian/api/1/streams/storeSinglePointValues?time=' + timestamp);
        request.setHeader('Content-Type', 'application/json');

        System.debug('POST: ' + 'callout:AM_Services/historian/api/1/streams/storeSinglePointValues?time=' + timestamp);

        JSONGenerator jsonGen = JSON.createGenerator(false);
        jsonGen.writeStartObject();

        Map<Integer, Object> streamIds = new Map<Integer, Object>();
        for (String type : dataMap.keySet()) {
            jsonGen.writeFieldName(type);

            jsonGen.writeStartObject();

            Map<String, Object> innerDataMap = (Map<String, Object>) dataMap.get(type);
            for (String streamIdKey : innerDataMap.keySet()) {
                Object value = innerDataMap.get(streamIdKey);

                if (
                    value instanceof Double ||
                    value instanceof Integer ||
                    value instanceof Long ||
                    value instanceof Decimal ||
                    value instanceof String ||
                    value instanceof Boolean
                ) {
                    jsonGen.writeFieldName(streamIdKey);

                    streamIds.put(Integer.valueOf(streamIdKey), value);

                    if (value instanceof Double) {
                        jsonGen.writeNumber((Double) value);
                    } else if (value instanceof Integer) {
                        jsonGen.writeNumber((Integer) value);
                    } else if (value instanceof Long) {
                        jsonGen.writeNumber((Long) value);
                    } else if (value instanceof Decimal) {
                        jsonGen.writeNumber((Decimal) value);
                    } else if (value instanceof Boolean) {
                        jsonGen.writeBoolean((Boolean) value);
                    } else {
                        jsonGen.writeString((String) value);
                    }
                }
            }

            jsonGen.writeEndObject();
        }

        jsonGen.writeEndObject();

        request.setBody(jsonGen.getAsString());

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 204) {
            boolean startAndEndTimeUpdated = false;
            String assetId = null;

            for (Integer streamId : streamIds.keySet()) {
                String outcome = AM_AssetService.updateTimeSeriesMinMaxValues(streamId, streamIds.get(streamId));

                if (assetId == null) {
                    assetId = outcome;
                }
            }

            if (!startAndEndTimeUpdated && assetId != null) {
                AM_AssetService.updateStartAndEndTime(assetId, timestamp);
                startAndEndTimeUpdated = true;
            }

            return '';
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
    }

    private static List<Integer> getStreamIdsFs(Map<String, Object> dataMap) {
        List<Integer> streams = new List<Integer>();
        for (String type : dataMap.keySet()) {
            Map<String, Object> innerDataMap = (Map<String, Object>) dataMap.get(type);

            for (String streamIdKey : innerDataMap.keySet()) {
                streams.add(Integer.valueOf(streamIdKey));
            }
        }
        return streams;
    }
}