@isTest
private class AM_ImportServiceTest {
    @testSetup
    static void initTests() {
        SCI_CommonUtilsMocks.initUserRolesForTesting();
    }

    @isTest
    static void test_getAssetRecordId_circuitBreaker() {
        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
        Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();

        Circuit_Breaker__c asset = new Circuit_Breaker__c(
            Name = 'Luca',
            Circuit_Breaker_ID__c = 'Full_Stack_Developer',
            Company__c = company.Id,
            Location__c = location.Id
        );
        insert asset;

        System.assertEquals(
            ('"' +
            asset.Id +
            '"'),
            AM_ImportService.getAssetRecordId(
                SCI_CommonUtilsMocks.COMPANY_ID,
                'CircuitBreaker',
                location.Site_ID__c,
                'Full_Stack_Developer'
            )
        );

        System.assertEquals(
            null,
            AM_ImportService.getAssetRecordId(
                'Unexistent',
                'CircuitBreaker',
                location.Site_ID__c,
                'Full_Stack_Developer'
            )
        );
        System.assertEquals(
            null,
            AM_ImportService.getAssetRecordId(
                SCI_CommonUtilsMocks.COMPANY_ID,
                'Wrong',
                location.Site_ID__c,
                'Full_Stack_Developer'
            )
        );
        System.assertEquals(
            null,
            AM_ImportService.getAssetRecordId(
                SCI_CommonUtilsMocks.COMPANY_ID,
                'CircuitBreaker',
                'Unexistent',
                'Full_Stack_Developer'
            )
        );
        System.assertEquals(
            null,
            AM_ImportService.getAssetRecordId(
                SCI_CommonUtilsMocks.COMPANY_ID,
                'CircuitBreaker',
                location.Site_ID__c,
                'Unexistent'
            )
        );
    }

    @isTest
    static void test_getAssetRecordId_transformer() {
        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateAssetMock());

        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
        Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();

        Transformer__c asset = new Transformer__c(
            Name = 'TR12345',
            Location__c = location.Id,
            Company__c = company.Id,
            Transformer_ID__c = 'TR-12345'
        );
        insert asset;

        System.assertEquals(
            ('"' +
            asset.Id +
            '"'),
            AM_ImportService.getAssetRecordId(
                SCI_CommonUtilsMocks.COMPANY_ID,
                'Transformer',
                location.Site_ID__c,
                asset.Transformer_ID__c
            )
        );

