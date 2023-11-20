@isTest
private class SCI_ContentDocumentServiceTest {
    private static String FILE_TITLE = 'Test File' + DateTime.now();

    private static ContentDocumentLink addFileToRecord(Id recordId) {
        ContentVersion cv = new ContentVersion(
            Description = 'Test File Description',
            PathOnClient = 'test_file.txt',
            Title = FILE_TITLE,
            Versiondata = Blob.valueOf('Test file body'),
            IsMajorVersion = true
        );
        insert cv;
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'I',
            LinkedEntityId = recordId
        );
        insert cdl;

        return cdl;
    }

    private static Transformer_Report_Request__c createTransformerReportRequest() {
        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
        Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();

        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateAssetMock());

        Transformer__c t = new Transformer__c(
            Name = 'TR1',
            Company__c = company.Id,
            Location__c = location.Id,
            Transformer_ID__c = 'TR-12345'
        );
        insert t;

        Transformer_Report_Request__c trr = new Transformer_Report_Request__c(
            Name = 'Test1',
            Transformer__c = t.Id,
            Report_Type__c = 'Overall report',
            Company__c = company.Id
        );
        insert trr;

        return trr;
    }

    @testSetup
    static void initTests() {
        SCI_CommonUtilsMocks.initUserRolesForTesting();
    }

    @isTest
    static void test_getRelatedDocs() {
        Test.startTest();

        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            Transformer_Report_Request__c trr = createTransformerReportRequest();

            System.assert(SCI_ContentDocumentService.getRelatedDocs(trr.Id).isEmpty());

            addFileToRecord(trr.Id);

            List<ContentDocumentLink> cdlOutcome = SCI_ContentDocumentService.getRelatedDocs(trr.Id);
            System.assertEquals(1, cdlOutcome.size());
            System.assertEquals(FILE_TITLE, cdlOutcome[0].ContentDocument.Title);
        }

        Test.stopTest();
    }

    @isTest
    static void test_getDocVersionId() {
        Test.startTest();

        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            Transformer_Report_Request__c trr = createTransformerReportRequest();

            addFileToRecord(trr.Id);

            List<ContentDocumentLink> cdlOutcome = SCI_ContentDocumentService.getRelatedDocs(trr.Id);
            System.assertEquals(1, cdlOutcome.size());
            System.assert(SCI_ContentDocumentService.getDocVersionId(cdlOutcome[0].ContentDocument.Id) != null);
        }

        Test.stopTest();
    }

    @isTest
    static void test_deleteDoc() {
        Test.startTest();

        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            SCI_CommonUtilsMocks.addUserToConnectedInsightsInternals();

            Transformer_Report_Request__c trr = createTransformerReportRequest();

            System.assert(SCI_ContentDocumentService.getRelatedDocs(trr.Id).isEmpty());

            ContentDocumentLink cdl = addFileToRecord(trr.Id);

            List<ContentDocumentLink> cdlOutcome = SCI_ContentDocumentService.getRelatedDocs(trr.Id);
            System.assertEquals(1, cdlOutcome.size());

            SCI_ContentDocumentService.deleteDoc(cdl.ContentDocumentId);

            cdlOutcome = SCI_ContentDocumentService.getRelatedDocs(trr.Id);
            System.assert(cdlOutcome.isEmpty());
        }

        Test.stopTest();
    }
}