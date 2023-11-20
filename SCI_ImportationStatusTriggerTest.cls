@isTest
private class SCI_ImportationStatusTriggerTest {
    private final static String IMP_REQ_ID = 'Terapia-Tapioco';
    private final static String ASSET_CATEGORY = 'CircuitBreaker';
    private final static String SESSION_OR_ASSET_ID = 'CB';
    private final static String STATUS = 'RUNNING';

    @testSetup
    static void initTests() {
        SCI_CommonUtilsMocks.initUserRolesForTesting();
    }

    @isTest
    static void test() {
        Test.startTest();

        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);

        Asset_Importation_Request__c impRequest = new Asset_Importation_Request__c(
            Name = IMP_REQ_ID,
            Company__c = company.Id,
            Asset_Category__c = ASSET_CATEGORY,
            Progress__c = 0,
            Status__c = STATUS
        );
        insert impRequest;

        SCI_Importation_Status_Notification__e event = new SCI_Importation_Status_Notification__e(
            ImportRequestId__c = IMP_REQ_ID,
            Asset_Category__c = ASSET_CATEGORY,
            Status__c = STATUS,
            SerialIdOrAssetId__c = SESSION_OR_ASSET_ID,
            Progress__c = 42
        );

        Database.SaveResult sr = EventBus.publish(event);

        Test.stopTest();

        System.assertEquals(true, sr.isSuccess());

        List<Asset_Importation_Request__c> impRequests = [
            SELECT Name, Company__c, Asset_Category__c, Status__c, SerialIdOrAssetId__c, Progress__c
            FROM Asset_Importation_Request__c
            WHERE Name = :IMP_REQ_ID
        ];

        System.assertEquals(1, impRequests.size());
        System.assertEquals(impRequest.Name, impRequests[0].Name);
        System.assertEquals(impRequest.Company__c, impRequests[0].Company__c);
        System.assertEquals(impRequest.Asset_Category__c, impRequests[0].Asset_Category__c);
        System.assertEquals(STATUS, impRequests[0].Status__c);
        System.assertEquals(SESSION_OR_ASSET_ID, impRequests[0].SerialIdOrAssetId__c);
        System.assertEquals(42, impRequests[0].Progress__c);
    }

    @isTest
    static void test_notMatching() {
        Test.startTest();

        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);

        Asset_Importation_Request__c impRequest = new Asset_Importation_Request__c(
            Name = 'Another One',
            Company__c = company.Id,
            Asset_Category__c = ASSET_CATEGORY,
            Progress__c = 0,
            Status__c = STATUS
        );
        insert impRequest;

        SCI_Importation_Status_Notification__e event = new SCI_Importation_Status_Notification__e(
            ImportRequestId__c = IMP_REQ_ID,
            Asset_Category__c = ASSET_CATEGORY,
            Status__c = STATUS,
            SerialIdOrAssetId__c = SESSION_OR_ASSET_ID,
            Progress__c = 42
        );

        Database.SaveResult sr = EventBus.publish(event);

        Test.stopTest();

        System.assertEquals(true, sr.isSuccess());

        List<Asset_Importation_Request__c> impRequests = [
            SELECT Name, Company__c, Asset_Category__c, Status__c, SerialIdOrAssetId__c, Progress__c
            FROM Asset_Importation_Request__c
            WHERE Name = :IMP_REQ_ID
        ];

        System.assertEquals(0, impRequests.size());
    }
}