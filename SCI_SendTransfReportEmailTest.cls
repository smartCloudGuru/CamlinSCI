@isTest
private class SCI_SendTransfReportEmailTest {
    @testSetup
    static void initTests() {
        SCI_CommonUtilsMocks.initUserRolesForTesting();
    }

    @isTest
    static void test() {
        Transformer__c t1, t2;
        Transformer_Report_Request__c trr1, trr2;
        Transformer_Report__c tr1, tr2;

        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateAssetMock());

        Test.startTest();

        System.runAs(SCI_CommonUtilsMocks.getDefaultCustomerUserForTesting()) {
            Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
            Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();

            t1 = new Transformer__c(Name = 'TR1', Company__c = company.Id, Location__c = location.Id);
            insert t1;

            trr1 = new Transformer_Report_Request__c(
                Name = 'Test1',
                Transformer__c = t1.Id,
                Report_Type__c = 'Overall report',
                Company__c = company.Id
            );
            insert trr1;

            t2 = new Transformer__c(Name = 'TR2', Company__c = company.Id, Location__c = location.Id);
            insert t2;

            trr2 = new Transformer_Report_Request__c(
                Name = 'Test2',
                Transformer__c = t2.Id,
                Report_Type__c = 'DGA only report',
                Company__c = company.Id
            );
            insert trr2;
        }

        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            List<PermissionSet> permSet = [SELECT Id FROM PermissionSet WHERE Name = 'Connected_Insights_Backoffice'];

            System.assert(!permSet.isEmpty());

            PermissionSetAssignment psa = new PermissionSetAssignment(
                PermissionSetId = permSet[0].Id,
                AssigneeId = UserInfo.getUserId()
            );
            insert psa;

            tr1 = new Transformer_Report__c(Name = 'Test1', Transformer_Report_Request__c = trr1.Id);
            insert tr1;
            tr2 = new Transformer_Report__c(Name = 'Test2', Transformer_Report_Request__c = trr2.Id);
            insert tr2;

            List<ID> trList = new List<ID>();
            trList.add(tr1.Id);
            trList.add(tr2.Id);

            System.assertEquals(0, Limits.getEmailInvocations());

            boolean exceptionThrown = false;

            try {
                SCI_SendTransfReportEmail.sendEmails(new List<ID>());
            } catch (IllegalArgumentException e) {
                exceptionThrown = true;
            }

            System.assert(exceptionThrown);
            System.assertEquals(0, Limits.getEmailInvocations());

            SCI_SendTransfReportEmail.sendEmails(trList);

            List<Site> site = [SELECT Id FROM Site WHERE UrlPathPrefix = 'connectedInsights' LIMIT 1];

            System.assertEquals(site.isEmpty() ? 0 : 2, Limits.getEmailInvocations());
        }

        Test.stopTest();
    }
}