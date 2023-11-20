@isTest
private class SCI_CommonUtilsTest {
    @testSetup
    static void initTests() {
        SCI_CommonUtilsMocks.initUserRolesForTesting();
        SCI_CommonUtilsMocks.initUserGroupsForTesting();
    }

    @isTest
    static void test_escapeSymbols() {
        System.assertEquals('', SCI_CommonUtils.escapeSymbols(''));
        System.assertEquals('_', SCI_CommonUtils.escapeSymbols(' '));
        System.assertEquals('_', SCI_CommonUtils.escapeSymbols('_'));
        System.assertEquals('__', SCI_CommonUtils.escapeSymbols(' \n'));
        System.assertEquals('_apos_', SCI_CommonUtils.escapeSymbols('\''));
        System.assertEquals('_at_', SCI_CommonUtils.escapeSymbols('@'));
        System.assertEquals('__at__', SCI_CommonUtils.escapeSymbols('_@_'));
        System.assertEquals(
            '_apos__at__semicolon__colon__dQuote__equal__hash__perc__qMark__slash_',
            SCI_CommonUtils.escapeSymbols('\'@;:"=#%?/')
        );
    }

    @isTest
    static void test_restoreSymbols() {
        System.assertEquals('', SCI_CommonUtils.restoreSymbols(''));
        System.assertEquals('_', SCI_CommonUtils.restoreSymbols('_'));
        System.assertEquals('@', SCI_CommonUtils.restoreSymbols('_at_'));
        System.assertEquals('_@_', SCI_CommonUtils.restoreSymbols('__at__'));
        System.assertEquals(
            '\'@;:"=#%?/',
            SCI_CommonUtils.restoreSymbols('_apos__at__semicolon__colon__dQuote__equal__hash__perc__qMark__slash_')
        );
    }

    @isTest
    static void test_getLocationId() {
        boolean exceptionOccured = false;

        try {
            SCI_CommonUtils.getLocationId(null, 'companyId');
        } catch (Exception e) {
            exceptionOccured = true;
        }

        System.assert(exceptionOccured);

        exceptionOccured = false;

        try {
            SCI_CommonUtils.getLocationId('', 'companyId');
        } catch (Exception e) {
            exceptionOccured = true;
        }

        System.assert(exceptionOccured);

        exceptionOccured = false;

        try {
            SCI_CommonUtils.getLocationId(' ', 'companyId');
        } catch (Exception e) {
            exceptionOccured = true;
        }

        System.assert(exceptionOccured);

        System.assertEquals('locationId', SCI_CommonUtils.getLocationId('locationId', null));
        System.assertEquals('locationId', SCI_CommonUtils.getLocationId('locationId', ''));
        System.assertEquals('locationId', SCI_CommonUtils.getLocationId('locationId', ' '));
        System.assertEquals('locationId;companyId', SCI_CommonUtils.getLocationId('locationId', 'companyId'));
    }

    @isTest
    static void test_getAssetId() {
        boolean exceptionOccured = false;

        try {
            SCI_CommonUtils.getAssetId(null, 'locationId');
        } catch (Exception e) {
            exceptionOccured = true;
        }

        System.assert(exceptionOccured);

        exceptionOccured = false;

        try {
            SCI_CommonUtils.getAssetId('', 'locationId');
        } catch (Exception e) {
            exceptionOccured = true;
        }

        System.assert(exceptionOccured);

        exceptionOccured = false;

        try {
            SCI_CommonUtils.getAssetId(' ', 'locationId');
        } catch (Exception e) {
            exceptionOccured = true;
        }

        System.assert(exceptionOccured);

        exceptionOccured = false;

        try {
            SCI_CommonUtils.getAssetId('serialId', null);
        } catch (Exception e) {
            exceptionOccured = true;
        }

        System.assert(exceptionOccured);

        exceptionOccured = false;

        try {
            SCI_CommonUtils.getAssetId('serialId', '');
        } catch (Exception e) {
            exceptionOccured = true;
        }

        System.assert(exceptionOccured);

        exceptionOccured = false;

        try {
            SCI_CommonUtils.getAssetId('serialId', ' ');
        } catch (Exception e) {
            exceptionOccured = true;
        }

        System.assert(exceptionOccured);

        System.assertEquals('serialId@locationId', SCI_CommonUtils.getAssetId('serialId', 'locationId'));
    }

    @isTest
    static void test_getUserCompanyId() {
        Test.startTest();

        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            System.assert(SCI_CommonUtils.getUserCompanyId() == null);
        }

