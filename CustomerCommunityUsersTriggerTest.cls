@isTest
private class CustomerCommunityUsersTriggerTest {
    @testSetup
    static void initTests() {
        SCI_CommonUtilsMocks.initUserRolesForTesting();
    }

    @isTest
    static void testUserWithAccountId() {
        Test.startTest();

        System.runAs(SCI_CommonUtilsMocks.getDefaultPortalOwner()) {
            Contact contact = SCI_CommonUtilsMocks.getDefaultContactForTesting();

            //Create user
            Profile portalProfile = SCI_CommonUtilsMocks.getDefaultPortalProfile();
            User user = new User(
                Alias = 'TestUser',
                Email = 'testuser@mytestorg.com',
                EmailEncodingKey = 'UTF-8',
                LastName = 'Testing',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                ProfileId = portalProfile.Id,
                TimeZoneSidKey = 'Europe/Rome',
                UserName = 'testuser@mytestorg.com',
                ContactId = contact.Id
            );

            Database.SaveResult insertResult = Database.insert(user, false);

            for (Database.Error err : insertResult.getErrors()) {
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
            }

            System.assert(insertResult.isSuccess());

            user = [SELECT Id, CompanyName FROM User WHERE Id = :insertResult.Id];
            System.assertEquals(SCI_CommonUtilsMocks.COMPANY_ID, user.CompanyName);
        }

        Test.stopTest();
    }

    @isTest
    static void testUserWithoutAccountId() {
        Test.startTest();

        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);

        Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
        User user = new User(
            Alias = 'TestUser',
            Email = 'testuser@mytestorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'Europe/Rome',
            UserName = 'testuser@mytestorg.com'
        );

        Database.SaveResult result = Database.insert(user, false);
        System.assert(result.isSuccess());

        user = [SELECT Id, CompanyName FROM User WHERE Id = :result.Id];
        System.assertEquals(null, user.CompanyName);

        Test.stopTest();
    }
}