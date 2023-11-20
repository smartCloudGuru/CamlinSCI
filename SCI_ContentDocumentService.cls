public with sharing class SCI_ContentDocumentService {
    @AuraEnabled(cacheable=false)
    public static List<ContentDocumentLink> getRelatedDocs(Id recordId) {
        return [
            SELECT
                LinkedEntityId,
                ContentDocument.Id,
                ContentDocument.CreatedDate,
                ContentDocument.Title,
                ContentDocument.ContentSize,
                ContentDocument.FileType
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :recordId
        ];
    }

    @AuraEnabled(cacheable=true)
    public static string getDocVersionId(Id docId) {
        ContentVersion contentVersion = [
            SELECT Id
            FROM ContentVersion
            WHERE ContentDocumentId = :docId AND IsLatest = TRUE
        ];

        return contentVersion != null ? contentVersion.Id : null;
    }

    @AuraEnabled(cacheable=false)
    public static void deleteDoc(Id docId) {
        ContentDocument contentDocument = new ContentDocument(Id = docId);
        delete contentDocument;
    }
}