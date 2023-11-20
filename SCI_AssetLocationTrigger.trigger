trigger SCI_AssetLocationTrigger on Asset_Location__c(before insert, before update) {
    for (Asset_Location__c al : Trigger.new) {
        List<Asset_Location__c> alreadyExistingLocations;

        // Sets Site ID, if missing
        if (al.Site_ID__c == null || al.Site_ID__c.trim().length() == 0) {
            al.Site_ID__c = SCI_CommonUtils.escapeSymbols(al.Name.length() > 64 ? al.Name.substring(0, 64) : al.Name);

            alreadyExistingLocations = [
                SELECT Id
                FROM Asset_Location__c
                WHERE Asset_Location__c.Company__c = :al.Company__c AND Asset_Location__c.Site_ID__c = :al.Site_ID__c
            ];

            if (alreadyExistingLocations != null && alreadyExistingLocations.size() != 0) {
                integer num = [
                    SELECT COUNT()
                    FROM Asset_Location__c
                    WHERE Asset_Location__c.Company__c = :al.Company__c
                ];

                al.Site_ID__c =
                    (al.Site_ID__c.length() > 60 ? al.Site_ID__c.substring(0, 60) : al.Site_ID__c) +
                    '-' +
                    String.valueOf(num).leftPad(3, '0');
            }
        }

        // Checks if Asset Location already exists
        if (Trigger.isInsert) {
            alreadyExistingLocations = [
                SELECT Id
                FROM Asset_Location__c
                WHERE Asset_Location__c.Company__c = :al.Company__c AND Asset_Location__c.Site_ID__c = :al.Site_ID__c
            ];

            if (alreadyExistingLocations != null && alreadyExistingLocations.size() != 0) {
                al.addError(
                    'Cannot create Asset Location record with the same Site ID and Company ID of another record.'
                );
            }
        }
    }
}