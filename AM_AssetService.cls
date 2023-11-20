public with sharing class AM_AssetService {
    private static void notifyDeviceLinkupUpdateFailure(
        String assetId,
        String totusSerialId,
        Datetime activationTime,
        Datetime deactivationTime
    ) {
        List<TOTUS_Device__c> tdList = [
            SELECT ID
            FROM TOTUS_Device__c
            WHERE
                TOTUS_Serial_ID__c = :totusSerialId
                AND Transformer__r.Asset_ID__c = :assetId
                AND Activation_Time__c = :activationTime
                AND Deactivation_Time__c = :deactivationTime
        ];

        if (tdList != null && tdList.size() > 0) {
            tdList[0].addError('Failed to update device link-up data to back-end.');
        }
    }

    @future(callout=true)
    public static void createTOTUSDevice(ID id) {
        List<TOTUS_Device__c> tdList = [
            SELECT
                TOTUS_Serial_ID__c,
                Transformer__r.Asset_ID__c,
                Activation_Time__c,
                Deactivation_Time__c,
                Multiasset_Channel__c,
                Is_Multitank__c,
                DGA_Source_A__c,
                DGA_Source_B__c,
                DGA_Source_C__c,
                Load_Sensor_Installation_Side__c
            FROM TOTUS_Device__c
            WHERE Id = :id
        ];

        if (tdList == null || tdList.size() == 0) {
            throw new IllegalArgumentException('TOTUS device related to given ID is missing.');
        }

        TOTUS_Device__c td = tdList[0];

        JSONGenerator jsonGen = JSON.createGenerator(false);
        jsonGen.writeStartObject();

        Boolean dgaAvailable = td.DGA_Source_A__c != null || td.Is_Multitank__c != null;

        if (dgaAvailable) {
            jsonGen.writeFieldName('dga');
            jsonGen.writeStartObject();

            if (td.DGA_Source_A__c != null) {
                jsonGen.writeStringField('sampleSourceA', td.DGA_Source_A__c);
            }

            if (td.Is_Multitank__c != null) {
                jsonGen.writeBooleanField('isMultitank', td.Is_Multitank__c);

                if (td.DGA_Source_B__c != null) {
                    jsonGen.writeStringField('sampleSourceB', td.DGA_Source_B__c);
                }

                if (td.DGA_Source_C__c != null) {
                    jsonGen.writeStringField('sampleSourceC', td.DGA_Source_C__c);
                }
            }

            jsonGen.writeEndObject();
        }

        if (td.Load_Sensor_Installation_Side__c != null) {
            jsonGen.writeFieldName('loadSensor');
            jsonGen.writeStartObject();

            jsonGen.writeStringField('installationSide', td.Load_Sensor_Installation_Side__c);

            jsonGen.writeEndObject();
        }

        jsonGen.writeEndObject();

        String outcome = createDeviceLinkup(
            td.Transformer__r.Asset_ID__c,
            td.TOTUS_Serial_ID__c,
            td.Activation_Time__c != null ? td.Activation_Time__c.getTime() : null,
            td.Deactivation_Time__c != null ? td.Deactivation_Time__c.getTime() : null,
            td.Multiasset_Channel__c != null &&
                td.Multiasset_Channel__c.length() > 0
                ? Integer.valueOf(td.Multiasset_Channel__c)
                : null,
            jsonGen.getAsString()
        );

        if (outcome != null && outcome.length() > 0) {
            new TOTUS_Device__c(Id = id).addError('Failed to update device link-up data to back-end.');
        }
    }

    @AuraEnabled(cacheable=false)
    public static String importCsvCircuitBreakers(String file, String companyId) {
        // Salesforce permission check
        if (!SCI_CommonUtils.isCurrentUserMemberOfPermissionSet('Connected_Insights_SME'))
            return '{"statusCode":403}';

        // backend call for CBs registration
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(
            'callout:AM_Services/import/api/1/fileImportation/cb?returnSuccessful=true&companyId=' + EncodingUtil.urlEncode(companyId, 'UTF-8')
        );
        request.setHeader('Content-Type', 'application/octet-stream');
        request.setBodyAsBlob(Blob.valueOf(file.unescapeJava()));
        Http http = new Http();
        HttpResponse response = http.send(request);
        String bodyResponse = response.getBody();
        Integer statusCode = response.getStatusCode();

        // internal server error
        if (statusCode == 500) {
            return '{"statusCode":' + statusCode + '}';    
        }

        // response processing in case of 2XX
        Map<String, Object> assetData = (Map<String, Object>) JSON.deserializeUntyped(bodyResponse);
        if (assetData.containsKey('succeeded')) {
            List<Object> cbs = (List<Object>) assetData.get('succeeded');
            for (Object cb : cbs) {
		        Map<String, Object> cbValues = (Map<String, Object>) cb;
                String substationName = (String) cbValues.get('substationName');
                String circuitBreakerName = (String) cbValues.get('breakerOrgId');
                AM_ImportService.manageCircuitBreakerExistence(
                    companyId,
                    substationName,
                    SCI_CommonUtils.escapeSymbols(substationName),
                    circuitBreakerName,
                    SCI_CommonUtils.escapeSymbols(circuitBreakerName),
                    'Europe/London'
                );
	        }
        }

        return '{"statusCode":' + statusCode + ', "body":' + bodyResponse + '}';
    }


    @future(callout=true)
    public static void removeTOTUSDevice(ID id) {
        List<TOTUS_Device__c> tdList = [
            SELECT TOTUS_Serial_ID__c, Transformer__r.Asset_ID__c, Activation_Time__c, Deactivation_Time__c
            FROM TOTUS_Device__c
            WHERE Id = :id
        ];

        if (tdList == null || tdList.size() == 0) {
            throw new IllegalArgumentException('TOTUS device related to given ID is missing.');
        }

        TOTUS_Device__c td = tdList[0];
        String outcome = removeDeviceLinkup(
            td.Transformer__r.Asset_ID__c,
            td.TOTUS_Serial_ID__c,
            td.Activation_Time__c != null ? td.Activation_Time__c.getTime() : null,
            td.Deactivation_Time__c != null ? td.Deactivation_Time__c.getTime() : null
        );

        if (outcome != null && outcome.length() > 0) {
            new TOTUS_Device__c(Id = id).addError('Failed to remove device link-up data from back-end.');
        }
    }

    @future(callout=true)
    public static void createTransformer(ID id) {
        List<Transformer__c> trList = [
            SELECT
                Asset_ID__c,
                Asset_UUID__c,
                Company__r.Company_ID__c,
                Location__r.Site_ID__c,
                Equipment_Number__c,
                HV_Bushing_Manufacturing_Year__c,
                HV_Bushing_OEM__r.Name,
                Bushing_HV_Rated_Current__c,
                HV_Bushing_Type__c,
                LV1_Bushing_Manufacturing_Year__c,
                LV2_Bushing_Manufacturing_Year__c,
                LV1_Bushing_OEM__r.Name,
                LV2_Bushing_OEM__r.Name,
                Bushing_LV1_Rated_Current__c,
                Bushing_LV2_Rated_Current__c,
                LV1_Bushing_Type__c,
                LV2_Bushing_Type__c,
                TV_Bushing_Manufacturing_Year__c,
                TV_Bushing_OEM__r.Name,
                Bushing_TV_Rated_Current__c,
                TV_Bushing_Type__c,
                Grid_Frequency__c,
                Installation_Year__c,
                Manufacturing_Year__c,
                Name,
                Load_Losses_FAT__c,
                No_Load_Losses_FAT__c,
                Number_of_cooling_stages__c,
                Number_of_Phases__c,
                Number_of_Windings__c,
                DETC_OEM__c,
                DETC_Installation_Side__c,
                OLTC_OEM__c,
                OLTC_Installation_Side__c,
                External_Cooling__c,
                Internal_Cooling__c,
                Oil_Protection_System__c,
                Oil_Type__c,
                OLTC_Diverter_Switch_Design__c,
                OLTC_Diverter_Switch_Technology__c,
                OLTC_Installation_Position__c,
                OLTC_Switching_Type__c,
                OLTC_Type__c,
                Max_Rating__c,
                Rated_Voltage_HV__c,
                Rated_Voltage_LV1__c,
                Rated_Voltage_LV2__c,
                Rated_Voltage_TV__c,
                Serial_Number__c,
                Tertiary__c,
                Transformer_OEM__r.Name,
                Location__r.Time_Zone__c,
                Transformer_Type__c
            FROM Transformer__c
            WHERE Id = :id
        ];

        if (trList.isEmpty()) {
            throw new IllegalArgumentException('Transformer with ID ' + id + ' not found.');
        }

        Transformer__c tr = trList[0];

        JSONGenerator jsonGen = JSON.createGenerator(false);
        jsonGen.writeStartObject();

        jsonGen.writeStringField('companyId', tr.Company__r.Company_ID__c);
        jsonGen.writeStringField('siteId', tr.Location__r.Site_ID__c);

        Boolean hvBushingAvailable =
            tr.HV_Bushing_Manufacturing_Year__c != null ||
            tr.HV_Bushing_OEM__r != null ||
            tr.Bushing_HV_Rated_Current__c != null ||
            tr.HV_Bushing_Type__c != null;
        Boolean lv1BushingAvailable =
            tr.LV1_Bushing_Manufacturing_Year__c != null ||
            tr.LV1_Bushing_OEM__r != null ||
            tr.Bushing_LV1_Rated_Current__c != null ||
            tr.LV1_Bushing_Type__c != null;
        Boolean lv2BushingAvailable =
            tr.LV2_Bushing_Manufacturing_Year__c != null ||
            tr.LV2_Bushing_OEM__r != null ||
            tr.Bushing_LV2_Rated_Current__c != null ||
            tr.LV2_Bushing_Type__c != null;
        Boolean tvBushingAvailable =
            tr.TV_Bushing_Manufacturing_Year__c != null ||
            tr.TV_Bushing_OEM__r != null ||
            tr.Bushing_TV_Rated_Current__c != null ||
            tr.TV_Bushing_Type__c != null;

        if (hvBushingAvailable || lv1BushingAvailable || lv2BushingAvailable || tvBushingAvailable) {
            jsonGen.writeFieldName('bushing');
            jsonGen.writeStartObject();

            if (hvBushingAvailable) {
                jsonGen.writeFieldName('hv');
                jsonGen.writeStartObject();

                if (tr.HV_Bushing_Manufacturing_Year__c != null) {
                    jsonGen.writeNumberField('manufacturingYear', tr.HV_Bushing_Manufacturing_Year__c);
                }

                if (tr.HV_Bushing_OEM__r != null) {
                    jsonGen.writeStringField('oem', tr.HV_Bushing_OEM__r.Name);
                }

                if (tr.Bushing_HV_Rated_Current__c != null) {
                    jsonGen.writeNumberField('ratedCurrent', tr.Bushing_HV_Rated_Current__c);
                }

                if (tr.HV_Bushing_Type__c != null) {
                    jsonGen.writeStringField('type', tr.HV_Bushing_Type__c);
                }

                jsonGen.writeEndObject();
            }

            if (lv1BushingAvailable) {
                jsonGen.writeFieldName('lv1');
                jsonGen.writeStartObject();

                if (tr.LV1_Bushing_Manufacturing_Year__c != null) {
                    jsonGen.writeNumberField('manufacturingYear', tr.LV1_Bushing_Manufacturing_Year__c);
                }

                if (tr.LV1_Bushing_OEM__r != null) {
                    jsonGen.writeStringField('oem', tr.LV1_Bushing_OEM__r.Name);
                }

                if (tr.Bushing_LV1_Rated_Current__c != null) {
                    jsonGen.writeNumberField('ratedCurrent', tr.Bushing_LV1_Rated_Current__c);
                }

                if (tr.LV1_Bushing_Type__c != null) {
                    jsonGen.writeStringField('type', tr.LV1_Bushing_Type__c);
                }

                jsonGen.writeEndObject();
            }

            if (lv2BushingAvailable) {
                jsonGen.writeFieldName('lv2');
                jsonGen.writeStartObject();

                if (tr.LV2_Bushing_Manufacturing_Year__c != null) {
                    jsonGen.writeNumberField('manufacturingYear', tr.LV2_Bushing_Manufacturing_Year__c);
                }

                if (tr.LV2_Bushing_OEM__r != null) {
                    jsonGen.writeStringField('oem', tr.LV2_Bushing_OEM__r.Name);
                }

                if (tr.Bushing_LV2_Rated_Current__c != null) {
                    jsonGen.writeNumberField('ratedCurrent', tr.Bushing_LV2_Rated_Current__c);
                }

                if (tr.LV2_Bushing_Type__c != null) {
                    jsonGen.writeStringField('type', tr.LV2_Bushing_Type__c);
                }

                jsonGen.writeEndObject();
            }

            if (tvBushingAvailable) {
                jsonGen.writeFieldName('tv');
                jsonGen.writeStartObject();

                if (tr.TV_Bushing_Manufacturing_Year__c != null) {
                    jsonGen.writeNumberField('manufacturingYear', tr.TV_Bushing_Manufacturing_Year__c);
                }

                if (tr.TV_Bushing_OEM__r != null) {
                    jsonGen.writeStringField('oem', tr.TV_Bushing_OEM__r.Name);
                }

                if (tr.Bushing_TV_Rated_Current__c != null) {
                    jsonGen.writeNumberField('ratedCurrent', tr.Bushing_TV_Rated_Current__c);
                }

                if (tr.TV_Bushing_Type__c != null) {
                    jsonGen.writeStringField('type', tr.TV_Bushing_Type__c);
                }

                jsonGen.writeEndObject();
            }

            jsonGen.writeEndObject();
        }

        if (tr.Equipment_Number__c != null) {
            jsonGen.writeStringField('equipmentNumber', tr.Equipment_Number__c);
        }

        if (tr.Grid_Frequency__c != null) {
            jsonGen.writeNumberField('gridFrequency', Integer.valueOf(tr.Grid_Frequency__c));
        }

        if (tr.Installation_Year__c != null) {
            jsonGen.writeNumberField('installationYear', tr.Installation_Year__c);
        }

        if (tr.Manufacturing_Year__c != null) {
            jsonGen.writeNumberField('manufacturingYear', tr.Manufacturing_Year__c);
        }

        if (tr.Load_Losses_FAT__c != null) {
            jsonGen.writeNumberField('loadLossesFAT', tr.Load_Losses_FAT__c);
        }

        if (tr.No_Load_Losses_FAT__c != null) {
            jsonGen.writeNumberField('noLoadLossesFAT', tr.No_Load_Losses_FAT__c);
        }

        if (tr.Number_of_cooling_stages__c != null) {
            jsonGen.writeNumberField('numberOfCoolingStages', Integer.valueOf(tr.Number_of_cooling_stages__c));
        }

        if (tr.Number_of_Phases__c != null) {
            jsonGen.writeNumberField('numberOfPhases', Integer.valueOf(tr.Number_of_Phases__c));
        }

        if (tr.Number_of_Windings__c != null) {
            jsonGen.writeNumberField('numberOfWindings', Integer.valueOf(tr.Number_of_Windings__c));
        }

        if (tr.External_Cooling__c != null) {
            jsonGen.writeStringField('externalCooling', tr.External_Cooling__c);
        }

        if (tr.Internal_Cooling__c != null) {
            jsonGen.writeStringField('internalCooling', tr.Internal_Cooling__c);
        }

        if (tr.Oil_Protection_System__c != null) {
            jsonGen.writeStringField('oilProtectionSystem', tr.Oil_Protection_System__c);
        }

        if (tr.Oil_Type__c != null) {
            jsonGen.writeStringField('oilType', tr.Oil_Type__c);
        }

        Boolean detcAvailable = tr.DETC_OEM__c != null || tr.DETC_Installation_Side__c != null;

        if (detcAvailable) {
            jsonGen.writeFieldName('detc');
            jsonGen.writeStartObject();

            if (tr.DETC_OEM__c != null) {
                jsonGen.writeStringField('oem', tr.DETC_OEM__c);
            }

            if (tr.DETC_Installation_Side__c != null) {
                jsonGen.writeStringField('installationSide', tr.DETC_Installation_Side__c);
            }

            jsonGen.writeEndObject();
        }

        Boolean oltcAvailable =
            tr.OLTC_OEM__c != null ||
            tr.OLTC_Installation_Side__c != null ||
            tr.OLTC_Diverter_Switch_Design__c != null ||
            tr.OLTC_Diverter_Switch_Technology__c != null ||
            tr.OLTC_Installation_Position__c != null ||
            tr.OLTC_Switching_Type__c != null ||
            tr.OLTC_Type__c != null;

        if (oltcAvailable) {
            jsonGen.writeFieldName('oltc');
            jsonGen.writeStartObject();

            if (tr.OLTC_OEM__c != null) {
                jsonGen.writeStringField('oem', tr.OLTC_OEM__c);
            }

            if (tr.OLTC_Installation_Side__c != null) {
                jsonGen.writeStringField('installationSide', tr.OLTC_Installation_Side__c);
            }

            if (tr.OLTC_Diverter_Switch_Design__c != null) {
                jsonGen.writeStringField('diverterSwitchDesign', tr.OLTC_Diverter_Switch_Design__c);
            }

            if (tr.OLTC_Diverter_Switch_Technology__c != null) {
                jsonGen.writeStringField('diverterSwitchTechnology', tr.OLTC_Diverter_Switch_Technology__c);
            }

            if (tr.OLTC_Installation_Position__c != null) {
                jsonGen.writeStringField('installationPosition', tr.OLTC_Installation_Position__c);
            }

            if (tr.OLTC_Switching_Type__c != null) {
                jsonGen.writeStringField('switchingType', tr.OLTC_Switching_Type__c);
            }

            if (tr.OLTC_Type__c != null) {
                jsonGen.writeStringField('type', tr.OLTC_Type__c);
            }

            jsonGen.writeEndObject();
        }

        if (tr.Transformer_OEM__r != null) {
            jsonGen.writeStringField('oem', tr.Transformer_OEM__r.Name);
        }

        if (tr.Max_Rating__c != null) {
            jsonGen.writeNumberField('maxRating', tr.Max_Rating__c);
        }

        if (tr.Rated_Voltage_HV__c != null) {
            jsonGen.writeNumberField('ratedVoltageHV', tr.Rated_Voltage_HV__c);
        }

        if (tr.Rated_Voltage_LV1__c != null) {
            jsonGen.writeNumberField('ratedVoltageLV1', tr.Rated_Voltage_LV1__c);
        }

        if (tr.Rated_Voltage_LV2__c != null) {
            jsonGen.writeNumberField('ratedVoltageLV2', tr.Rated_Voltage_LV2__c);
        }

        if (tr.Rated_Voltage_TV__c != null) {
            jsonGen.writeNumberField('ratedVoltageTV', tr.Rated_Voltage_TV__c);
        }

        if (tr.Serial_Number__c != null) {
            jsonGen.writeStringField('serialNumber', tr.Serial_Number__c);
        }

        if (tr.Location__r != null) {
            jsonGen.writeStringField('timeZone', tr.Location__r.Time_Zone__c);
        }

        if (tr.Tertiary__c != null) {
            jsonGen.writeBooleanField('tertiary', tr.Tertiary__c == 'Y');
        }

        jsonGen.writeEndObject();

        String outcome = createAsset(
            tr.Asset_ID__c,
            tr.Asset_UUID__c,
            'Transformer',
            tr.Transformer_Type__c,
            tr.Name,
            jsonGen.getAsString()
        );

        if (outcome != null && outcome.length() > 0) {
            new Transformer__c(Id = id).addError('Failed to update transformer data to back-end');
        }
    }

    @future(callout=true)
    public static void updateTOTUSDeviceActivationTime(
        ID transformerId,
        String totusSerialId,
        Datetime deactivationTime,
        Datetime activationTime
    ) {
        List<Transformer__c> trList = [SELECT Asset_ID__c FROM Transformer__c WHERE Id = :transformerId];

        if (trList == null || trList.size() == 0) {
            throw new IllegalArgumentException('Transformer with ID ' + transformerId + ' not found.');
        }

        Transformer__c tr = trList[0];

        String outcome = updateDeviceLinkupActivationTime(
            tr.Asset_ID__c,
            totusSerialId,
            deactivationTime != null ? deactivationTime.getTime() : null,
            activationTime != null ? activationTime.getTime() : null
        );

        if (outcome != null && outcome.length() > 0) {
            notifyDeviceLinkupUpdateFailure(tr.Asset_ID__c, totusSerialId, activationTime, deactivationTime);
        }
    }

    @future(callout=true)
    public static void updateTOTUSDeviceDeactivationTime(
        ID transformerId,
        String totusSerialId,
        Datetime activationTime,
        Datetime deactivationTime
    ) {
        List<Transformer__c> trList = [SELECT Asset_ID__c FROM Transformer__c WHERE Id = :transformerId];

        if (trList == null || trList.size() == 0) {
            throw new IllegalArgumentException('Transformer with ID ' + transformerId + ' not found.');
        }

        Transformer__c tr = trList[0];

        String outcome = updateDeviceLinkupDeactivationTime(
            tr.Asset_ID__c,
            totusSerialId,
            activationTime != null ? activationTime.getTime() : null,
            deactivationTime != null ? deactivationTime.getTime() : null
        );

        if (outcome != null && outcome.length() > 0) {
            notifyDeviceLinkupUpdateFailure(tr.Asset_ID__c, totusSerialId, activationTime, deactivationTime);
        }
    }

    @future(callout=true)
    public static void updateTOTUSDeviceProperties(
        ID transformerId,
        String totusSerialId,
        Datetime activationTime,
        Datetime deactivationTime,
        String properties
    ) {
        List<Transformer__c> trList = [SELECT Asset_ID__c FROM Transformer__c WHERE Id = :transformerId];

        if (trList == null || trList.size() == 0) {
            throw new IllegalArgumentException('Transformer with ID ' + transformerId + ' not found.');
        }

        Transformer__c tr = trList[0];

        String outcome = mergeDeviceLinkupProperties(
            tr.Asset_ID__c,
            totusSerialId,
            activationTime != null ? activationTime.getTime() : null,
            deactivationTime != null ? deactivationTime.getTime() : null,
            properties
        );

        if (outcome != null && outcome.length() > 0) {
            notifyDeviceLinkupUpdateFailure(tr.Asset_ID__c, totusSerialId, activationTime, deactivationTime);
        }
    }

    @future(callout=true)
    public static void updateTransformerProperties(String assetId, String properties) {
        String outcome = mergeAssetProperties(assetId, properties);

        if (outcome != null && outcome.length() > 0) {
            List<Transformer__c> trList = [SELECT ID FROM Transformer__c WHERE Asset_ID__c = :assetId];

            if (trList != null && trList.size() > 0) {
                trList[0].addError('Failed to update transformer data to back-end');
            }
        }
    }

    public static String createAsset(
        String assetId,
        String assetUUID,
        String category,
        String type,
        String name,
        String properties
    ) {
        if (!SCI_CommonUtils.checkAssetIdAuthorisation(assetId))
            return '{"statusCode":403}';

        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('callout:AM_Services/asset/api/1/assets/' + EncodingUtil.urlEncode(assetId, 'UTF-8'));
        request.setHeader('Content-Type', 'application/json');

        JSONGenerator jsonGen = JSON.createGenerator(false);
        jsonGen.writeStartObject();
        jsonGen.writeStringField('assetId', assetId);
        jsonGen.writeStringField('assetUUID', assetUUID);
        jsonGen.writeStringField('category', category);

        if (type != null) {
            jsonGen.writeStringField('type', type);
        }

        jsonGen.writeStringField('name', name);
        jsonGen.writeFieldName('properties');
        jsonGen.writeStartObject();
        jsonGen.writeEndObject();
        jsonGen.writeEndObject();

        if (properties != null && properties.length() > 0) {
            request.setBody(jsonGen.getAsString().replace('"properties":{}', '"properties":' + properties));
        } else {
            request.setBody(jsonGen.getAsString());
        }

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 201) {
            return '';
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
    }

    public static String createDeviceLinkup(
        String assetId,
        String deviceId,
        Long activationTime,
        Long deactivationTime,
        Integer multipleAssetIndex,
        String properties
    ) {
        if (!SCI_CommonUtils.checkAssetIdAuthorisation(assetId))
            return '{"statusCode":403}';

        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(
            'callout:AM_Services/asset/api/1/assets/' +
            EncodingUtil.urlEncode(assetId, 'UTF-8') +
            '/addDeviceLinkup'
        );
        request.setHeader('Content-Type', 'application/json');

        JSONGenerator jsonGen = JSON.createGenerator(false);
        jsonGen.writeStartObject();
        jsonGen.writeStringField('assetId', assetId);
        jsonGen.writeStringField('deviceId', deviceId);

        if (multipleAssetIndex != null) {
            jsonGen.writeNumberField('multipleAssetIndex', multipleAssetIndex);
        }

        if (activationTime != null) {
            jsonGen.writeNumberField('activationTime', activationTime);
        }

        if (deactivationTime != null) {
            jsonGen.writeNumberField('deactivationTime', deactivationTime);
        }

        jsonGen.writeFieldName('properties');
        jsonGen.writeStartObject();
        jsonGen.writeEndObject();

        if (properties != null && properties.length() > 0) {
            request.setBody(jsonGen.getAsString().replace('"properties":{}', '"properties":' + properties));
        } else {
            request.setBody(jsonGen.getAsString());
        }

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 204) {
            return '';
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
    }

    public static String getAssetData(String assetId) {
        System.debug('getAssetData assetId: ' + assetId);
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('callout:AM_Services/asset/api/1/assets/' + EncodingUtil.urlEncode(assetId, 'UTF-8'));
        HttpResponse response = new Http().send(request);

        System.debug('GET: ' + 'callout:AM_Services/asset/api/1/assets/' + EncodingUtil.urlEncode(assetId, 'UTF-8'));

        if (response.getStatusCode() == 200) {
            System.debug('getAssetData response body: ' + response.getBody());
            return response.getBody();
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
        //return AM_AssetService_GetAssetMock.ASSET;
    }

    public static String mergeAssetProperties(String assetId, String properties) {
        HttpRequest request = new HttpRequest();
        request.setMethod('PATCH');
        request.setEndpoint(
            'callout:AM_Services/asset/api/1/assets/' +
            EncodingUtil.urlEncode(assetId, 'UTF-8') +
            '/properties'
        );
        request.setHeader('Content-Type', 'application/merge-patch+json');
        request.setBody(properties != null ? properties : '{}');

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 204) {
            return '';
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
    }

    public static String mergeDeviceLinkupProperties(
        String assetId,
        String deviceId,
        Long activationTime,
        Long deactivationTime,
        String properties
    ) {
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(
            'callout:AM_Services/asset/api/1/assets/' +
            EncodingUtil.urlEncode(assetId, 'UTF-8') +
            '/mergeDeviceLinkupProperties?deviceId=' +
            EncodingUtil.urlEncode(deviceId, 'UTF-8') +
            (activationTime != null ? '&activationTime=' + activationTime : '') +
            (deactivationTime != null ? '&deactivationTime=' + deactivationTime : '')
        );
        request.setHeader('Content-Type', 'application/json');
        request.setBody(properties != null ? properties : '{}');

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 204) {
            return '';
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
    }

    public static String removeDeviceLinkup(
        String assetId,
        String deviceId,
        Long activationTime,
        Long deactivationTime
    ) {
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(
            'callout:AM_Services/asset/api/1/assets/' +
            EncodingUtil.urlEncode(assetId, 'UTF-8') +
            '/removeDeviceLinkup'
        );
        request.setHeader('Content-Type', 'application/json');

        JSONGenerator jsonGen = JSON.createGenerator(false);
        jsonGen.writeStartObject();
        jsonGen.writeStringField('assetId', assetId);
        jsonGen.writeStringField('deviceId', deviceId);

        if (activationTime != null) {
            jsonGen.writeNumberField('activationTime', activationTime);
        }

        if (deactivationTime != null) {
            jsonGen.writeNumberField('deactivationTime', deactivationTime);
        }

        request.setBody(jsonGen.getAsString());

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 204) {
            return '';
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
    }

    private static String updateAssetTime(String assetId, Long timestamp, String timeType) {
        HttpRequest request = new HttpRequest();
        request.setMethod('PATCH');
        String endpoint =
            'callout:AM_Services/asset/api/1/assets/' +
            EncodingUtil.urlEncode(assetId, 'UTF-8') +
            '/' +
            timeType +
            'Time';
        request.setEndpoint(endpoint);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(JSON.serialize(timestamp));

        System.debug('PATCH: ' + endpoint);
        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 204) {
            return '';
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
    }

    public static String updateDeviceLinkupActivationTime(
        String assetId,
        String deviceId,
        Long deactivationTime,
        Long newActivationTime
    ) {
        if (newActivationTime == null) {
            return '{"statusCode":400}';
        }

        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(
            'callout:AM_Services/asset/api/1/assets/' +
            EncodingUtil.urlEncode(assetId, 'UTF-8') +
            '/setDeviceLinkupActivationTime?deviceId=' +
            EncodingUtil.urlEncode(deviceId, 'UTF-8') +
            (deactivationTime != null ? '&deactivationTime=' + deactivationTime : '')
        );
        request.setHeader('Content-Type', 'application/json');
        request.setBody(newActivationTime != null ? JSON.serialize(newActivationTime) : '');

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 204) {
            return '';
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
    }

    public static String updateDeviceLinkupDeactivationTime(
        String assetId,
        String deviceId,
        Long activationTime,
        Long newDeactivationTime
    ) {
        if (newDeactivationTime == null) {
            return '{"statusCode":400}';
        }

        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(
            'callout:AM_Services/asset/api/1/assets/' +
            EncodingUtil.urlEncode(assetId, 'UTF-8') +
            '/setDeviceLinkupDeactivationTime?deviceId=' +
            EncodingUtil.urlEncode(deviceId, 'UTF-8') +
            (activationTime != null ? '&activationTime=' + activationTime : '')
        );
        request.setHeader('Content-Type', 'application/json');
        request.setBody(newDeactivationTime != null ? JSON.serialize(newDeactivationTime) : '');

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 204) {
            return '';
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
    }

    private static String updateMinOrMaxValue(Integer streamId, Object value, String minOrMax) {
        HttpRequest request = new HttpRequest();
        request.setMethod('PATCH');
        request.setEndpoint('callout:AM_Services/asset/api/1/valuesTimeSeries/' + streamId + '/' + minOrMax);
        request.setHeader('Content-Type', 'application/json');
        request.setBody(JSON.serialize(value));

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 204) {
            return '';
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
    }

    public static void updateStartAndEndTime(String assetId, Long timestamp) {
        String assetDataStr = getAssetData(assetId);

        if (!assetDataStr.startsWith('{"statusCode":')) {
            Map<String, Object> assetData = (Map<String, Object>) JSON.deserializeUntyped(assetDataStr);
            
            Long startTime = (Long) assetData.get('startTime');
            Long endTime = (Long) assetData.get('endTime');

            if (startTime == null || startTime == 0 || timestamp < startTime) {
                updateAssetTime(assetId, timestamp, 'start');
            }

            if (endTime == null || endTime == 0 || timestamp > endTime) {
                updateAssetTime(assetId, timestamp, 'end');
                /*
                // Update of Condition Index, Condition Group and Last Point Time fields
                String category = (String) assetData.get('category');

                if ('Transformer'.equals(category)) {
                    List<Transformer__c> trList = [SELECT Asset_ID__c FROM Transformer__c WHERE Asset_ID__c = :assetId];

                    if (trList != null && trList.size() == 1) {
                        String valuesTSListStr = getValuesTimeSeries(assetId);

                        if (!valuesTSListStr.startsWith('{"statusCode":')) {
                            List<Object> valuesTSList = (List<Object>) JSON.deserializeUntyped(valuesTSListStr);

                            for (Object item : valuesTSList) {
                                Map<String, Object> timeSeriesDetails = (Map<String, Object>) item;
                                String tsName = (String) timeSeriesDetails.get('name');

                                if (
                                    'Diagnostics/Calculated/Transformer/Condition/CG/ActivePart/DGA/Lab'.equals(tsName)
                                ) {
                                    Integer streamId = (Integer) timeSeriesDetails.get('streamId');
                                    String singlePointsValuesStr = AM_HistorianService.getSinglePointValues(
                                        new List<Integer>{ streamId },
                                        timestamp
                                    );

                                    if (
                                        singlePointsValuesStr != null &&
                                        singlePointsValuesStr.length() > 0 &&
                                        !singlePointsValuesStr.startsWith('{"statusCode":')
                                    ) {
                                        Transformer__c tr = trList[0];
                                        Map<String, Object> singlePointsValues = (Map<String, Object>) JSON.deserializeUntyped(
                                            singlePointsValuesStr
                                        );

                                        tr.Condition_Index__c = (Double) singlePointsValues.get(
                                            String.valueOf(streamId)
                                        );
                                        tr.Last_Point_Time__c = timestamp;

                                        Database.update(tr);
                                    }

                                    break;
                                }
                            }
                        }
                    }
                }*/
            }
        }
    }

    public static String updateTimeSeriesMinMaxValues(Integer streamId, Object value) {
        String valuesTSDetails = getValuesTimeSeriesDetails(streamId);

        if (!valuesTSDetails.startsWith('{"statusCode":')) {
            Map<String, Object> valuesTSDetailsMap = (Map<String, Object>) JSON.deserializeUntyped(valuesTSDetails);

            String type = (String) valuesTSDetailsMap.get('type');
            if (type != 'Boolean' && type != 'String') {
                Map<String, Object> properties = (Map<String, Object>) valuesTSDetailsMap.get('properties');

                Double min = (Double) properties.get('min');

                if (min == null || min > (Double) value) {
                    updateMinOrMaxValue(streamId, value, 'min');
                }

                Double max = (Double) properties.get('max');

                if (max == null || max < (Double) value) {
                    updateMinOrMaxValue(streamId, value, 'max');
                }
            }

            return (String) valuesTSDetailsMap.get('assetId');
        }

        return null;
    }

    @AuraEnabled(cacheable=true)
    public static String createValuesTimeSeries(String assetId, String name, String type, String properties) {
        if (!SCI_CommonUtils.checkAssetIdAuthorisation(assetId))
            return '{"statusCode":403}';

        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint(
            'callout:AM_Services/asset/api/1/assets/' +
            EncodingUtil.urlEncode(assetId, 'UTF-8') +
            '/valuesTimeSeries'
        );
        request.setHeader('Content-Type', 'application/json');

        JSONGenerator jsonGen = JSON.createGenerator(false);
        jsonGen.writeStartObject();
        jsonGen.writeStringField('assetId', assetId);
        jsonGen.writeStringField('name', name);
        jsonGen.writeStringField('type', type);
        jsonGen.writeObjectField('properties', JSON.deserializeUntyped(properties));
        jsonGen.writeEndObject();
        request.setBody(jsonGen.getAsString());

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 200) {
            return response.getBody();
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
    }

    @AuraEnabled(cacheable=true)
    public static String getAsset(String assetId) {
        System.debug('AM_AssetService getAsset assetId: ' + assetId);
        if (!SCI_CommonUtils.checkAssetIdAuthorisation(assetId))
            return '{"statusCode":403}';

        System.debug('AM_AssetService getAsset after authorization');

        return getAssetData(assetId);
    }

    @AuraEnabled(cacheable=true)
    public static String getSignalsTimeSeries(String assetId) {
        if (!SCI_CommonUtils.checkAssetIdAuthorisation(assetId))
            return '{"statusCode":403}';

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');

        String endpoint =
            'callout:AM_Services/asset/api/1/assets/' +
            EncodingUtil.urlEncode(assetId, 'UTF-8') +
            '/signalsTimeSeries';

        request.setEndpoint(endpoint);

        System.debug('GET: ' + endpoint);

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 200) {
            return response.getBody();
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
        //return AM_AssetService_GetSignalsTSMock.SIGNALS_TIME_SERIES;
    }

    public static String getSignalsTimeSeriesDetails(Integer streamId) {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('callout:AM_Services/asset/api/1/signalsTimeSeries/' + streamId);
        System.debug('GET: ' + 'callout:AM_Services/asset/api/1/signalsTimeSeries/' + streamId);

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 200) {
            return response.getBody();
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
        //return AM_AssetService_GetSignalsTSDetailsMock.SIGNALS_TIME_SERIES;
    }

    @AuraEnabled(cacheable=true)
    public static String getValuesTimeSeries(String assetId) {
        if (!SCI_CommonUtils.checkAssetIdAuthorisation(assetId))
            return '{"statusCode":403}';

        HttpRequest request = new HttpRequest();
        request.setMethod('GET');

        String endpoint =
            'callout:AM_Services/asset/api/1/assets/' +
            EncodingUtil.urlEncode(assetId, 'UTF-8') +
            '/valuesTimeSeries';

        request.setEndpoint(endpoint);
        System.debug('GET: ' + endpoint);

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 200) {
            System.debug('getValuesTimeSeries for assetId response body: ' + response.getBody());
            return response.getBody();
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
        //return AM_AssetService_GetValuesTSMock.VALUES_TIME_SERIES;
    }

    public static String getValuesTimeSeriesDetails(Integer streamId) {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint('callout:AM_Services/asset/api/1/valuesTimeSeries/' + streamId);
        System.debug('GET: ' + 'callout:AM_Services/asset/api/1/valuesTimeSeries/' + streamId);

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 200) {
            return response.getBody();
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
        //return AM_AssetService_GetValuesTSDetailsMock.VALUES_TIME_SERIES;
    }

    public static String getValuesTimeSeriesFor(Integer[] streams) {
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setEndpoint('callout:AM_Services/asset/api/1/valuesTimeSeries/get');
        request.setHeader('Content-Type', 'application/json');

        String body = JSON.serialize(streams);
        request.setBody(body);

        HttpResponse response = new Http().send(request);

        if (response.getStatusCode() == 200) {
            return response.getBody();
        }

        return '{"statusCode":' + response.getStatusCode() + '}';
    }
}