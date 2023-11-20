trigger CustomerCommunityUsersTrigger on User(after insert) {
    List<User> users = [SELECT Id, Name, AccountId FROM User WHERE Id IN :Trigger.new];

    for (User user : users) {
        if (user.AccountId != null) {
            List<Account> accounts = [SELECT Id, Company_ID__c FROM Account WHERE Id = :user.AccountId];

            if (!accounts.isEmpty()) {
                user.CompanyName = accounts[0].Company_ID__c;
                update user;

                System.debug(
                    'User Id "' +
                    user.Id +
                    '" (' +
                    user.Name +
                    ') - company name updated: "' +
                    user.CompanyName +
                    '"'
                );
            }
        }
    }
}