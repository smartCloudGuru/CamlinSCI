@isTest
private class CustomerCommunityAccountTriggerTest {
    @testSetup
    static void initTests() {
        SCI_CommonUtilsMocks.initUserRolesForTesting();
    }

    @isTest
    static void test_with_already_existing_Company_ID() {
        Test.startTest();

        Account company = SCI_CommonUtilsMocks.getDefaultCompany(true);

        Account newCompany = new Account(
            Name = company.Name,
            BillingStreet = 'Street',
            BillingCity = 'Bologna',
            Region__c = 'Emilia Romagna',
            BillingPostalCode = '12345',
            BillingCountry = 'Italy'
        );
        newCompany.SCI_Enabled__c = true;

        company.Name = 'New Acme';
        update company;

        Database.SaveResult result = Database.insert(newCompany, true);
        System.assert(result.isSuccess());

        company = [SELECT Id, Name, Company_ID__c FROM Account WHERE Id = :company.Id];
        newCompany = [SELECT Id, Name, Company_ID__c FROM Account WHERE Id = :result.Id];
        System.assertNotEquals(null, newCompany.Company_ID__c);
        System.assert(newCompany.Company_ID__c != company.Company_ID__c);
        System.assert(newCompany.Company_ID__c.startsWith(company.Company_ID__c));

        Test.stopTest();
    }

    @isTest
    static void test_NotCustomerCommunityAccount() {
        Test.startTest();

        Account company = new Account(
            Name = SCI_CommonUtilsMocks.COMPANY_ID,
            BillingStreet = 'Street',
            BillingCity = 'Bologna',
            Region__c = 'Emilia Romagna',
            BillingPostalCode = '12345',
            BillingCountry = 'Italy'
        );

        Database.SaveResult result = Database.insert(company, false);
        System.assert(result.isSuccess());

        company = [SELECT Id, Company_ID__c FROM Account WHERE Id = :result.Id];
        System.assertEquals(null, company.Company_ID__c);

        Test.stopTest();
    }
}