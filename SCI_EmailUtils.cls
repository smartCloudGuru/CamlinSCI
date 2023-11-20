public class SCI_EmailUtils {
    private static String SENDER_DISPLAY_NAME = 'SAPIENT Connected Insights';

    public static void sendEmail(List<String> toAddresses, String subject, String htmlBody) {
        if (toAddresses == null || toAddresses.isEmpty()) {
            throw new IllegalArgumentException();
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        // Assign the addresses for the To lists to the mail object.
        mail.setToAddresses(toAddresses);

        // Specify the address used when the recipients reply to the email.
        //mail.setReplyTo('no_reply@camlingroup.com');

        // Specify the name used as the display name.
        mail.setSenderDisplayName(SENDER_DISPLAY_NAME);

        // Specify the subject line for your email address.
        mail.setSubject(subject);

        // Optionally append the salesforce.com email signature to the email.
        // The email address of the user executing the Apex Code will be used.
        mail.setUseSignature(false);

        // Specify the content of the email.
        mail.setHtmlBody(htmlBody);

        // Send the email
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{ mail });
    }
}