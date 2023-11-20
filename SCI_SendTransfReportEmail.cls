public class SCI_SendTransfReportEmail {
    @InvocableMethod(label='Send Transformer Report Email')
    public static void sendEmails(List<ID> reportIds) {
        if (reportIds == null || reportIds.isEmpty()) {
            throw new IllegalArgumentException();
        }

        for (ID id : reportIds) {
            List<Transformer_Report_Request__c> reportRequests = [
                SELECT Name, CreatedById
                FROM Transformer_Report_Request__c
                WHERE Id IN (SELECT Transformer_Report_Request__c FROM Transformer_Report__c WHERE Id = :id)
            ];
            String userId = reportRequests.size() > 0 ? reportRequests[0].CreatedById : null;

            if (userId != null) {
                List<User> users = [SELECT Email FROM User WHERE Id = :userId];

                if (!users.isEmpty()) {
                    String[] toAddresses = new List<String>{ users[0].Email };
                    String subject = 'New Report Available: ' + reportRequests[0].Name;
                    List<Site> site = [SELECT Id FROM Site WHERE UrlPathPrefix = 'connectedInsights' LIMIT 1];

                    if (!site.isEmpty()) {
                        String url =
                            [SELECT SecureURL FROM SiteDetail WHERE DurableId = :site[0].Id]
                            .SecureUrl +
                            '/s/transformer-report/' +
                            id;
                        String htmlBody =
                            'A new report about transformers has been created.' +
                            '<p>To view report click here: <a href="' +
                            url +
                            '">' +
                            url +
                            '</a>.</p>';

                        SCI_EmailUtils.sendEmail(toAddresses, subject, htmlBody);
                    }
                }
            }
        }
    }
}