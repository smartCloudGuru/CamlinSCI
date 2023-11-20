@isTest
private class AM_AssetServiceTest {
    private static String ASSET_UUID = '123e4567-e89b-42d3-a456-556642440000';

    @testSetup
    static void initTests() {
        SCI_CommonUtilsMocks.initUserRolesForTesting();
    }

    @isTest
    static void test_createAsset() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateAssetMock());

            Test.startTest();

            String assetId = 'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID;
            String result = AM_AssetService.createAsset(
                assetId,
                ASSET_UUID,
                'Transformer',
                'TrType',
                'TST002-000054',
                '{"serialNumber":1234567890}'
            );
            System.assertEquals('', result);

            result = AM_AssetService.createAsset(assetId, ASSET_UUID, 'CircuitBreaker', '', '', '');
            System.assertEquals('{"statusCode":400}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_getAssetData() {
        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_GetAssetMock());

        Test.startTest();

        String result = AM_AssetService.getAssetData('TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID);
        System.assert(!result.startsWith('{"statusCode":'));

        result = AM_AssetService.getAssetData('NotExistent@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID);
        System.assertEquals('{"statusCode":404}', result);

        Test.stopTest();
    }

    @isTest
    static void test_createDeviceLinkup() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateDeviceLinkupMock());

            Test.startTest();

            String assetId = 'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID;
            String result = AM_AssetService.createDeviceLinkup(assetId, 'TTM9', null, null, null, '{}');
            System.assertEquals('', result);

            result = AM_AssetService.createDeviceLinkup('TTM9/1', 'TTM9', 1234567890L, null, 1, '{}');
            System.assertEquals('{"statusCode":400}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_importCsvCircuitBreakers() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsSubjectMatterExpert();
            Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
            Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();
            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_ImportCsvCBsCallout(200));

            Test.startTest();
            String result = AM_AssetService.importCsvCircuitBreakers('', SCI_CommonUtilsMocks.COMPANY_ID);
            System.assert(result.startsWith('{"statusCode":200'));
            System.assert(result.contains('succeeded'));
            Test.stopTest();
        }
    }

    @isTest
    static void test_importCsvCircuitBreakersBadRequest() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsSubjectMatterExpert();
            Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
            Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();
            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_ImportCsvCBsCallout(400));

            Test.startTest();
            String result = AM_AssetService.importCsvCircuitBreakers('', SCI_CommonUtilsMocks.COMPANY_ID);
            System.assert(result.startsWith('{"statusCode":400'));
            Test.stopTest();
        }
    }

    @isTest
    static void test_importCsvCircuitBreakersInternalServerError() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsSubjectMatterExpert();
            Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
            Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();
            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_ImportCsvCBsCallout(500));

            Test.startTest();
            String result = AM_AssetService.importCsvCircuitBreakers('', SCI_CommonUtilsMocks.COMPANY_ID);
            System.assert(result.startsWith('{"statusCode":500'));
            Test.stopTest();
        }
    }

    @isTest
    static void test_importCsvCircuitBreakersNotASubjectMatterExpert() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
            Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();
            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_ImportCsvCBsCallout(500));

            Test.startTest();
            String result = AM_AssetService.importCsvCircuitBreakers('', SCI_CommonUtilsMocks.COMPANY_ID);
            System.assert(result.startsWith('{"statusCode":403'));
            Test.stopTest();
        }
    }

    @isTest
    static void test_createTOTUSDevice() {
        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
        Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();

        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateAssetMock());

        Transformer__c tr = new Transformer__c(
            Name = 'Luca',
            Serial_Number__c = '1234567890',
            Location__c = location.Id,
            Company__c = company.Id
        );
        insert tr;

        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateDeviceLinkupMock());

        Test.startTest();

        TOTUS_Device__c td = new TOTUS_Device__c(
            Name = 'Connection to TTM9',
            Transformer__c = tr.Id,
            TOTUS_Serial_ID__c = 'TTM9',
            Is_Multitank__c = true,
            DGA_Source_A__c = 'Main_Tank',
            DGA_Source_B__c = 'LTC_Selector_Phase_A',
            DGA_Source_C__c = 'LTC_Selector_Phase_B',
            Load_Sensor_Installation_Side__c = 'HV'
        );
        insert td;

        AM_AssetService.createTOTUSDevice(td.Id);

        Test.stopTest();
    }

    @isTest
    static void test_removeTOTUSDevice() {
        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
        Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();

        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateAssetMock());

        Transformer__c tr = new Transformer__c(
            Name = 'Luca',
            Serial_Number__c = '1234567890',
            Location__c = location.Id,
            Company__c = company.Id
        );
        insert tr;

        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateDeviceLinkupMock());

        Test.startTest();

        TOTUS_Device__c td = new TOTUS_Device__c(
            Name = 'Connection to TTM9',
            Transformer__c = tr.Id,
            TOTUS_Serial_ID__c = 'TTM9'
        );
        insert td;

        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_RemoveDeviceLinkupMock());

        AM_AssetService.removeTOTUSDevice(td.Id);

        Test.stopTest();
    }

    @isTest
    static void test_createTransformer() {
        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
        Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();

        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateAssetMock());

        Test.startTest();

        OEM__c transformerOEM = new OEM__c(Name = 'Tozzi Ltd', Equipment_Type__c = 'Transformer');
        insert transformerOEM;

        OEM__c detcOEM = new OEM__c(Name = 'Tozzi Ltd', Equipment_Type__c = 'DETC');
        insert detcOEM;

        OEM__c oltcOEM = new OEM__c(Name = 'Tozzi Ltd', Equipment_Type__c = 'OLTC');
        insert oltcOEM;

        OEM__c bushingOEM = new OEM__c(Name = 'Tozzi Ltd', Equipment_Type__c = 'Bushing');
        insert bushingOEM;

        Transformer__c tr = new Transformer__c(
            Name = 'TTM9',
            Company__c = company.Id,
            Location__c = location.Id,
            Equipment_Number__c = 'Antani',
            Serial_Number__c = '1234567890',
            Manufacturing_Year__c = 1978,
            Installation_Year__c = 1980,
            Transformer_OEM__c = transformerOEM.Id,
            Grid_Frequency__c = '50',
            Number_of_Phases__c = '3',
            Number_of_Windings__c = '3',
            Tertiary__c = 'Y',
            Load_Losses_FAT__c = 5,
            No_Load_Losses_FAT__c = 3,
            Number_of_cooling_stages__c = '2',
            External_Cooling__c = 'WF',
            Internal_Cooling__c = 'KF',
            Oil_Type__c = 'Mineral',
            Oil_Protection_System__c = 'Membrane_Bladder',
            DETC_OEM__c = detcOEM.Id,
            DETC_Installation_Side__c = 'HV',
            OLTC_Installation_Side__c = 'TV',
            OLTC_OEM__c = oltcOEM.Id,
            OLTC_Diverter_Switch_Design__c = 'Unknown',
            OLTC_Diverter_Switch_Technology__c = 'Vacuum',
            OLTC_Installation_Position__c = 'External',
            OLTC_Switching_Type__c = 'Reactor',
            OLTC_Type__c = 'OLTC',
            Max_Rating__c = 12345,
            Rated_Voltage_HV__c = 100,
            Rated_Voltage_LV1__c = 2,
            Rated_Voltage_LV2__c = 2,
            Rated_Voltage_TV__c = 10,
            HV_Bushing_Manufacturing_Year__c = 2000,
            HV_Bushing_Type__c = 'SP',
            HV_Bushing_OEM__c = bushingOEM.Id,
            Bushing_HV_Rated_Current__c = 12.3,
            LV1_Bushing_Manufacturing_Year__c = 2000,
            LV1_Bushing_Type__c = 'SP',
            LV1_Bushing_OEM__c = bushingOEM.Id,
            Bushing_LV1_Rated_Current__c = 12.3,
            LV2_Bushing_Manufacturing_Year__c = 2000,
            LV2_Bushing_Type__c = 'SP',
            LV2_Bushing_OEM__c = bushingOEM.Id,
            Bushing_LV2_Rated_Current__c = 12.3,
            TV_Bushing_Manufacturing_Year__c = 2000,
            TV_Bushing_Type__c = 'SP',
            TV_Bushing_OEM__c = bushingOEM.Id,
            Bushing_TV_Rated_Current__c = 12.3
        );
        insert tr;

        AM_AssetService.createTransformer(tr.Id);

        Test.stopTest();
    }

    @isTest
    static void test_mergeAssetProperties() {
        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_MergeAssetMock());

        Test.startTest();

        JSONGenerator jsonGen = JSON.createGenerator(false);
        jsonGen.writeStartObject();
        jsonGen.writeNumberField('installationYear', 1980);
        jsonGen.writeNumberField('manufacturingYear', 1978);
        jsonGen.writeEndObject();

        AM_AssetService.mergeAssetProperties('AnAssetId', jsonGen.getAsString());

        Test.stopTest();
    }

    @isTest
    static void test_getAsset() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_GetAssetMock());

            Test.startTest();

            String result = AM_AssetService.getAsset('CBF@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID);
            System.assert(!result.startsWith('{"statusCode":'));

            result = AM_AssetService.getAsset('Not_Existent');
            System.assertEquals('{"statusCode":404}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_getAssetWithAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultCustomerUserForTesting()) {
            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_GetAssetMock());

            Test.startTest();

            String result = AM_AssetService.getAsset('CBF@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID);
            System.assert(!result.startsWith('{"statusCode":'));

            Test.stopTest();
        }
    }

    @isTest
    static void test_getAssetWithoutAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getUserForTesting('Inactive Users', 'Standard User', 'Another')) {
            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_GetAssetMock());

            Test.startTest();

            String result = AM_AssetService.getAsset('CBF@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID);
            System.assertEquals('{"statusCode":403}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_createValuesTimeSeries() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateValuesTSMock());

            Test.startTest();

            String assetId = 'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID;
            String result = AM_AssetService.createValuesTimeSeries(assetId, 'DGA/H2', 'Number', '{"chartable":true}');
            System.assert(result != null && result.length() > 0);

            result = AM_AssetService.createAsset(assetId, ASSET_UUID, 'Transformer', 'DGA/N2', 'Antani', '{}');
            System.assertEquals('{"statusCode":400}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_getSignalsTimeSeries() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_GetSignalsTSMock());

            Test.startTest();

            String result = AM_AssetService.getSignalsTimeSeries('CBF@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID);
            System.assert(!result.startsWith('{"statusCode":'));

            result = AM_AssetService.getSignalsTimeSeries('Not_Existent');
            System.assertEquals('{"statusCode":404}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_getSignalsTimeSeriesWithAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultCustomerUserForTesting()) {
            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_GetSignalsTSMock());

            Test.startTest();

            String result = AM_AssetService.getSignalsTimeSeries('CBF@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID);
            System.assert(!result.startsWith('{"statusCode":'));

            Test.stopTest();
        }
    }

    @isTest
    static void test_getSignalsTimeSeriesWithoutAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getUserForTesting('Inactive Users', 'Standard User', 'Another')) {
            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_GetSignalsTSMock());

            Test.startTest();

            String result = AM_AssetService.getSignalsTimeSeries('CBF@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID);
            System.assertEquals('{"statusCode":403}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_getSignalsTimeSeriesDetails() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_GetSignalsTSDetailsMock());

            Test.startTest();

            String result = AM_AssetService.getSignalsTimeSeriesDetails(100);
            System.assert(!result.startsWith('{"statusCode":'));

            result = AM_AssetService.getSignalsTimeSeriesDetails(0);
            System.assertEquals('{"statusCode":404}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_getValuesTimeSeries() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_GetValuesTSMock());

            Test.startTest();

            String result = AM_AssetService.getValuesTimeSeries(
                'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID
            );
            System.assert(!result.startsWith('{"statusCode":'));

            result = AM_AssetService.getValuesTimeSeries('Not_Existent');
            System.assertEquals('{"statusCode":404}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_getValuesTimeSeriesWithAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultCustomerUserForTesting()) {
            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_GetValuesTSMock());

            Test.startTest();

            String result = AM_AssetService.getValuesTimeSeries(
                'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID
            );
            System.assert(!result.startsWith('{"statusCode":'));

            Test.stopTest();
        }
    }

    @isTest
    static void test_getValuesTimeSeriesWithoutAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getUserForTesting('Inactive Users', 'Standard User', 'Another')) {
            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_GetValuesTSMock());

            Test.startTest();

            String result = AM_AssetService.getValuesTimeSeries(
                'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID
            );
            System.assertEquals('{"statusCode":403}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_getValuesTimeSeriesDetails() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_GetValuesTSDetailsMock());

            Test.startTest();

            String result = AM_AssetService.getValuesTimeSeriesDetails(1000);
            System.assert(!result.startsWith('{"statusCode":'));

            result = AM_AssetService.getValuesTimeSeriesDetails(0);
            System.assertEquals('{"statusCode":404}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_removeDeviceLinkup() {
        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_RemoveDeviceLinkupMock());

        Test.startTest();

        String result = AM_AssetService.removeDeviceLinkup(
            'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID,
            'TTM9',
            1234567890L,
            Datetime.now().getTime()
        );
        System.assert(!result.startsWith('{"statusCode":'));

        result = AM_AssetService.removeDeviceLinkup(
            'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID,
            'TTM9',
            Datetime.now().getTime(),
            null
        );
        System.assert(!result.startsWith('{"statusCode":'));

        result = AM_AssetService.removeDeviceLinkup(
            'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID,
            'TTM9',
            null,
            Datetime.now().getTime()
        );
        System.assert(!result.startsWith('{"statusCode":'));

        result = AM_AssetService.removeDeviceLinkup(
            'Not_existent@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID,
            'TTM9',
            Datetime.now().getTime(),
            null
        );
        System.assertEquals('{"statusCode":404}', result);

        Test.stopTest();
    }

    @isTest
    static void test_updateStartAndEndTime() {
        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_UpdateStartEndTimeMock());

        Test.startTest();

        AM_AssetService.updateStartAndEndTime('TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID, 1234567890L);

        Test.stopTest();
    }

    @isTest
    static void test_updateTimeSeriesMinMaxValues() {
        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_UpdateMinMaxValueMock());

        Test.startTest();

        AM_AssetService.updateTimeSeriesMinMaxValues(12345, (Double) 42.0);

        Test.stopTest();
    }

    @isTest
    static void test_updateDeviceLinkupActivationTime() {
        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_UpdateDeviceLinkupMock());

        Test.startTest();

        String result = AM_AssetService.updateDeviceLinkupActivationTime(
            'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID,
            'TTM9',
            Datetime.now().getTime(),
            1234567890L
        );
        System.assert(!result.startsWith('{"statusCode":'));

        result = AM_AssetService.updateDeviceLinkupActivationTime(
            'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID,
            'TTM9',
            Datetime.now().getTime(),
            null
        );
        System.assertEquals('{"statusCode":400}', result);

        result = AM_AssetService.updateDeviceLinkupActivationTime(
            'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID,
            'TTM9',
            null,
            Datetime.now().getTime()
        );
        System.assert(!result.startsWith('{"statusCode":'));

        result = AM_AssetService.updateDeviceLinkupActivationTime(
            'Not_existent@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID,
            'TTM9',
            Datetime.now().getTime(),
            1234567890L
        );
        System.assertEquals('{"statusCode":404}', result);

        Test.stopTest();
    }

    @isTest
    static void test_updateDeviceLinkupDeactivationTime() {
        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_UpdateDeviceLinkupMock());

        Test.startTest();

        String result = AM_AssetService.updateDeviceLinkupDeactivationTime(
            'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID,
            'TTM9',
            1234567890L,
            Datetime.now().getTime()
        );
        System.assert(!result.startsWith('{"statusCode":'));

        result = AM_AssetService.updateDeviceLinkupDeactivationTime(
            'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID,
            'TTM9',
            Datetime.now().getTime(),
            null
        );
        System.assertEquals('{"statusCode":400}', result);

        result = AM_AssetService.updateDeviceLinkupDeactivationTime(
            'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID,
            'TTM9',
            null,
            Datetime.now().getTime()
        );
        System.assert(!result.startsWith('{"statusCode":'));

        result = AM_AssetService.updateDeviceLinkupDeactivationTime(
            'Not_existent@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID,
            'TTM9',
            1234567890L,
            Datetime.now().getTime()
        );
        System.assertEquals('{"statusCode":404}', result);

        Test.stopTest();
    }

    @isTest
    static void test_mergeDeviceLinkupProperties() {
        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_MergeDeviceLinkupMock());

        Test.startTest();

        JSONGenerator jsonGen = JSON.createGenerator(false);
        jsonGen.writeStartObject();
        jsonGen.writeFieldName('dga');
        jsonGen.writeStartObject();
        jsonGen.writeStringField('dgaSourceA', 'Main_Tank');
        jsonGen.writeEndObject();
        jsonGen.writeEndObject();

        String result = AM_AssetService.mergeDeviceLinkupProperties(
            'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID,
            'TTM9',
            Datetime.now().getTime(),
            null,
            jsonGen.getAsString()
        );
        System.assert(!result.startsWith('{"statusCode":'));

        result = AM_AssetService.mergeDeviceLinkupProperties(
            'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID,
            'TTM9',
            Datetime.now().getTime(),
            null,
            null
        );
        System.assert(!result.startsWith('{"statusCode":'));

        result = AM_AssetService.mergeDeviceLinkupProperties(
            'Not_existent@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID,
            'TTM9',
            Datetime.now().getTime(),
            null,
            jsonGen.getAsString()
        );
        System.assertEquals('{"statusCode":404}', result);

        Test.stopTest();
    }

    @isTest
    static void test_updateTOTUSDeviceActivationTime() {
        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
        Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();

        Test.startTest();

        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateAssetMock());

        Transformer__c tr = new Transformer__c(
            Name = 'Luca',
            Serial_Number__c = '1234567890',
            Location__c = location.Id,
            Company__c = company.Id
        );
        insert tr;

        TOTUS_Device__c td = new TOTUS_Device__c(
            Name = 'Connection to TTM9',
            Transformer__c = tr.Id,
            TOTUS_Serial_ID__c = 'TTM9'
        );
        insert td;

        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_UpdateDeviceLinkupMock());

        AM_AssetService.updateTOTUSDeviceActivationTime(tr.Id, 'TTM9', Datetime.now(), null);

        Test.stopTest();
    }

    @isTest
    static void test_updateTOTUSDeviceDeactivationTime() {
        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
        Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();

        Test.startTest();

        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateAssetMock());

        Transformer__c tr = new Transformer__c(
            Name = 'Luca',
            Serial_Number__c = '1234567890',
            Location__c = location.Id,
            Company__c = company.Id
        );
        insert tr;

        TOTUS_Device__c td = new TOTUS_Device__c(
            Name = 'Connection to TTM9',
            Transformer__c = tr.Id,
            TOTUS_Serial_ID__c = 'TTM9'
        );
        insert td;

        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_UpdateDeviceLinkupMock());

        AM_AssetService.updateTOTUSDeviceDeactivationTime(tr.Id, 'TTM9', Datetime.now(), null);

        Test.stopTest();
    }

    @isTest
    static void test_updateTOTUSDeviceProperties() {
        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
        Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();

        Test.startTest();

        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateAssetMock());

        Transformer__c tr = new Transformer__c(
            Name = 'Luca',
            Serial_Number__c = '1234567890',
            Location__c = location.Id,
            Company__c = company.Id
        );
        insert tr;

        TOTUS_Device__c td = new TOTUS_Device__c(
            Name = 'Connection to TTM9',
            Transformer__c = tr.Id,
            TOTUS_Serial_ID__c = 'TTM9'
        );
        insert td;

        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_MergeDeviceLinkupMock());

        JSONGenerator jsonGen = JSON.createGenerator(false);
        jsonGen.writeStartObject();
        jsonGen.writeFieldName('dga');
        jsonGen.writeStartObject();
        jsonGen.writeStringField('dgaSourceA', 'Main_Tank');
        jsonGen.writeEndObject();
        jsonGen.writeEndObject();

        AM_AssetService.updateTOTUSDeviceProperties(tr.Id, 'TTM9', Datetime.now(), null, jsonGen.getAsString());

        Test.stopTest();
    }

    @isTest
    static void test_updateTransformerProperties() {
        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
        Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();

        Test.startTest();

        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateAssetMock());

        Transformer__c tr = new Transformer__c(
            Name = 'TST002-000054@BOLOGNA;' + SCI_CommonUtilsMocks.COMPANY_ID,
            Serial_Number__c = '1234567890',
            Location__c = location.Id,
            Company__c = company.Id
        );
        insert tr;

        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_MergeAssetMock());

        JSONGenerator jsonGen = JSON.createGenerator(false);
        jsonGen.writeStartObject();
        jsonGen.writeNumberField('installationYear', 1980);
        jsonGen.writeNumberField('manufacturingYear', 1978);
        jsonGen.writeEndObject();

        AM_AssetService.updateTransformerProperties(
            'TST002-000054@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID,
            jsonGen.getAsString()
        );

        AM_AssetService.updateTransformerProperties(
            'Not_existent@SUGAR;' + SCI_CommonUtilsMocks.COMPANY_ID,
            jsonGen.getAsString()
        );

        Test.stopTest();
    }
}