        System.assertEquals(
            null,
            AM_ImportService.getAssetRecordId('Unexistent', 'Transformer', location.Site_ID__c, asset.Transformer_ID__c)
        );
        System.assertEquals(
            null,
            AM_ImportService.getAssetRecordId(
                SCI_CommonUtilsMocks.COMPANY_ID,
                'Wrong',
                location.Site_ID__c,
                asset.Transformer_ID__c
            )
        );
        System.assertEquals(
            null,
            AM_ImportService.getAssetRecordId(
                SCI_CommonUtilsMocks.COMPANY_ID,
                'Transformer',
                'Unexistent',
                asset.Transformer_ID__c
            )
        );
        System.assertEquals(
            null,
            AM_ImportService.getAssetRecordId(
                SCI_CommonUtilsMocks.COMPANY_ID,
                'Transformer',
                location.Site_ID__c,
                'Unexistent'
            )
        );
    }

    @isTest
    static void test_getAssetLocationRecordId() {
        Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();

        System.assertEquals(
            ('"' +
            location.Id +
            '"'),
            AM_ImportService.getAssetLocationRecordId(SCI_CommonUtilsMocks.COMPANY_ID, 'BOLOGNA')
        );

        System.assertEquals(null, AM_ImportService.getAssetLocationRecordId('Unexistent', 'BOLOGNA'));
        System.assertEquals(
            null,
            AM_ImportService.getAssetLocationRecordId(SCI_CommonUtilsMocks.COMPANY_ID, 'Unexistent')
        );
    }

    @isTest
    static void test_getImportationStatus() {
        String impReqId = '1234567890';

        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);

        Asset_Importation_Request__c impRequest = new Asset_Importation_Request__c(
            Name = impReqId,
            Company__c = company.Id,
            Asset_Category__c = 'CircutBreaker',
            Progress__c = 0,
            Status__c = 'RUNNING',
            SerialIdOrAssetId__c = 'TTM9'
        );
        insert impRequest;

        System.assert(AM_ImportService.getImportationStatus(SCI_CommonUtilsMocks.COMPANY_ID, impReqId) != null);
        System.assert(AM_ImportService.getImportationStatus('Unexistent', impReqId) == null);
        System.assert(AM_ImportService.getImportationStatus(SCI_CommonUtilsMocks.COMPANY_ID, 'xxx') == null);
    }

    @isTest
    static void test_importRecFileWithoutSubstation() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);

            Test.startTest();

            System.Test.setMock(HttpCalloutMock.class, new AM_ImportService_ImportRecFileMock());
            String result = AM_ImportService.importRecFile(
                SCI_CommonUtilsMocks.COMPANY_ID,
                'filename.rec',
                'xxx',
                'Europe/Rome',
                3600,
                1616112000000L,
                'BOLOGNA',
                'Luca',
                'Full Stack Developer',
                'Windows 10'
            );
            System.assert(!result.startsWith('{"statusCode":'));

            Test.stopTest();
        }
    }

    @isTest
    static void test_importRecFileWithoutAsset() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();

            Test.startTest();

            System.Test.setMock(HttpCalloutMock.class, new AM_ImportService_ImportRecFileMock());
            String result = AM_ImportService.importRecFile(
                SCI_CommonUtilsMocks.COMPANY_ID,
                'filename.rec',
                'xxx',
                'Europe/Rome',
                3600,
                1616112000000L,
                'BOLOGNA',
                'Luca',
                'Full Stack Developer',
                'Windows 10'
            );
            System.assert(!result.startsWith('{"statusCode":'));

            Test.stopTest();
        }
    }

    @isTest
    static void test_importRecFile() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
            Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();

            Circuit_Breaker__c asset = new Circuit_Breaker__c(
                Name = 'Luca',
                Circuit_Breaker_ID__c = 'Full_Stack_Developer',
                Location__c = location.Id,
                Company__c = company.Id
            );
            insert asset;

            Test.startTest();

            System.Test.setMock(HttpCalloutMock.class, new AM_ImportService_ImportRecFileMock());
            String result = AM_ImportService.importRecFile(
                SCI_CommonUtilsMocks.COMPANY_ID,
                'filename.rec',
                'xxx',
                'Europe/Rome',
                3600,
                1616112000000L,
                'BOLOGNA',
                'Luca',
                'Full Stack Developer',
                'Windows 10'
            );
            System.assert(!result.startsWith('{"statusCode":'));

            boolean exceptionOccured = false;
            try {
                result = AM_ImportService.importRecFile(
                    SCI_CommonUtilsMocks.COMPANY_ID,
                    null,
                    'xxx',
                    'Europe/Rome',
                    3600,
                    1616112000000L,
                    'BOLOGNA',
                    'Luca',
                    'Full Stack Developer',
                    'Windows 10'
                );
            } catch (Exception e) {
                exceptionOccured = true;
            }
            System.assert(exceptionOccured);

            try {
                result = AM_ImportService.importRecFile(
                    null,
                    'filename.rec',
                    'xxx',
                    'Europe/Rome',
                    3600,
                    1616112000000L,
                    'BOLOGNA',
                    'Luca',
                    'Full Stack Developer',
                    'Windows 10'
                );
            } catch (Exception e) {
                exceptionOccured = true;
            }
            System.assert(exceptionOccured);

            Test.stopTest();
        }
    }

    @isTest
    static void test_importRecFileWithEmptyParameters() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);

            Test.startTest();

            System.Test.setMock(HttpCalloutMock.class, new AM_ImportService_ImportRecFileMock());
            String result = AM_ImportService.importRecFile(
                SCI_CommonUtilsMocks.COMPANY_ID,
                'filename.rec',
                'xxx',
                'Europe/Rome',
                null,
                null,
                'BOLOGNA',
                'Luca',
                null,
                null
            );
            System.assert(result.startsWith('{"statusCode":500}'));

            boolean exceptionOccured = false;
            try {
                result = AM_ImportService.importRecFile(null, null, null, null, null, null, null, null, null, null);
            } catch (IllegalArgumentException e) {
                exceptionOccured = true;
            }
            System.assert(exceptionOccured);

            Test.stopTest();
        }
    }

    @isTest
    static void test_importRecxFileWithoutSubstation() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);

            Test.startTest();

            System.Test.setMock(HttpCalloutMock.class, new AM_ImportService_ImportRecFileMock());
            String result = AM_ImportService.importRecxFile(
                SCI_CommonUtilsMocks.COMPANY_ID,
                'filename.recx',
                'xxx',
                'Europe/Rome',
                3600,
                1616112000000L,
                'BOLOGNA',
                'Luca',
                'Full Stack Developer',
                'Windows 10'
            );
            System.assert(!result.startsWith('{"statusCode":'));

            Test.stopTest();
        }
    }

    @isTest
    static void test_importRecxFileWithoutAsset() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();

            Test.startTest();

            System.Test.setMock(HttpCalloutMock.class, new AM_ImportService_ImportRecFileMock());
            String result = AM_ImportService.importRecxFile(
                SCI_CommonUtilsMocks.COMPANY_ID,
                'filename.recx',
                'xxx',
                'Europe/Rome',
                3600,
                1616112000000L,
                'BOLOGNA',
                'Luca',
                'Full Stack Developer',
                'Windows 10'
            );
            System.assert(!result.startsWith('{"statusCode":'));

            Test.stopTest();
        }
    }

    @isTest
    static void test_importRecxFile() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
            Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();

            Circuit_Breaker__c asset = new Circuit_Breaker__c(
                Name = 'Luca',
                Circuit_Breaker_ID__c = 'Full_Stack_Developer',
                Location__c = location.Id,
                Company__c = company.Id
            );
            insert asset;

            Test.startTest();

            System.Test.setMock(HttpCalloutMock.class, new AM_ImportService_ImportRecFileMock());
            String result = AM_ImportService.importRecxFile(
                SCI_CommonUtilsMocks.COMPANY_ID,
                'filename.recx',
                'xxx',
                'Europe/Rome',
                3600,
                1616112000000L,
                'BOLOGNA',
                'Luca',
                'Full Stack Developer',
                'Windows 10'
            );
            System.assert(!result.startsWith('{"statusCode":'));

            Test.stopTest();
        }
    }

    @isTest
    static void test_importRecxFileWithEmptyParameters() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);

            Test.startTest();

            System.Test.setMock(HttpCalloutMock.class, new AM_ImportService_ImportRecFileMock());
            String result = AM_ImportService.importRecxFile(
                SCI_CommonUtilsMocks.COMPANY_ID,
                'filename.recx',
                'xxx',
                'Europe/Rome',
                null,
                null,
                'BOLOGNA',
                'Luca',
                null,
                null
            );
            System.assert(result.startsWith('{"statusCode":'));

            Test.stopTest();

            boolean exceptionOccured = false;
            try {
                result = AM_ImportService.importRecxFile(null, null, null, null, null, null, null, null, null, null);
            } catch (IllegalArgumentException e) {
                exceptionOccured = true;
            }
            System.assert(exceptionOccured);
        }
    }

    @isTest
    static void test_validateRecFile() {
        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);

            Test.startTest();

            System.Test.setMock(HttpCalloutMock.class, new AM_ImportService_ValidateRecFileMock());
            String result = AM_ImportService.validateRecFile(
                SCI_CommonUtilsMocks.COMPANY_ID,
                'BOLOGNA',
                'Luca',
                'Full Stack Developer',
                'Windows 10',
                'Europe/Rome',
                3600,
                1616112000000L
            );
            System.assert(!result.startsWith('{"statusCode":'));

            result = AM_ImportService.validateRecFile(
                SCI_CommonUtilsMocks.COMPANY_ID,
                null,
                null,
                null,
                null,
                null,
                null,
                null
            );
            System.assert(result.startsWith('{"statusCode":500}'));

            Test.stopTest();
        }
    }
}