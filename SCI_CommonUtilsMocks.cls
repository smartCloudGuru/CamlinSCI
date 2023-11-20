@isTest
global class SCI_CommonUtilsMocks {
    public final static String COMPANY_ID = 'Acme';

    public static void addUserToConnectedInsightsInternals() {
        List<PermissionSet> permSet = [SELECT Id FROM PermissionSet WHERE Name = 'Connected_Insights_Internal'];
        PermissionSetAssignment psa = new PermissionSetAssignment(
            PermissionSetId = permSet[0].Id,
            AssigneeId = UserInfo.getUserId()
        );
        insert psa;
    }

    public static void addUserToConnectedInsightsSubjectMatterExpert() {
        List<PermissionSet> permSet = [SELECT Id FROM PermissionSet WHERE Name = 'Connected_Insights_SME'];
        PermissionSetAssignment psa = new PermissionSetAssignment(
            PermissionSetId = permSet[0].Id,
            AssigneeId = UserInfo.getUserId()
        );
        insert psa;
    }

    public static Account getDefaultCompany(boolean sciEnabled) {
        List<Account> accountList = [SELECT Id, SCI_Enabled__c FROM Account WHERE Company_ID__c = :COMPANY_ID];

        if (accountList != null && accountList.size() > 0) {
            if (sciEnabled && !accountList[0].SCI_Enabled__c) {
                accountList[0].SCI_Enabled__c = true;

                Database.SaveResult saveResult = Database.update(accountList[0], false);

                for (Database.Error err : saveResult.getErrors()) {
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                }

                System.assert(saveResult.isSuccess());
            }

            return accountList[0];
        }

        Account account = new Account(
            Name = COMPANY_ID,
            Company_ID__c = COMPANY_ID,
            BillingStreet = 'Street',
            BillingCity = 'Bologna',
            Region__c = 'Emilia Romagna',
            BillingPostalCode = '12345',
            BillingCountry = 'Italy'
        );
        account.SCI_Enabled__c = sciEnabled;

        Database.UpsertResult upsertResult = Database.upsert(account, false);

        for (Database.Error err : upsertResult.getErrors()) {
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
        }

        System.assert(upsertResult.isSuccess());

        return account;
    }

    public static Asset_Location__c getDefaultLocation() {
        Account company = getDefaultCompany(false);

        List<Asset_Location__c> assetLocationList = [
            SELECT Name, Site_ID__c
            FROM Asset_Location__c
            WHERE Site_ID__c = 'BOLOGNA' AND Company__c = :company.Id
        ];

        if (assetLocationList != null && assetLocationList.size() > 0) {
            return assetLocationList[0];
        }

        Asset_Location__c al = new Asset_Location__c(Name = 'Bologna', Company__c = company.Id, Site_ID__c = 'BOLOGNA');

        Database.UpsertResult upsertResult = Database.upsert(al, false);

        for (Database.Error err : upsertResult.getErrors()) {
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
        }

        System.assert(upsertResult.isSuccess());

        return al;
    }

    public static UserRole getDefaultUserRole() {
        return [SELECT Id FROM UserRole WHERE Name = 'CEO' LIMIT 1];
    }

    public static User getDefaultUserForTesting() {
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        UserRole userRole = getDefaultUserRole();
        return new User(
            Alias = 'TestUser',
            Email = 'testuser@mytestorg.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'Europe/Rome',
            UserName = 'testuser@mytestorg.com',
            UserRoleId = userRole.Id
        );
    }

    public static User getDefaultPortalOwner() {
        List<User> portalOwnerList = [SELECT Id FROM User WHERE Alias = 'portalow'];

        if (portalOwnerList != null && portalOwnerList.size() > 0) {
            return portalOwnerList[0];
        }

        // Creates portal owner user
        UserRole portalRole = [SELECT Id FROM UserRole WHERE PortalType = 'None' LIMIT 1];
        Profile profile = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1];
        User portalOwner = new User(
            UserRoleId = portalRole.Id,
            ProfileId = profile.Id,
            Username = 'test-portal.owner@camlingroup.com',
            Alias = 'portalow',
            Email = 'test-portal.owner@camlingroup.com',
            EmailEncodingKey = 'UTF-8',
            Firstname = 'Portal',
            Lastname = 'Owner',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            TimeZoneSidKey = 'America/Chicago'
        );

        Database.UpsertResult upsertResult = Database.upsert(portalOwner, false);

        for (Database.Error err : upsertResult.getErrors()) {
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
        }

        System.assert(upsertResult.isSuccess());

        return portalOwner;
    }

    public static Profile getDefaultPortalProfile() {
        return [SELECT Id FROM Profile WHERE Name = 'Customer Community Plus User' LIMIT 1];
    }

    public static Contact getDefaultContactForTesting() {
        Database.UpsertResult upsertResult;

        User portalOwner = getDefaultPortalOwner();

        Contact contact;
        System.runAs(portalOwner) {
            List<Account> portalAccountList = [SELECT Id FROM Account WHERE Company_ID__c = :COMPANY_ID];

            Account portalAccount;
            if (portalAccountList != null && portalAccountList.size() > 0) {
                portalAccount = portalAccountList[0];
            } else {
                // Creates portal account
                portalAccount = new Account(
                    Name = COMPANY_ID,
                    Company_ID__c = COMPANY_ID,
                    SCI_Enabled__c = true,
                    OwnerId = portalOwner.Id,
                    BillingStreet = 'Street',
                    BillingCity = 'Bologna',
                    Region__c = 'Emilia Romagna',
                    BillingPostalCode = '12345',
                    BillingCountry = 'Italy'
                );

                upsertResult = Database.upsert(portalAccount, false);

                for (Database.Error err : upsertResult.getErrors()) {
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                }

                System.assert(upsertResult.isSuccess());
            }

            List<Contact> contactList = [
                SELECT Id
                FROM Contact
                WHERE Email = 'test.mctesty@test.com' AND AccountId = :portalAccount.Id
            ];

            if (contactList != null && contactList.size() > 0) {
                contact = contactList[0];
            } else {
                // Creates contact
                contact = new Contact(
                    FirstName = 'Test',
                    Lastname = 'McTesty',
                    AccountId = portalAccount.Id,
                    Email = 'test.mctesty@test.com'
                );

                upsertResult = Database.upsert(contact, false);

                for (Database.Error err : upsertResult.getErrors()) {
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                }

                System.assert(upsertResult.isSuccess());
            }
        }

        return contact;
    }

    public static User getDefaultCustomerUserForTesting() {
        Database.UpsertResult upsertResult;

        User customerUser;
        System.runAs(getDefaultPortalOwner()) {
            Contact contact = getDefaultContactForTesting();

            List<User> customerUserList = [
                SELECT Alias, Email, Username
                FROM User
                WHERE UserName = 'testuser@camlingroup.com'
            ];

            if (customerUserList != null && customerUserList.size() > 0) {
                customerUser = customerUserList[0];
            } else {
                // Creates customer user
                Profile portalProfile = getDefaultPortalProfile();

                customerUser = new User(
                    Alias = 'customer',
                    Email = 'test-customer.user@camlingroup.com',
                    EmailEncodingKey = 'UTF-8',
                    LastName = 'Testing',
                    LanguageLocaleKey = 'en_US',
                    LocaleSidKey = 'en_US',
                    ProfileId = portalProfile.Id,
                    TimeZoneSidKey = 'Europe/Rome',
                    UserName = 'test-customer.user@camlingroup.com',
                    ContactId = contact.Id
                );

                upsertResult = Database.upsert(customerUser, false);

                for (Database.Error err : upsertResult.getErrors()) {
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                }

                System.assert(upsertResult.isSuccess());
            }
        }

        return customerUser;
    }

    public static User getUserForTesting(String userRoleName, String profileName, String companyName) {
        Profile profile = [SELECT Id FROM Profile WHERE Name = :(profileName != null ? profileName : 'Standard User')];
        UserRole userRole = [SELECT Id FROM UserRole WHERE Name = :(userRoleName != null ? userRoleName : 'CEO')];

        return new User(
            Alias = 'testuser',
            Email = 'test-user@camlingroup.com',
            EmailEncodingKey = 'UTF-8',
            LastName = 'Testing',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profile.Id,
            TimeZoneSidKey = 'Europe/Rome',
            UserName = 'test-' + System.currentTimeMillis() + '-user@camlingroup.com',
            CompanyName = (companyName != null ? companyName : COMPANY_ID),
            UserRoleId = userRole.Id
        );
    }

    private static void initBackofficeUsersGroupForTesting() {
        String defaultBackofficeUserAlias = 'backoffi';
        List<User> backOfficeUsers = [SELECT Alias FROM User WHERE Alias = :defaultBackofficeUserAlias];

        if (backOfficeUsers == null || backOfficeUsers.size() == 0) {
            UserRole userRole = getDefaultUserRole();
            Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
            User backofficeUser = new User(
                UserRoleId = userRole.Id,
                ProfileId = profile.Id,
                Username = 'test-backoffice.user@camlingroup.com',
                Alias = defaultBackofficeUserAlias,
                Email = 'test-backoffice.user@camlingroup.com',
                EmailEncodingKey = 'UTF-8',
                Firstname = 'Back',
                Lastname = 'Office',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Chicago'
            );

            Database.UpsertResult upsertResult = Database.upsert(backofficeUser, false);

            for (Database.Error err : upsertResult.getErrors()) {
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
            }

            System.assert(upsertResult.isSuccess());
        }

        Group g = [SELECT Id, Name FROM Group WHERE Name = :SCI_Constants.BACKOFFICE_USERS_PUBLIC_GROUP];
        User backofficeUser = [SELECT Alias FROM User WHERE Alias = :defaultBackofficeUserAlias LIMIT 1];
        GroupMember gm = new GroupMember(GroupId = g.Id, UserOrGroupId = backOfficeUser.Id);

        Database.UpsertResult upsertResult = Database.upsert(gm, false);

        for (Database.Error err : upsertResult.getErrors()) {
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
        }

        System.assert(upsertResult.isSuccess());
    }

    private static void initCamlinUsersGroupForTesting() {
        String defaultCamlinUserAlias = 'camuser';
        List<User> camlinUsers = [SELECT Alias FROM User WHERE Alias = :defaultCamlinUserAlias];

        if (camlinUsers == null || camlinUsers.size() == 0) {
            UserRole userRole = getDefaultUserRole();
            Profile profile = [SELECT Id FROM Profile WHERE Name = 'Standard User'];
            User camlinUser = new User(
                UserRoleId = userRole.Id,
                ProfileId = profile.Id,
                Username = 'test-camlin.user@camlingroup.com',
                Alias = defaultCamlinUserAlias,
                Email = 'test-camlin.user@camlingroup.com',
                EmailEncodingKey = 'UTF-8',
                Firstname = 'Camlin',
                Lastname = 'Default',
                LanguageLocaleKey = 'en_US',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'America/Chicago'
            );

            Database.UpsertResult upsertResult = Database.upsert(camlinUser, false);

            for (Database.Error err : upsertResult.getErrors()) {
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
            }

            System.assert(upsertResult.isSuccess());
        }

        Group g = [SELECT Id, Name FROM Group WHERE Name = :SCI_Constants.CAMLIN_USERS_PUBLIC_GROUP];
        User camlinUser = [SELECT Alias FROM User WHERE Alias = :defaultCamlinUserAlias LIMIT 1];
        GroupMember gm = new GroupMember(GroupId = g.Id, UserOrGroupId = camlinUser.Id);

        Database.UpsertResult upsertResult = Database.upsert(gm, false);

        for (Database.Error err : upsertResult.getErrors()) {
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
        }

        System.assert(upsertResult.isSuccess());
    }

    public static void initUserGroupsForTesting() {
        List<User> users = SCI_CommonUtils.listUsersOfGroup(SCI_Constants.BACKOFFICE_USERS_PUBLIC_GROUP);

        if (users == null || users.size() == 0) {
            initBackofficeUsersGroupForTesting();
        }

        users = SCI_CommonUtils.listUsersOfGroup(SCI_Constants.CAMLIN_USERS_PUBLIC_GROUP);

        if (users == null || users.size() == 0) {
            initCamlinUsersGroupForTesting();
        }
    }

    public static void initUserRolesForTesting() {
        List<UserRole> userRoles = [SELECT Id FROM UserRole WHERE Name = 'Inactive Users'];

        if (userRoles == null || userRoles.size() == 0) {
            UserRole userRole = new UserRole(Name = 'Inactive Users');

            Database.UpsertResult upsertResult = Database.upsert(userRole, false);

            for (Database.Error err : upsertResult.getErrors()) {
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
            }

            System.assert(upsertResult.isSuccess());
        }

        userRoles = [SELECT Id FROM UserRole WHERE Name = 'CEO'];

        if (userRoles == null || userRoles.size() == 0) {
            UserRole userRole = new UserRole(Name = 'CEO');

            Database.UpsertResult upsertResult = Database.upsert(userRole, false);

            for (Database.Error err : upsertResult.getErrors()) {
                System.debug(err.getStatusCode() + ': ' + err.getMessage());
            }

            System.assert(upsertResult.isSuccess());
        }
    }
}