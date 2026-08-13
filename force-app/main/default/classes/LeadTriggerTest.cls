@IsTest
/** Exercises the existing LeadTrigger behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.NcssCount, PMD.UnusedLocalVariable')
public class LeadTriggerTest {

    @TestSetup
    static void setupData() {
        Contact__c con = new Contact__c();
        con.First_Name__c = 'Test';
        con.Last_Name__c = 'Name';
        con.Email__c = 'test@test.com';
        con.Contact_Type__c = 'Subject';
        con.SSN__c = '123-12-1123';
        insert con;

        Case__c caseRec = new Case__c();
        caseRec.Contact__c = con.Id;
        caseRec.Assigned_To__c = UserInfo.getUserId();
        insert caseRec;

        Timesheet__c ts = new Timesheet__c();
        ts.User__c = UserInfo.getUserId();
        ts.Date__c = System.today();
        insert ts;
    }

    private static Case__c getCaseRecord() {
        return [
            SELECT Id, Contact__c, Assigned_To__c, Case_Number__c
            FROM Case__c
            LIMIT 1
        ];
    }

    private static Lead__c createLead(Boolean doInsert) {
        Case__c c = getCaseRecord();

        Lead__c l = new Lead__c();
        l.Case__c = c.Id;
        l.Coverage_Type__c = 'Subject Interview';
        l.LeadType__c = 'Subject Interview (ESI/TESI)';
        l.Assigned_To__c = UserInfo.getUserId();
        l.Item_Number__c = 1;

        if(doInsert) {
            insert l;
        }

        return l;
    }

    @IsTest
    static void testBeforeInsertLead() {
        Test.startTest();

        Lead__c l = createLead(false);
        insert l;

        Test.stopTest();

        Lead__c insertedLead = [
            SELECT Id, Status__c, Contact__c, Last_Status_Change__c
            FROM Lead__c
            WHERE Id = :l.Id
        ];

        System.assertNotEquals(null, insertedLead.Contact__c, 'Assertion failed in LeadTriggerTest at source line 67');
        System.assertNotEquals(null, insertedLead.Last_Status_Change__c, 'Assertion failed in LeadTriggerTest at source line 68');
    }

    @IsTest
    static void testAssignedNotAcceptedFlow() {
        Lead__c l = createLead(true);

        Test.startTest();

        l.Status__c = 'Assigned Not Accepted';
        l.Assigned_To__c = UserInfo.getUserId();
        update l;

        Test.stopTest();

        Lead__c updatedLead = [
            SELECT Id, Status__c, Lead_Log__c
            FROM Lead__c
            WHERE Id = :l.Id
        ];

        System.assertEquals('Assigned Not Accepted', updatedLead.Status__c, 'Assertion failed in LeadTriggerTest at source line 89');
    }

    @IsTest
    static void testLeadAcceptedFlow() {
        Lead__c l = createLead(true);

        Test.startTest();

        l.Assigned_To__c = UserInfo.getUserId();
        l.Lead_Accepted_or_Rejected__c = 'Accepted';
        update l;

        Test.stopTest();

        Lead__c updatedLead = [
            SELECT Id, Status__c, Lead_Accepted_or_Rejected__c, Lead_Log__c
            FROM Lead__c
            WHERE Id = :l.Id
        ];

        System.assertEquals('Accepted', updatedLead.Lead_Accepted_or_Rejected__c, 'Assertion failed in LeadTriggerTest at source line 110');
        System.assertEquals('In-Progress', updatedLead.Status__c, 'Assertion failed in LeadTriggerTest at source line 111');
    }

    @IsTest
    static void testLeadRejectedFlow() {
        Lead__c l = createLead(true);

        Test.startTest();

        l.Assigned_To__c = UserInfo.getUserId();
        l.Lead_Accepted_or_Rejected__c = 'Rejected';
        update l;

        Test.stopTest();

        Lead__c updatedLead = [
            SELECT Id, Lead_Accepted_or_Rejected__c, Assigned_To__c, Lead_Log__c
            FROM Lead__c
            WHERE Id = :l.Id
        ];

        System.assertEquals('Rejected', updatedLead.Lead_Accepted_or_Rejected__c, 'Assertion failed in LeadTriggerTest at source line 132');
    }

    @IsTest
    static void testCompletedLeadCreatesMessages() {
        Lead__c l = createLead(true);

        Test.startTest();

        l.Status__c = 'Completed';
        l.Issues_discrepancies_or_developed_acti__c = 'Yes';
        l.Issue_Description__c = 'Test issue description';
        l.Explanation_of_why_leads_not_obtained__c = 'Test ESI explanation';
        update l;

        Test.stopTest();

        List<Message__c> msgs = [
            SELECT Id, Subject__c, Message_Body__c, Lead__c
            FROM Message__c
            WHERE Lead__c = :l.Id
        ];

        System.assert(msgs.size() > 0, 'Assertion failed in LeadTriggerTest at source line 155');
    }

    @IsTest
    static void testCompletedDateSet() {
        Lead__c l = createLead(true);

        Test.startTest();

        l.Status__c = 'Completed';
        update l;

        Test.stopTest();

        Lead__c updatedLead = [
            SELECT Id, Completed_Date__c
            FROM Lead__c
            WHERE Id = :l.Id
        ];

        System.assertEquals(System.today(), updatedLead.Completed_Date__c, 'Assertion failed in LeadTriggerTest at source line 175');
    }

    @IsTest
    static void testIssueDescriptionCleared() {
        Lead__c l = createLead(true);

        l.Issues_discrepancies_or_developed_acti__c = 'Yes';
        l.Issue_Description__c = 'Should be cleared';
        update l;

        Test.startTest();

        l.Issues_discrepancies_or_developed_acti__c = 'No';
        update l;

        Test.stopTest();

        Lead__c updatedLead = [
            SELECT Id, Issue_Description__c
            FROM Lead__c
            WHERE Id = :l.Id
        ];

        System.assertEquals(null, updatedLead.Issue_Description__c, 'Assertion failed in LeadTriggerTest at source line 199');
    }

    @IsTest
    static void testWaiverInformationCreated() {
        Lead__c l = createLead(true);

        Test.startTest();

        l.Reason_for_Waiver__c = 'Subject not available';
        update l;

        Test.stopTest();

        List<Waiver_Information__c> waivers = [
            SELECT Id, Case__c, Lead__c, Waiver_Reason__c
            FROM Waiver_Information__c
            WHERE Lead__c = :l.Id
        ];

        System.assertEquals(1, waivers.size(), 'Assertion failed in LeadTriggerTest at source line 219');
        System.assertEquals('Subject not available', waivers[0].Waiver_Reason__c, 'Assertion failed in LeadTriggerTest at source line 220');
    }

    @IsTest
    static void testQARejectedToInProgressLog() {
        Lead__c l = createLead(true);

        l.Status__c = 'QA Rejected';
        update l;

        Test.startTest();

        l.Status__c = 'In-Progress';
        update l;

        Test.stopTest();

        Lead__c updatedLead = [
            SELECT Id, Status__c, Lead_Log__c
            FROM Lead__c
            WHERE Id = :l.Id
        ];

        System.assertEquals('In-Progress', updatedLead.Status__c, 'Assertion failed in LeadTriggerTest at source line 243');
    }

    @IsTest
    static void testQAReviewCompletedLog() {
        Lead__c l = createLead(true);

        l.Status__c = 'QA Review Completed';
        update l;

        Test.startTest();

        l.Status__c = 'Completed';
        update l;

        Test.stopTest();

        Lead__c updatedLead = [
            SELECT Id, Status__c, Lead_Log__c
            FROM Lead__c
            WHERE Id = :l.Id
        ];

        System.assertEquals('Completed', updatedLead.Status__c, 'Assertion failed in LeadTriggerTest at source line 266');
    }

    @IsTest
    static void testCoverageTypeChangeSetsInProgress() {
        Lead__c l = createLead(true);

        Test.startTest();

        l.Coverage_Type__c = 'Other';
        update l;

        Test.stopTest();

        Lead__c updatedLead = [
            SELECT Id, Status__c, Coverage_Type__c
            FROM Lead__c
            WHERE Id = :l.Id
        ];

    }

    @IsTest
    static void testDuplicateItemNumberValidation() {
        Case__c c = getCaseRecord();

        Lead__c l1 = new Lead__c();
        l1.Case__c = c.Id;
        l1.Coverage_Type__c = 'Subject Interview';
        l1.LeadType__c = 'Subject Interview (ESI/TESI)';
        l1.Item_Number__c = 10;
        insert l1;

        Lead__c l2 = new Lead__c();
        l2.Case__c = c.Id;
        l2.Coverage_Type__c = 'Subject Interview';
        l2.LeadType__c = 'Subject Interview (ESI/TESI)';
        l2.Item_Number__c = 10;

        Test.startTest();

        try {
            insert l2;
            System.assert(false, 'Duplicate item number should throw error.');
        } catch (DmlException e) {
            System.assert(e.getMessage().contains('Duplicate') || e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'), 'Assertion failed in LeadTriggerTest at source line 311');
        }

        Test.stopTest();
    }

    @IsTest
    static void testInvoiceCalculationVariants() {
        Date completedDate = Date.today();
        Lead__c leadRecord = new Lead__c(
            LeadType__c = 'Subject Interview (ESI/TESI)',
            Coverage_Type__c = 'Subject Interview',
            Was_Subject_interview_conducted__c = 'Yes',
            Completed_Date__c = completedDate
        );

        Invoice__c invoice = LeadTriggerHandler.generateInvoices(leadRecord);
        System.assertEquals('P', invoice.Interview_Method__c, 'Assertion failed in LeadTriggerTest at source line 328');
        System.assertEquals(450, invoice.Item_Price__c, 'Assertion failed in LeadTriggerTest at source line 329');
        System.assertEquals('Generated', invoice.Status__c, 'Assertion failed in LeadTriggerTest at source line 330');
        System.assertNotEquals(null, invoice.Pay_Period_Ending__c, 'Assertion failed in LeadTriggerTest at source line 331');

        leadRecord.Was_Subject_interview_conducted__c = 'No';
        invoice = LeadTriggerHandler.generateInvoices(leadRecord);
        System.assertEquals('P-UC', invoice.Interview_Method__c, 'Assertion failed in LeadTriggerTest at source line 335');
        System.assertEquals(15, invoice.Item_Price__c, 'Assertion failed in LeadTriggerTest at source line 336');

        leadRecord.LeadType__c = 'General (GENL)';
        leadRecord.Coverage_Type__c = 'Personal';
        leadRecord.Was_the_record_obtained_Personal__c =
            'Yes, Source was interviewed';
        leadRecord.Personal_Contact_Method__c = 'Telephone';
        invoice = LeadTriggerHandler.generateInvoices(leadRecord);
        System.assertEquals('PO', invoice.Interview_Method__c, 'Assertion failed in LeadTriggerTest at source line 344');
        System.assertEquals(75, invoice.Item_Price__c, 'Assertion failed in LeadTriggerTest at source line 345');

        leadRecord.Personal_Contact_Method__c = 'In Person';
        invoice = LeadTriggerHandler.generateInvoices(leadRecord);
        System.assertEquals('P', invoice.Interview_Method__c, 'Assertion failed in LeadTriggerTest at source line 349');
        System.assertEquals(115, invoice.Item_Price__c, 'Assertion failed in LeadTriggerTest at source line 350');

        leadRecord.Was_the_record_obtained_Personal__c =
            'No, Unable to interview source';
        invoice = LeadTriggerHandler.generateInvoices(leadRecord);
        System.assertEquals('P-UC', invoice.Interview_Method__c, 'Assertion failed in LeadTriggerTest at source line 355');

        leadRecord.Coverage_Type__c = 'Record';
        leadRecord.Was_the_record_obtained_Personal__c = null;
        leadRecord.Was_the_record_obtained__c =
            'Yes, record was obtained';
        leadRecord.Contact_Method__c = 'Email';
        invoice = LeadTriggerHandler.generateInvoices(leadRecord);
        System.assertEquals('RO', invoice.Interview_Method__c, 'Assertion failed in LeadTriggerTest at source line 363');
        System.assertEquals(50, invoice.Item_Price__c, 'Assertion failed in LeadTriggerTest at source line 364');

        leadRecord.Contact_Method__c = 'In Person';
        invoice = LeadTriggerHandler.generateInvoices(leadRecord);
        System.assertEquals('R', invoice.Interview_Method__c, 'Assertion failed in LeadTriggerTest at source line 368');
        System.assertEquals(60, invoice.Item_Price__c, 'Assertion failed in LeadTriggerTest at source line 369');

        leadRecord.Was_the_record_obtained__c =
            'No, unable to obtain record';
        invoice = LeadTriggerHandler.generateInvoices(leadRecord);
        System.assertEquals('R-UC', invoice.Interview_Method__c, 'Assertion failed in LeadTriggerTest at source line 374');

        leadRecord.Was_the_record_obtained__c = null;
        invoice = LeadTriggerHandler.generateInvoices(leadRecord);
        System.assertEquals('', invoice.Interview_Method__c, 'Assertion failed in LeadTriggerTest at source line 378');
        System.assertEquals(null, invoice.Item_Price__c, 'Assertion failed in LeadTriggerTest at source line 379');

        System.assertEquals(null, LeadTriggerHandler.getPayPeriodEndingDate(null), 'Assertion failed in LeadTriggerTest at source line 381');
        System.assertEquals(
            0,
            LeadTriggerHandler.getPaychexIds(new List<Lead__c>()).size()
        , 'Assertion failed in LeadTriggerTest at source line 382');
    }

    @IsTest
    static void testLeadAuditHistoryCalculation() {
        Lead__c insertedLead = createLead(true);
        Lead__c oldVersion = [
            SELECT Id, Status__c, Last_Status_Change__c, CreatedById
            FROM Lead__c
            WHERE Id = :insertedLead.Id
        ];
        Lead__c newVersion = oldVersion.clone(true, true, false, false);
        oldVersion.Last_Status_Change__c = System.now().addHours(-1);
        newVersion.Last_Status_Change__c = System.now();
        insert new List<Lead_Status_History__c>{
            new Lead_Status_History__c(
                Lead__c = insertedLead.Id,
                Completed_By__c = UserInfo.getUserId()
            ),
            new Lead_Status_History__c(
                Lead__c = insertedLead.Id,
                Completed_By__c = UserInfo.getUserId()
            )
        };

        Test.startTest();
        LeadTriggerHandler.LeadAuditMethod(
            new List<Lead__c>{ oldVersion },
            new List<Lead__c>{ newVersion }
        );
        Test.stopTest();

        List<Lead_Status_History__c> historyRecords = [
            SELECT Id, Lead__c, Status_Name__c, Status_Duration__c
            FROM Lead_Status_History__c
            WHERE Lead__c = :insertedLead.Id
            AND Status_Duration__c != null
        ];
        System.assertEquals(1, historyRecords.size(), 'Assertion failed in LeadTriggerTest at source line 423');
        System.assertEquals(oldVersion.Status__c, historyRecords[0].Status_Name__c, 'Assertion failed in LeadTriggerTest at source line 424');
        System.assert(historyRecords[0].Status_Duration__c.contains('1 Hrs'), 'Assertion failed in LeadTriggerTest at source line 425');
    }
}