@isTest
private class SCI_AssetLocationTriggerTest {
    @testSetup
    static void initTests() {
        SCI_CommonUtilsMocks.initUserRolesForTesting();
    }

    @isTest
    static void test_without_Site_ID() {
        Test.startTest();

        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
        Asset_Location__c location = new Asset_Location__c(Name = 'Location', Company__c = company.Id);
        insert location;

        Asset_Location__c retrievedLocation = [SELECT Site_ID__c FROM Asset_Location__c WHERE Id = :location.Id];

        System.assert(retrievedLocation.Site_ID__c != null);
        System.assert(retrievedLocation.Site_ID__c.startsWith('Location'));

        Test.stopTest();
    }

    @isTest
    static void test_with_Site_ID() {
        Test.startTest();

        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
        Asset_Location__c location = new Asset_Location__c(
            Name = 'Location',
            Company__c = company.Id,
            Site_ID__c = 'Site ID'
        );
        insert location;

        Asset_Location__c retrievedLocation = [SELECT Site_ID__c FROM Asset_Location__c WHERE Id = :location.Id];

        System.assert(retrievedLocation.Site_ID__c != null);
        System.assertEquals('Site ID', retrievedLocation.Site_ID__c);

        Test.stopTest();
    }

    @isTest
    static void test_with_already_existing_Site_ID() {
        Test.startTest();

        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);
        Asset_Location__c location = new Asset_Location__c(Name = 'Location', Company__c = company.Id);
        Asset_Location__c newLocation = new Asset_Location__c(Name = location.Name, Company__c = company.Id);

        insert location;
        location.Name = 'New Location';
        update location;

        Database.SaveResult result = Database.insert(newLocation, true);
        System.assert(result.isSuccess());

        location = [SELECT Id, Name, Site_ID__c FROM Asset_Location__c WHERE Id = :location.Id];
        newLocation = [SELECT Id, Name, Site_ID__c FROM Asset_Location__c WHERE Id = :result.Id];
        System.assertNotEquals(null, newLocation.Site_ID__c);
        System.assert(newLocation.Site_ID__c != location.Site_ID__c);
        System.assert(newLocation.Site_ID__c.startsWith(location.Site_ID__c));

        Test.stopTest();
    }
}