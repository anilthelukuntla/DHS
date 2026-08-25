@IsTest
public class MailUtilitiesTest {

    @TestSetup
    static void setupData() {
        Account acc = new Account(Name = 'Test Account');
        insert acc;

        Contact con = new Contact(
            LastName = 'Test Contact',
            Email = 'testcontact@example.com',
            AccountId = acc.Id
        );
        insert con;
    }

    @IsTest
    static void testSendHTMLEmail() {
        List<String> toAddresses = new List<String>{ 'test@example.com' };
        List<String> ccAddresses = new List<String>{ 'cc@example.com' };

        Test.startTest();
        MailUtilities.sendHTMLEmail(
            toAddresses,
            'Test Subject',
            '<h1>Test Body</h1>',
            ccAddresses
        );
        Test.stopTest();

    }

    @IsTest
    static void testSendHTMLEmailWithTargetObjectId() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        MailUtilities.sendHTMLEmailWithTargetObjectId(
            con.Id,
            'Target Object Test',
            '<p>Hello Contact</p>',
            new List<String>{ 'cc@example.com' }
        );
        Test.stopTest();

    }

    @IsTest
    static void testSendBIEmail() {
        Test.startTest();
        MailUtilities.sendBIEmail(
            'BI Email Test',
            '<p>BI Email Body</p>',
            new List<String>{ 'to@example.com' },
            new List<String>{ 'bcc@example.com' },
            new List<String>{ 'cc@example.com' }
        );
        Test.stopTest();

    }

    @IsTest
    static void testSendBIEmailWithSetTargetObjectId() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];

        Test.startTest();
        MailUtilities.sendBIEmailWithSetTargetObjectId(
            'BI Target Test',
            '<p>BI Target Body</p>',
            con.Id,
            new List<String>{ 'bcc@example.com' },
            new List<String>{ 'cc@example.com' }
        );
        Test.stopTest();

    }

    @IsTest
    static void testNullAndEmptyRecipients() {
        Test.startTest();

        MailUtilities.sendHTMLEmail(
            null,
            'No Recipients',
            '<p>No email should send</p>',
            null
        );

        MailUtilities.sendHTMLEmail(
            new List<String>(),
            'Empty Recipients',
            '<p>No email should send</p>',
            null
        );

        Test.stopTest();

        System.assertEquals(0, Limits.getEmailInvocations());
    }
    @IsTest
    static void testSendHTMLEmailWithTemplate() {
        Contact con = [SELECT Id FROM Contact LIMIT 1];
    
        EmailTemplate template = new EmailTemplate(
            Name = 'Test Template',
            DeveloperName = 'Test_Template',
            FolderId = UserInfo.getUserId(),
            TemplateType = 'custom',
            Subject = 'Test Template Subject',
            HtmlValue = '<p>Hello {!Contact.Name}</p>',
            Body = 'Hello'
        );
        insert template;
    
        Test.startTest();
    
        MailUtilities.sendHTMLEmail(
            new List<String>{ 'test@example.com' },
            'Template Email Test',
            '<p>Body</p>',
            new List<String>{ 'cc@example.com' },
            'Test Template',
            con.Id
        );
    
        Test.stopTest();
    
    }
}