public without sharing class SCI_CommonUtils {
    public static String escapeSymbols(String value) {
        return value.replaceAll('\\s', '_')
            .replaceAll('\'', '_apos_')
            .replaceAll('@', '_at_')
            .replaceAll(';', '_semicolon_')
            .replaceAll(':', '_colon_')
            .replaceAll('"', '_dQuote_')
            .replaceAll('=', '_equal_')
            .replaceAll('#', '_hash_')
            .replaceAll('%', '_perc_')
            .replaceAll('\\?', '_qMark_')
            .replaceAll('/', '_slash_');
    }

    public static String restoreSymbols(String value) {
        return value.replaceAll('_apos_', '\'')
            .replaceAll('_at_', '@')
            .replaceAll('_semicolon_', ';')
            .replaceAll('_colon_', ':')
            .replaceAll('_dQuote_', '"')
            .replaceAll('_equal_', '=')
            .replaceAll('_hash_', '#')
            .replaceAll('_perc_', '%')
            .replaceAll('_qMark_', '\\?')
            .replaceAll('_slash_', '/');
    }

    public static String getLocationId(String siteId, String companyId) {
        if (siteId == null || siteId.trim().length() == 0)
            throw new IllegalArgumentException();

        return companyId != null && companyId.trim().length() > 0 ? siteId + ';' + companyId : siteId;
    }

    public static String getAssetId(String serialId, String locationId) {
        if (serialId == null || serialId.trim().length() == 0 || locationId == null || locationId.trim().length() == 0)
            throw new IllegalArgumentException();

        return serialId + '@' + locationId;
    }

    public static String getUserCompanyId() {
        String userId = UserInfo.getUserId();
        List<User> users = [SELECT Id, CompanyName FROM User WHERE Id = :userId AND AccountId != ''];
        return users.size() == 1 ? users[0].CompanyName : null; // CompanyName field, instead of its name, contains Company ID of the user
    }

    public static String getUserRoleName() {
        String roleId = UserInfo.getUserRoleId();
        List<UserRole> userRoles = [SELECT Id, Name FROM UserRole WHERE Id = :roleId];
        return userRoles.size() == 1 ? userRoles[0].Name : null;
    }

    public static boolean isCurrentUserMemberOfGroup(String groupName) {
        return isUserMemberOfGroup(UserInfo.getUserId(), UserInfo.getUserRoleId(), groupName);
    }

    public static boolean isCurrentUserMemberOfPermissionSet(String permissionSetName) {
        String userId = UserInfo.getUserId();
        List<PermissionSetAssignment> permSetAssignments = [
            SELECT Id
            FROM PermissionSetAssignment
            WHERE PermissionSet.Name = :permissionSetName AND AssigneeId = :userId
        ];
        return permSetAssignments.size() == 1;
    }

    private static boolean isUserMemberOfGroup(String userId, String userRoleId, String groupName) {
        // Checks if the user is a direct member of the group
        List<GroupMember> groupMembers = [
            SELECT GroupId
            FROM GroupMember
            WHERE Group.Type = 'Regular' AND Group.Name = :groupName AND UserOrGroupId = :userId
        ];

        if (!groupMembers.isEmpty()) {
            return true;
        }

        // Gets the groups and roles contained into the group
        String[] groupIds = new List<String>();
        for (GroupMember gm : [SELECT UserOrGroupId FROM GroupMember WHERE Group.Name = :groupName]) {
            groupIds.add(gm.UserOrGroupId);
        }

        // Checks if the user's role is one of the contained into the group
        List<Group> groups = [
            SELECT Id
            FROM Group
            WHERE Type LIKE 'Role%' AND Id IN :groupIds AND RelatedId = :userRoleId
        ];

        if (!groups.isEmpty()) {
            return true;
        }

        // Gets the groups contained into the group and checks if user is member of these groups
        for (Group g : [SELECT RelatedId, Name FROM Group WHERE Type = 'Regular' AND Id IN :groupIds]) {
            if (isUserMemberOfGroup(userId, userRoleId, g.Name))
                return true;
        }

        return false;
    }

    public static Account getCompany(String companyName) {
        List<Account> accounts = [SELECT Id FROM Account WHERE Company_ID__c = :companyName];
        return accounts != null && accounts.size() == 1 ? accounts[0] : null;
    }

    public static Asset_Location__c getLocation(String locationId) {
        if (locationId == null || locationId.trim().length() == 0)
            return null;

        List<Asset_Location__c> locations = [SELECT Id FROM Asset_Location__c WHERE Location_ID__c = :locationId];
        return locations != null && locations.size() == 1 ? locations[0] : null;
    }

    public static boolean checkCircuitBreakerExistence(String assetId) {
        if (assetId == null || assetId.trim().length() == 0)
            return false;

        List<Circuit_Breaker__c> assets = [SELECT Id FROM Circuit_Breaker__c WHERE Asset_ID__c = :assetId];
        return assets != null && assets.size() == 1;
    }

    public static boolean checkAssetIdAuthorisation(String assetId) {
        return isCurrentUserAssetAuthorized(assetId) || isCurrentUserMemberOfCiPermSets();
    }

    public static boolean isCurrentUserAssetAuthorized(String assetId) {
        String companyId = SCI_CommonUtils.getUserCompanyId();
        return (companyId != null && assetId.endsWith(';' + SCI_CommonUtils.escapeSymbols(companyId)));
    }
    
    public static boolean isCurrentUserAuthorizedFor(String assetId, String companyId) {
        return (companyId != null && assetId.endsWith(';' + SCI_CommonUtils.escapeSymbols(companyId)));
    }

    public static boolean isNotCurrentUserAuthorizedFor(String assetId,String companyId) {
        return !isCurrentUserAuthorizedFor(assetId, companyId);
    }

    /*
        Checks that a user has the permission Connected_Insights_Internal or Connected_Insights_SME
    */
    public static boolean isCurrentUserMemberOfCiPermSets() {
        return SCI_CommonUtils.isCurrentUserMemberOfPermissionSet('Connected_Insights_Internal') ||
            SCI_CommonUtils.isCurrentUserMemberOfPermissionSet('Connected_Insights_SME');
    }

    public static List<User> listUsersOfGroup(String groupName) {
        if (groupName == null || groupName.trim().length() == 0) {
            throw new IllegalArgumentException();
        }

        Map<String, User> usersMap = new Map<String, User>();
        Map<String, UserRole> rolesMap = new Map<String, UserRole>();
        Map<String, Group> groupsMap = new Map<String, Group>();

        List<GroupMember> groupMembers = [
            SELECT UserOrGroupId
            FROM GroupMember
            WHERE Group.Type = 'Regular' AND Group.Name = :groupName
        ];
        for (GroupMember gm : groupMembers) {
            SCI_CommonUtils.visitGroupMember(gm.UserOrGroupId, usersMap, rolesMap, groupsMap);
        }

        return usersMap.values();
    }

    private static void visitGroupMember(
        String userOrGroupId,
        Map<String, User> usersMap,
        Map<String, UserRole> rolesMap,
        Map<String, Group> groupsMap
    ) {
        List<User> users = [SELECT Id, FirstName, LastName, IsActive, Email FROM User WHERE Id = :userOrGroupId];

        if (!users.isEmpty()) {
            User u = users[0];

            if (u.IsActive) {
                usersMap.put(u.Id, u);
            }
        } else {
            List<Group> roles = [SELECT RelatedId FROM Group WHERE Type LIKE 'Role%' AND Id = :userOrGroupId];

            if (!roles.isEmpty()) {
                String roleId = roles[0].RelatedId;

                if (!rolesMap.containsKey(roleId)) {
                    SCI_CommonUtils.visitRole(roleId, usersMap, rolesMap);
                }
            } else if (!groupsMap.containsKey(userOrGroupId)) {
                List<Group> groups = [SELECT Id FROM Group WHERE Type = 'Regular' AND Id = :userOrGroupId];

                if (!groups.isEmpty()) {
                    SCI_CommonUtils.visitGroup(groups[0].Id, usersMap, rolesMap, groupsMap);
                }
            }
        }
    }

    private static void visitRole(String roleId, Map<String, User> usersMap, Map<String, UserRole> rolesMap) {
        List<User> users = [
            SELECT Id, FirstName, LastName, Email
            FROM User
            WHERE IsActive = TRUE AND UserRoleId = :roleId
        ];

        for (User u : users) {
            usersMap.put(u.Id, u);
        }

        rolesMap.put(roleId, new UserRole(Id = roleId));

        List<UserRole> subRoles = [SELECT Id FROM UserRole WHERE ParentRoleId = :roleId];
        for (UserRole r : subRoles) {
            if (!rolesMap.containsKey(r.Id)) {
                SCI_CommonUtils.visitRole(r.Id, usersMap, rolesMap);
            }
        }
    }

    private static void visitGroup(
        String groupId,
        Map<String, User> usersMap,
        Map<String, UserRole> rolesMap,
        Map<String, Group> groupsMap
    ) {
        groupsMap.put(groupId, new Group(Id = groupId));

        List<GroupMember> groupMembers = [
            SELECT UserOrGroupId
            FROM GroupMember
            WHERE Group.Type = 'Regular' AND Group.Id = :groupId
        ];
        for (GroupMember gm : groupMembers) {
            SCI_CommonUtils.visitGroupMember(gm.UserOrGroupId, usersMap, rolesMap, groupsMap);
        }
    }

    private static List<User> listUsersWithRoleId(String roleId) {
        List<User> outcome = [
            SELECT Id, FirstName, LastName, Email
            FROM User
            WHERE IsActive = TRUE AND UserRoleId = :roleId
        ];

        List<UserRole> subRoles = [SELECT Id FROM UserRole WHERE ParentRoleId = :roleId];
        for (UserRole r : subRoles) {
            outcome.addAll(SCI_CommonUtils.listUsersWithRoleId(r.Id));
        }

        return outcome;
    }
}