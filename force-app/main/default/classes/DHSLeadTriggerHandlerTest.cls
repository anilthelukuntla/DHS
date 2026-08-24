@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexAssertionsShouldIncludeMessage')
public class DHSLeadTriggerHandlerTest {

    @TestSetup
    static void setupData() {
        User u = [
            SELECT Id, Candidate_type__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
        u.Candidate_type__c = 'SCA';
        update u;

        DHS_Contact__c con = new DHS_Contact__c();
        con.First_Name__c = 'Test';
        con.Last_Name__c = 'Contact';
        con.Email__c = 'test@test.com';
        con.Contact_Type__c = 'Subject';
        con.SSN__c = '123-45-6789';
        insert con;

        DHS_Case__c c = new DHS_Case__c();
        c.DHS_Contact__c = con.Id;
        c.DHS_Assigned_To__c = UserInfo.getUserId();
        insert c;
    }

    private static DHS_Case__c getCaseRecord() {
        return [
            SELECT Id
            FROM DHS_Case__c
            LIMIT 1
        ];
    }

    private static DHS_Lead__c createLead(String leadType, String coverageType) {
        DHS_Case__c c = getCaseRecord();

        DHS_Lead__c l = new DHS_Lead__c();
        l.DHS_Case__c = c.Id;
        l.DHS_Assigned_To__c = UserInfo.getUserId();
        l.LeadType__c = leadType;
        l.Coverage_Type__c = coverageType;
        l.Status__c = 'Assigned';
        insert l;

        return l;
    }

    @IsTest
    static void testSubjectInterviewCompletedCreatesInvoice() {
        DHS_Lead__c l = createLead(
            'Subject Interview (ESI/TESI)',
            'Subject Interview'
        );

        l.Status__c = 'Completed';
        l.Was_Subject_Interview_Conducted__c = 'Yes';

        Test.startTest();
        update l;
        Test.stopTest();

        DHS_Invoice__c inv = [
            SELECT Id, DHS_Lead__c, Status__c, Interview_Method__c, Item_Price__c
            FROM DHS_Invoice__c
            WHERE DHS_Lead__c = :l.Id
            LIMIT 1
        ];

        System.assertEquals('Generated', inv.Status__c);
        System.assertEquals('P', inv.Interview_Method__c);
        System.assertEquals(450.00, inv.Item_Price__c);
    }

    @IsTest
    static void testSubjectInterviewUnableCreatesInvoice() {
        DHS_Lead__c l = createLead(
            'Subject Interview (ESI/TESI)',
            'Subject Interview'
        );

        l.Status__c = 'Completed';
        l.Was_Subject_Interview_Conducted__c = 'No';

        Test.startTest();
        update l;
        Test.stopTest();

        DHS_Invoice__c inv = [
            SELECT Interview_Method__c, Item_Price__c
            FROM DHS_Invoice__c
            WHERE DHS_Lead__c = :l.Id
            LIMIT 1
        ];

        System.assertEquals('P-UC', inv.Interview_Method__c);
        System.assertEquals(15.00, inv.Item_Price__c);
    }

    @IsTest
    static void testPersonalTelephoneCreatesPOInvoice() {
        DHS_Lead__c l = createLead(
            'Personal Reference (PERS)',
            'Personal'
        );

        l.Status__c = 'Completed';
        l.Was_the_record_obtained_Personal__c = 'Yes, Source was interviewed';
        l.Personal_Contact_Method__c = 'Telephone';

        Test.startTest();
        update l;
        Test.stopTest();

        DHS_Invoice__c inv = [
            SELECT Interview_Method__c, Item_Price__c
            FROM DHS_Invoice__c
            WHERE DHS_Lead__c = :l.Id
            LIMIT 1
        ];

        System.assertEquals('PO', inv.Interview_Method__c);
        System.assertEquals(75.00, inv.Item_Price__c);
    }

    @IsTest
    static void testPersonalInPersonCreatesPInvoice() {
        DHS_Lead__c l = createLead(
            'Personal Reference (PERS)',
            'Personal'
        );

        l.Status__c = 'Completed';
        l.Was_the_record_obtained_Personal__c = 'Yes, Source was interviewed';
        l.Personal_Contact_Method__c = 'In Person';

        Test.startTest();
        update l;
        Test.stopTest();

        DHS_Invoice__c inv = [
            SELECT Interview_Method__c, Item_Price__c
            FROM DHS_Invoice__c
            WHERE DHS_Lead__c = :l.Id
            LIMIT 1
        ];

        System.assertEquals('P', inv.Interview_Method__c);
        System.assertEquals(115.00, inv.Item_Price__c);
    }

    @IsTest
    static void testPersonalUnableCreatesPUCInvoice() {
        DHS_Lead__c l = createLead(
            'Personal Reference (PERS)',
            'Personal'
        );

        l.Status__c = 'Completed';
        l.Was_the_record_obtained_Personal__c = 'No, Unable to interview source';

        Test.startTest();
        update l;
        Test.stopTest();

        DHS_Invoice__c inv = [
            SELECT Interview_Method__c, Item_Price__c
            FROM DHS_Invoice__c
            WHERE DHS_Lead__c = :l.Id
            LIMIT 1
        ];

        System.assertEquals('P-UC', inv.Interview_Method__c);
        System.assertEquals(15.00, inv.Item_Price__c);
    }

    @IsTest
    static void testRecordEmailCreatesROInvoice() {
        DHS_Lead__c l = createLead(
            'Education (EDUC)',
            'Record'
        );

        l.Status__c = 'Completed';
        l.Was_the_record_obtained__c = 'Yes, record was obtained';
        l.Contact_Method__c = 'Email';

        Test.startTest();
        update l;
        Test.stopTest();

        DHS_Invoice__c inv = [
            SELECT Interview_Method__c, Item_Price__c
            FROM DHS_Invoice__c
            WHERE DHS_Lead__c = :l.Id
            LIMIT 1
        ];

        System.assertEquals('RO', inv.Interview_Method__c);
        System.assertEquals(50.00, inv.Item_Price__c);
    }

    @IsTest
    static void testRecordInPersonCreatesRInvoice() {
        DHS_Lead__c l = createLead(
            'Education (EDUC)',
            'Record'
        );

        l.Status__c = 'Completed';
        l.Was_the_record_obtained__c = 'No, record does not exist';
        l.Contact_Method__c = 'In Person';

        Test.startTest();
        update l;
        Test.stopTest();

        DHS_Invoice__c inv = [
            SELECT Interview_Method__c, Item_Price__c
            FROM DHS_Invoice__c
            WHERE DHS_Lead__c = :l.Id
            LIMIT 1
        ];

        System.assertEquals('R', inv.Interview_Method__c);
        System.assertEquals(60.00, inv.Item_Price__c);
    }

    @IsTest
    static void testRecordUnableCreatesRUCInvoice() {
        DHS_Lead__c l = createLead(
            'Education (EDUC)',
            'Record'
        );

        l.Status__c = 'Completed';
        l.Was_the_record_obtained__c = 'No, unable to obtain record';

        Test.startTest();
        update l;
        Test.stopTest();

        DHS_Invoice__c inv = [
            SELECT Interview_Method__c, Item_Price__c
            FROM DHS_Invoice__c
            WHERE DHS_Lead__c = :l.Id
            LIMIT 1
        ];

        System.assertEquals('R-UC', inv.Interview_Method__c);
        System.assertEquals(15.00, inv.Item_Price__c);
    }

    @IsTest
    static void testEmploymentUsesEmploymentContactMethod() {
        DHS_Lead__c l = createLead(
            'Employment (EMPL)',
            'Record'
        );

        l.Status__c = 'Completed';
        l.Was_the_record_obtained__c = 'Yes, record was obtained';
        l.Employment_Contact_Method__c = 'Telephone';

        Test.startTest();
        update l;
        Test.stopTest();

        DHS_Invoice__c inv = [
            SELECT Interview_Method__c, Item_Price__c
            FROM DHS_Invoice__c
            WHERE DHS_Lead__c = :l.Id
            LIMIT 1
        ];

        System.assertEquals('RO', inv.Interview_Method__c);
        System.assertEquals(50.00, inv.Item_Price__c);
    }

    @IsTest
    static void testExistingInvoiceUpdatedToGenerated() {
        DHS_Lead__c l = createLead(
            'Subject Interview (ESI/TESI)',
            'Subject Interview'
        );

        DHS_Invoice__c inv = new DHS_Invoice__c();
        inv.DHS_Lead__c = l.Id;
        inv.DHS_Case__c = l.DHS_Case__c;
        inv.Status__c = 'In-Review';
        insert inv;

        l.Status__c = 'Completed';
        l.Was_Subject_Interview_Conducted__c = 'Yes';

        Test.startTest();
        update l;
        Test.stopTest();

        DHS_Invoice__c updatedInv = [
            SELECT Status__c
            FROM DHS_Invoice__c
            WHERE Id = :inv.Id
        ];

        System.assertEquals('Generated', updatedInv.Status__c);
    }

    @IsTest
    static void testCompletedBackToInProgressSetsInvoiceInReview() {
        DHS_Lead__c l = createLead(
            'Subject Interview (ESI/TESI)',
            'Subject Interview'
        );

        l.Status__c = 'Completed';
        l.Was_Subject_Interview_Conducted__c = 'Yes';
        update l;

        DHS_Invoice__c inv = [
            SELECT Id, Status__c
            FROM DHS_Invoice__c
            WHERE DHS_Lead__c = :l.Id
            LIMIT 1
        ];

        l.Status__c = 'In-Progress';

        Test.startTest();
        update l;
        Test.stopTest();

        DHS_Invoice__c updatedInv = [
            SELECT Status__c
            FROM DHS_Invoice__c
            WHERE Id = :inv.Id
        ];

        System.assertEquals('In-Review', updatedInv.Status__c);
    }

    @IsTest
    static void testNoInvoiceWhenStatusNotCompleted() {
        DHS_Lead__c l = createLead(
            'Subject Interview (ESI/TESI)',
            'Subject Interview'
        );

        l.Status__c = 'In-Progress';

        Test.startTest();
        update l;
        Test.stopTest();

        Integer invoiceCount = [
            SELECT COUNT()
            FROM DHS_Invoice__c
            WHERE DHS_Lead__c = :l.Id
        ];

        System.assertEquals(0, invoiceCount);
    }
}
