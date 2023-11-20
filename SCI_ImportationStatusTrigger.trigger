trigger SCI_ImportationStatusTrigger on SCI_Importation_Status_Notification__e(after insert) {
    for (SCI_Importation_Status_Notification__e event : Trigger.New) {
        Asset_Importation_Request__c impRequest = [
            SELECT Name
            FROM Asset_Importation_Request__c
            WHERE Name = :event.ImportRequestId__c
            LIMIT 1
        ];

        if (impRequest == null) {
            System.debug(
                'Received an SCI_Importation_Status_Notification__e event with a not matching ' +
                'ImportRequestId__c field: ' +
                JSON.serialize(event)
            );
        } else {
            impRequest.Progress__c = event.Progress__c;
            impRequest.SerialIdOrAssetId__c = event.SerialIdOrAssetId__c;
            impRequest.Status__c = event.Status__c;

            update impRequest;
        }
    }
}