        System.runAs(SCI_CommonUtilsMocks.getDefaultCustomerUserForTesting()) {
            System.assertEquals(SCI_CommonUtilsMocks.COMPANY_ID, SCI_CommonUtils.getUserCompanyId());
        }

        Test.stopTest();
    }

    @isTest
    static void test_getUserRoleName() {
        Test.startTest();

        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            System.assertEquals('CEO', SCI_CommonUtils.getUserRoleName());
        }

        Test.stopTest();
    }

    @isTest
    static void test_isCurrentUserMemberOfGroup() {
        Test.startTest();

        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            Group g = [SELECT Id, Name FROM Group WHERE Name = :SCI_Constants.CAMLIN_USERS_PUBLIC_GROUP];
            User user = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
            GroupMember gm = new GroupMember(GroupId = g.Id, UserOrGroupId = user.Id);

            Database.UpsertResult upsertResult = Database.upsert(gm, false);

            for (Database.Error err : upsertResult.getErrors()) {
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
            }

            System.assert(upsertResult.isSuccess());

            System.assert(SCI_CommonUtils.isCurrentUserMemberOfGroup(SCI_Constants.CAMLIN_USERS_PUBLIC_GROUP));
            System.assert(!SCI_CommonUtils.isCurrentUserMemberOfGroup('Unexistent'));
        }

        Test.stopTest();
    }

    @isTest
    static void test_isCurrentUserMemberOfPermissionSet() {
        Test.startTest();

        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'Connected_Insights_Internal'];
            PermissionSetAssignment psa = new PermissionSetAssignment(
                PermissionSetId = permSet.Id,
                AssigneeId = UserInfo.getUserId()
            );
            insert psa;

            System.assert(SCI_CommonUtils.isCurrentUserMemberOfPermissionSet('Connected_Insights_Internal'));
            System.assert(!SCI_CommonUtils.isCurrentUserMemberOfPermissionSet('Unexistent'));
        }

        Test.stopTest();
    }

    @isTest
    static void test_isCurrentUserMemberOfCiPermSets_Connected_Insights_Internal() {
        Test.startTest();

        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'Connected_Insights_Internal'];
            PermissionSetAssignment psa = new PermissionSetAssignment(
                PermissionSetId = permSet.Id,
                AssigneeId = UserInfo.getUserId()
            );
            insert psa;

            System.assert(SCI_CommonUtils.isCurrentUserMemberOfCiPermSets());
        }

        Test.stopTest();
    }

    @isTest
    static void test_isCurrentUserMemberOfCiPermSets_Connected_Insights_SME() {
        Test.startTest();

        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            PermissionSet permSet = [SELECT Id FROM PermissionSet WHERE Name = 'Connected_Insights_SME'];
            PermissionSetAssignment psa = new PermissionSetAssignment(
                PermissionSetId = permSet.Id,
                AssigneeId = UserInfo.getUserId()
            );
            insert psa;

            System.assert(SCI_CommonUtils.isCurrentUserMemberOfCiPermSets());
        }

        Test.stopTest();
    }

    @isTest
    static void test_getCompany() {
        Test.startTest();

        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);

        System.assertEquals(company.Id, SCI_CommonUtils.getCompany(SCI_CommonUtilsMocks.COMPANY_ID).Id);
        System.assertEquals(null, SCI_CommonUtils.getCompany('Unexistent'));
        System.assertEquals(null, SCI_CommonUtils.getCompany(''));
        System.assertEquals(null, SCI_CommonUtils.getCompany(null));

        Test.stopTest();
    }

    @isTest
    static void test_getLocation() {
        Test.startTest();

        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);

        Asset_Location__c location = new Asset_Location__c(
            Name = 'Location',
            Company__c = company.Id,
            Site_ID__c = 'SiteId'
        );
        insert location;

        Account foundCompany = SCI_CommonUtils.getCompany(SCI_CommonUtilsMocks.COMPANY_ID);
        Asset_Location__c foundLocation = SCI_CommonUtils.getLocation('SiteId;' + SCI_CommonUtilsMocks.COMPANY_ID);
        System.assertEquals(location.Id, foundLocation.Id);
        System.assertEquals(null, SCI_CommonUtils.getLocation('SiteId;Unexistent'));
        System.assertEquals(null, SCI_CommonUtils.getLocation(''));
        System.assertEquals(null, SCI_CommonUtils.getLocation(null));

        Test.stopTest();
    }

    @isTest
    static void test_checkCircuitBreakerExistence() {
        Test.startTest();

        Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);

        Asset_Location__c location = new Asset_Location__c(
            Name = 'Location',
            Company__c = company.Id,
            Site_ID__c = 'SiteId'
        );
        insert location;

        Circuit_Breaker__c cb = new Circuit_Breaker__c(
            Name = 'CB 1',
            Company__c = company.Id,
            Location__c = location.Id,
            Circuit_Breaker_ID__c = 'CB_1'
        );
        insert cb;

        System.assert(SCI_CommonUtils.checkCircuitBreakerExistence('CB_1@SiteId;' + SCI_CommonUtilsMocks.COMPANY_ID));
        System.assert(!SCI_CommonUtils.checkCircuitBreakerExistence('CB_2@SiteId;' + SCI_CommonUtilsMocks.COMPANY_ID));
        System.assert(!SCI_CommonUtils.checkCircuitBreakerExistence('CB_1@Site;' + SCI_CommonUtilsMocks.COMPANY_ID));
        System.assert(!SCI_CommonUtils.checkCircuitBreakerExistence('CB_1@SiteId;Unexistent'));
        System.assert(!SCI_CommonUtils.checkCircuitBreakerExistence(''));
        System.assert(!SCI_CommonUtils.checkCircuitBreakerExistence(null));

        Test.stopTest();
    }

    @isTest
    static void test_checkAssetIdAuthorisation_withCustomerUser() {
        Test.startTest();

        System.runAs(SCI_CommonUtilsMocks.getDefaultCustomerUserForTesting()) {
            Account company = SCI_CommonUtils.getCompany(SCI_CommonUtils.getUserCompanyId());

            Asset_Location__c location = new Asset_Location__c(Name = 'Location', Company__c = company.Id);
            insert location;

            Circuit_Breaker__c cb = new Circuit_Breaker__c(
                Name = 'CB 1',
                Company__c = company.Id,
                Location__c = location.Id,
                Circuit_Breaker_ID__c = 'CB_1'
            );
            insert cb;

            String locationId = SCI_CommonUtils.getLocationId('Location', SCI_CommonUtilsMocks.COMPANY_ID);
            System.assert(SCI_CommonUtils.checkAssetIdAuthorisation(SCI_CommonUtils.getAssetId('CB_1', locationId)));
            System.assert(!SCI_CommonUtils.checkAssetIdAuthorisation('Unexistent'));
        }

        Test.stopTest();
    }

    @isTest
    static void test_checkAssetIdAuthorisation_withInternalUser() {
        Test.startTest();

        System.runAs(SCI_CommonUtilsMocks.getUserForTesting(null, null, null)) {
            Account company = SCI_CommonUtilsMocks.getDefaultCompany(false);

            Asset_Location__c location = new Asset_Location__c(Name = 'Location', Company__c = company.Id);
            insert location;

            Circuit_Breaker__c cb = new Circuit_Breaker__c(
                Name = 'CB 1',
                Company__c = company.Id,
                Location__c = location.Id,
                Circuit_Breaker_ID__c = 'CB_1'
            );
            insert cb;

            System.assert(!SCI_CommonUtils.checkAssetIdAuthorisation(cb.Asset_ID__c));
        }

        Test.stopTest();
    }

    @isTest
    static void test_listUsersOfGroup() {
        boolean exceptionOccured = false;

        try {
            SCI_CommonUtils.listUsersOfGroup(null);
        } catch (Exception e) {
            exceptionOccured = true;
        }

        System.assert(exceptionOccured);

        exceptionOccured = false;

        try {
            SCI_CommonUtils.listUsersOfGroup(' ');
        } catch (Exception e) {
            exceptionOccured = true;
        }

        System.assert(exceptionOccured);

        Test.startTest();

        System.runAs(SCI_CommonUtilsMocks.getDefaultUserForTesting()) {
            Group g = [SELECT Id, Name FROM Group WHERE Name = :SCI_Constants.BACKOFFICE_USERS_PUBLIC_GROUP];
            GroupMember gm = new GroupMember(GroupId = g.Id, UserOrGroupId = UserInfo.getUserId());

            System.assert(SCI_CommonUtils.listUsersOfGroup(SCI_Constants.BACKOFFICE_USERS_PUBLIC_GROUP).size() >= 1);
            System.assertEquals(0, SCI_CommonUtils.listUsersOfGroup('Unexistent').size());
        }

        Test.stopTest();
    }
}