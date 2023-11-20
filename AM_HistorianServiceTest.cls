@isTest
private class AM_HistorianServiceTest {
    @testSetup
    static void initTests() {
        SCI_CommonUtilsMocks.initUserRolesForTesting();
    }

    @isTest
    static void test_getSignalDetails() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_GetSignalDetailsMock());

            Test.startTest();

            String result = AM_HistorianService.getSignalDetails(3);
            System.assert(!result.startsWith('{"statusCode":'));

            result = AM_HistorianService.getSignalDetails(0);
            System.assertEquals('{"statusCode":404}', result);

            result = AM_HistorianService.getSignalDetails(99999);
            System.assertEquals('{"statusCode":403}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_getSignal() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.getSignal(100, 1302084312000L);
            System.assert(!result.startsWith('{"statusCode":'));

            result = AM_HistorianService.getSignal(100, 42);
            System.assertEquals('{"statusCode":404}', result);

            result = AM_HistorianService.getSignal(0, 42);
            System.assertEquals('{"statusCode":404}', result);

            result = AM_HistorianService.getSignal(99999, 42);
            System.assertEquals('{"statusCode":403}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_getSignalWithAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultCustomerUserForTesting()) {
            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.getSignal(100, 1302084312000L);
            System.assert(!result.startsWith('{"statusCode":'));

            result = AM_HistorianService.getSignal(99999, 42);
            System.assertEquals('{"statusCode":403}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_getSignalWithoutAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getUserForTesting('Inactive Users', 'Standard User', 'Another')) {
            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.getSignal(100, 1302084312000L);
            System.assertEquals('{"statusCode":403}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_getSignals() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.getSignals(100, null, null);
            System.assert(!result.startsWith('{"statusCode":'));

            result = AM_HistorianService.getSignals(100, 0, 42);
            System.assert(!result.startsWith('{"statusCode":'));

            result = AM_HistorianService.getSignals(0, 0, 42);
            System.assertEquals('{"statusCode":404}', result);

            result = AM_HistorianService.getSignals(99999, 0, 42);
            System.assertEquals('{"statusCode":403}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_getSignalsWithAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultCustomerUserForTesting()) {
            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.getSignals(100, null, null);
            System.assert(!result.startsWith('{"statusCode":'));

            result = AM_HistorianService.getSignals(100, 0, 42);
            System.assert(!result.startsWith('{"statusCode":'));

            Test.stopTest();
        }
    }

    @isTest
    static void test_getSignalsWithoutAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getUserForTesting('Inactive Users', 'Standard User', 'Another')) {
            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.getSignals(100, null, null);
            System.assertEquals('{"statusCode":403}', result);

            result = AM_HistorianService.getSignals(100, 0, 42);
            System.assertEquals('{"statusCode":403}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_getWaveforms() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.getWaveforms(3, null, null, null, null);
            System.assert(!result.startsWith('{"statusCode":'));
            List<Object> waveforms = (List<Object>) JSON.deserializeUntyped(result);
            System.assertEquals(6.0, waveforms.size());

            result = AM_HistorianService.getWaveforms(3, new List<String>{ 'Current' }, 0, 42, 42);
            System.assert(!result.startsWith('{"statusCode":'));
            waveforms = (List<Object>) JSON.deserializeUntyped(result);
            System.assertEquals(1.0, waveforms.size());

            result = AM_HistorianService.getWaveforms(0, null, null, null, null);
            System.assertEquals('{"statusCode":404}', result);

            result = AM_HistorianService.getWaveforms(99999, null, null, null, null);
            System.assertEquals('{"statusCode":403}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_getWaveformsWithAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultCustomerUserForTesting()) {
            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.getWaveforms(3, null, null, null, null);
            System.assert(!result.startsWith('{"statusCode":'));
            List<Object> waveforms = (List<Object>) JSON.deserializeUntyped(result);
            System.assertEquals(6.0, waveforms.size());

            result = AM_HistorianService.getWaveforms(3, new List<String>{ 'Current' }, 0, 42, 42);
            System.assert(!result.startsWith('{"statusCode":'));
            waveforms = (List<Object>) JSON.deserializeUntyped(result);
            System.assertEquals(1.0, waveforms.size());

            Test.stopTest();
        }
    }

    @isTest
    static void test_getWaveformsWithoutAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getUserForTesting('Inactive Users', 'Standard User', 'Another')) {
            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.getWaveforms(3, null, null, null, null);
            System.assertEquals('{"statusCode":403}', result);

            result = AM_HistorianService.getWaveforms(3, new List<String>{ 'Current' }, 0, 42, 42);
            System.assertEquals('{"statusCode":403}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_getCursorValues() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.getCursorValues(
                new List<Integer>{ 1000, 1001, 1002 },
                1234567890,
                1000
            );
            System.assert(!result.startsWith('{"statusCode":'));
            Map<String, Object> outcomeMap = (Map<String, Object>) JSON.deserializeUntyped(result);
            System.assertEquals(2, outcomeMap.keySet().size());

            result = AM_HistorianService.getCursorValues(new List<Integer>{ 99999 }, 1234567890, null);
            System.assert(result.equals('{"statusCode":403}'));

            Test.stopTest();
        }
    }

    @isTest
    static void test_getCursorValuesWithAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultCustomerUserForTesting()) {
            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.getCursorValues(
                new List<Integer>{ 1000, 1001, 1002 },
                1234567890,
                null
            );
            System.assert(!result.startsWith('{"statusCode":'));
            Map<String, Object> outcomeMap = (Map<String, Object>) JSON.deserializeUntyped(result);
            System.assertEquals(2, outcomeMap.keySet().size());

            Test.stopTest();
        }
    }

    @isTest
    static void test_getUserAuthorizationStatusWithPermToConnectedInsights() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            Test.startTest();

            List<Integer> streams = new List<Integer>{ 1000, 1001, 1002 };

            String result = AM_HistorianService.getUserAuthorizationStatus(streams);

            System.assertEquals('{"statusCode": 200 }', result, 'should return success code');

            Test.stopTest();
        }
    }

    @isTest
    static void test_getUserAuthorizationStatusWithoutCIPermsAndAuthorizedForTheAssets() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultCustomerUserForTesting()) {
            Test.startTest();

            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_GetValuesTimeSeriesMock());

            List<Integer> streams = new List<Integer>{ 1000, 1001, 1002 };

            String result = AM_HistorianService.getUserAuthorizationStatus(streams);

            System.assertEquals('{"statusCode": 200 }', result, 'should return success code');

            Test.stopTest();
        }
    }

    @isTest
    static void test_getUserAuthorizationStatusWithoutCIPermsAndRetrievesBadResponse() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultCustomerUserForTesting()) {
            Test.startTest();

            System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_GetValuesTimeSeriesMock());

            List<Integer> streams = new List<Integer>{ 1001, 1002 };

            String result = AM_HistorianService.getUserAuthorizationStatus(streams);

            System.assertEquals('{"statusCode":500}', result, 'should return status code 500, bad response form middleware');

            Test.stopTest();
        }
    }

    @isTest
    static void test_getCursorValuesWithoutAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getUserForTesting('Inactive Users', 'Standard User', 'Another')) {
            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.getCursorValues(
                new List<Integer>{ 1000, 1001, 1002 },
                1234567890,
                1000
            );
            System.assertEquals('{"statusCode":403}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_getStreamData() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.getStreamsData(
                new List<Integer>{ 1000, 1001, 1002 },
                1234567800,
                1234567890,
                1024
            );
            System.assert(!result.startsWith('{"statusCode":'));
            List<Object> outcomeList = (List<Object>) JSON.deserializeUntyped(result);
            System.assertEquals(3, outcomeList.size());

            result = AM_HistorianService.getStreamsData(new List<Integer>{ 99999 }, 1234567800, 1234567890, 1024);
            System.assert(result.equals('{"statusCode":403}'));

            Test.stopTest();
        }
    }

    @isTest
    static void test_getStreamDataWithAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultCustomerUserForTesting()) {
            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.getStreamsData(
                new List<Integer>{ 1000, 1001, 1002 },
                1234567800,
                1234567890,
                1024
            );
            System.assert(!result.startsWith('{"statusCode":'));
            List<Object> outcomeList = (List<Object>) JSON.deserializeUntyped(result);
            System.assertEquals(3, outcomeList.size());

            Test.stopTest();
        }
    }

    @isTest
    static void test_getStreamDataWithoutAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getUserForTesting('Inactive Users', 'Standard User', 'Another')) {
            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.getStreamsData(
                new List<Integer>{ 1000, 1001, 1002 },
                1234567800,
                1234567890,
                1024
            );
            System.assert(result.equals('{"statusCode":403}'));

            Test.stopTest();
        }
    }

    @isTest
    static void test_getSinglePointValues() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();
            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.getSinglePointValues(new List<Integer>{ 1000, 1001, 1002 }, 1234567890);
            System.assert(!result.startsWith('{"statusCode":'));
            Map<String, Object> outcomeMap = (Map<String, Object>) JSON.deserializeUntyped(result);
            System.assertEquals(3, outcomeMap.keySet().size());

            result = AM_HistorianService.getSinglePointValues(new List<Integer>{ 1000, 99999 }, 1234567890);
            System.assert(result.equals('{"statusCode":403}'));

            Test.stopTest();
        }
    }

    @isTest
    static void test_getSinglePointValuesWithAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultCustomerUserForTesting()) {
            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.getSinglePointValues(new List<Integer>{ 1000, 1001, 1002 }, 1234567890);
            System.assert(!result.startsWith('{"statusCode":'));
            Map<String, Object> outcomeMap = (Map<String, Object>) JSON.deserializeUntyped(result);
            System.assertEquals(3, outcomeMap.keySet().size());

            Test.stopTest();
        }
    }

    @isTest
    static void test_getSinglePointValuesWithoutAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getUserForTesting('Inactive Users', 'Standard User', 'Another')) {
            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.getSinglePointValues(new List<Integer>{ 1000, 1001, 1002 }, 1234567890);
            System.assertEquals('{"statusCode":403}', result);

            Test.stopTest();
        }
    }

    @isTest
    static void test_storeSinglePointValues() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();
            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.storeSinglePointValues(
                1234567890,
                '{"number":{"1000":12.3,"1001":45},"string":{"1002":"Antani"},"boolean":{"1003":true}}'
            );
            System.assert(!result.startsWith('{"statusCode":'));

            result = AM_HistorianService.storeSinglePointValues(1234567890, '{"string":{"99999":"Antani"}}');
            System.assert(result.equals('{"statusCode":403}'));

            Test.stopTest();
        }
    }

    @isTest
    static void test_storeSinglePointValuesWithAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultCustomerUserForTesting()) {
            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.storeSinglePointValues(
                1234567890,
                '{"number":{"1000":12.3,"1001":45},"string":{"1002":"Antani"},"boolean":{"1003":true}}'
            );
            System.assert(!result.startsWith('{"statusCode":'));

            Test.stopTest();
        }
    }

    @isTest
    static void test_storeSinglePointValuesWithoutAuthorisation() {
        System.runAs(SCI_CommonUtilsMocks.getUserForTesting('Inactive Users', 'Standard User', 'Another')) {
            System.Test.setMock(HttpCalloutMock.class, new AM_HistorianService_CalloutMock());

            Test.startTest();

            String result = AM_HistorianService.storeSinglePointValues(
                1234567890,
                '{"number":{"1000":12.3,"1001":45},"string":{"1002":"Antani"},"boolean":{"1003":true}}'
            );
            System.assertEquals('{"statusCode":403}', result);

            Test.stopTest();
        }
    }
}