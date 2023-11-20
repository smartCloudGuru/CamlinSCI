public class SCI_SendTransfReportRequestEmail {
    @InvocableMethod(label='Send Transformer Report Request Email')
    public static void sendEmails(List<ID> reportRequestIds) {
        if (reportRequestIds == null || reportRequestIds.isEmpty()) {
            throw new IllegalArgumentException();
        }

        List<User> backOfficeUsers = SCI_CommonUtils.listUsersOfGroup(SCI_Constants.BACKOFFICE_USERS_PUBLIC_GROUP);
        Messaging.reserveSingleEmailCapacity(reportRequestIds.size());

        List<String> toAddresses = new List<String>();
        for (User u : backOfficeUsers) {
            toAddresses.add(u.Email);
        }

        for (ID id : reportRequestIds) {
            String subject = 'New Report Request Created: ' + id;
            String url =
                URL.getOrgDomainUrl().toExternalForm() +
                '/lightning/r/Transformer_Report_Request__c/' +
                id +
                '/view';
            String htmlBody =
                'A new report request about transformers has been created.' +
                '<p>To view report request click here: <a href="' +
                url +
                '">' +
                url +
                '</a>.</p>';

            SCI_EmailUtils.sendEmail(toAddresses, subject, htmlBody);
        }
    }
}