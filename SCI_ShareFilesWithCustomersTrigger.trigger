trigger SCI_ShareFilesWithCustomersTrigger on ContentDocumentLink(before insert) {
    Schema.DescribeSObjectResult r = Transformer_Report__c.sObjectType.getDescribe();
    String keyPrefix = r.getKeyPrefix();

    for (ContentDocumentLink cdl : Trigger.new) {
        if ((String.valueOf(cdl.LinkedEntityId)).startsWith(keyPrefix)) {
            cdl.ShareType = 'I';
            cdl.Visibility = 'AllUsers';
        }
    }
}