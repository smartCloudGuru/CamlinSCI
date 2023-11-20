@isTest
private class SCI_SendTransfReportRequestEmailTest {
    @testSetup
    static void initTests() {
        SCI_CommonUtilsMocks.initUserRolesForTesting();
        SCI_CommonUtilsMocks.initUserGroupsForTesting();
    }

    @isTest
    static void test() {
        System.Test.setMock(HttpCalloutMock.class, new AM_AssetService_CreateAssetMock());

        Test.startTest();

        System.runAs(SCI_CommonUtilsMocks.getDefaultCustomerUserForTesting()) {
            Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
            Asset_Location__c location = SCI_CommonUtilsMocks.getDefaultLocation();

            Transformer__c t1 = new Transformer__c(
                Name = 'TR1',
                Company__c = company.Id,
                Location__c = location.Id,
                Transformer_ID__c = 'TR-12345'
            );
            insert t1;

            Transformer_Report_Request__c trr1 = new Transformer_Report_Request__c(
                Name = 'Test1',
                Transformer__c = t1.Id,
                Report_Type__c = 'Overall report',
                Company__c = company.Id
            );
            insert trr1;

            Transformer__c t2 = new Transformer__c(
                Name = 'TR2',
                Company__c = company.Id,
                Location__c = location.Id,
                Transformer_ID__c = 'TR-12346'
            );
            insert t2;

            Transformer_Report_Request__c trr2 = new Transformer_Report_Request__c(
                Name = 'Test2',
                Transformer__c = t2.Id,
                Report_Type__c = 'DGA only report',
                Company__c = company.Id
            );
            insert trr2;

            List<ID> trrList = new List<ID>();
            trrList.add(trr1.Id);
            trrList.add(trr2.Id);

            System.assertEquals(0, Limits.getEmailInvocations());

            boolean exceptionThrown = false;

            try {
                SCI_SendTransfReportRequestEmail.sendEmails(new List<ID>());
            } catch (IllegalArgumentException e) {
                exceptionThrown = true;
            }

            System.assert(exceptionThrown);
            System.assertEquals(0, Limits.getEmailInvocations());

            SCI_SendTransfReportRequestEmail.sendEmails(trrList);

            System.assertEquals(2, Limits.getEmailInvocations());
        }

        Test.stopTest();
    }
}