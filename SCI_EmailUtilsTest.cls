@isTest
private class SCI_EmailUtilsTest {
    @isTest
    static void test_sendEmail() {
        Test.startTest();

        System.assertEquals(0, Limits.getEmailInvocations());

        boolean exceptionThrown = false;

        try {
            SCI_EmailUtils.sendEmail(null, '', '');
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown);
        System.assertEquals(0, Limits.getEmailInvocations());

        exceptionThrown = false;

        try {
            SCI_EmailUtils.sendEmail(new List<String>(), '', '');
        } catch (IllegalArgumentException e) {
            exceptionThrown = true;
        }

        System.assert(exceptionThrown);
        System.assertEquals(0, Limits.getEmailInvocations());

        String[] toAddresses = new List<String>{ 'conte.mascetti@antani.org', 'prof.sassaroli@antani.org' };
        String subject = 'Sbiriguda';
        String htmlBody = '<p>Allaccia scarpa, scarpallaccia.</p>';

        SCI_EmailUtils.sendEmail(toAddresses, subject, htmlBody);

        System.assertEquals(1, Limits.getEmailInvocations());

        Test.stopTest();
    }
}