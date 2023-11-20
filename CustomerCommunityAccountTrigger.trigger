trigger CustomerCommunityAccountTrigger on Account(before insert, before update) {
    for (Account acc : Trigger.new) {
        if (acc.SCI_Enabled__c == true && acc.Company_ID__c == null) {
            acc.Company_ID__c = SCI_CommonUtils.escapeSymbols(
                acc.Name.length() > 64 ? acc.Name.substring(0, 64) : acc.Name
            );

            List<Account> alreadyExistingAccounts = [SELECT Id FROM Account WHERE Company_ID__c = :acc.Company_ID__c];

            if (alreadyExistingAccounts != null && alreadyExistingAccounts.size() > 0) {
                String whereParam = acc.Company_ID__c + '%';
                integer num = [SELECT COUNT() FROM Account WHERE Company_ID__c LIKE :whereParam];

                acc.Company_ID__c =
                    (acc.Company_ID__c.length() > 60 ? acc.Company_ID__c.substring(0, 60) : acc.Company_ID__c) +
                    '-' +
                    String.valueOf(num).leftPad(3, '0');

                alreadyExistingAccounts = [SELECT Id FROM Account WHERE Company_ID__c = :acc.Company_ID__c];

                if (alreadyExistingAccounts != null && alreadyExistingAccounts.size() != 0) {
                    if (Trigger.isInsert) {
                        acc.addError('Cannot create Account record with the same Company ID of another record.');
                    } else {
                        Trigger.oldMap
                            .get(acc.Id)
                            .addError('Cannot set Company ID equals to the one of another Account record.');
                    }
                }
            }
        }
    }
}