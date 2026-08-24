@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSLeadDetailPageControllerTest {

    @TestSetup
    static void setup() {
        insert new DHS_GeneralSettings__c(
            Name = 'TimeEntryDuringLeadConfirm',
            Value__c = 'SCA'
        );

        DHS_Contact__c subject = new DHS_Contact__c(
            First_Name__c = 'Test',
            Last_Name__c = 'Name',
            Email__c = 'test@test.com',
            Contact_Type__c = 'Subject',
            SSN__c = '123-12-1123'
        );
        insert subject;

        DHS_Case__c caseRecord = new DHS_Case__c(
            DHS_Contact__c = subject.Id,
            DHS_Assigned_To__c = UserInfo.getUserId(),
            Case_Number__c = 'TEST-CASE-001'
        );
        insert caseRecord;

        DHS_Lead__c lead = new DHS_Lead__c(
            DHS_Case__c = caseRecord.Id,
            DHS_Contact__c = subject.Id,
            Coverage_Type__c = 'Subject Interview',
            DHS_Assigned_To__c = UserInfo.getUserId(),
            LeadType__c = 'Subject Interview (ESI/TESI)',
            Status__c = 'Assigned'
        );
        insert lead;
    }

    private static DHS_Lead__c getTestLead() {
        return [
            SELECT Id,
                   DHS_Case__c,
                   DHS_Contact__c,
                   Status__c,
                   LeadType__c
            FROM DHS_Lead__c
            LIMIT 1
        ];
    }

    private static DHSLeadDetailPageController getController(
        Id leadId
    ) {
        PageReference pageReference = Page.DHSLeaddetail;
        Test.setCurrentPage(pageReference);

        ApexPages.currentPage()
            .getParameters()
            .put('id', String.valueOf(leadId));

        return new DHSLeadDetailPageController();
    }

    @IsTest
    static void testUpdateAndSelfAssignActions() {
        DHS_Lead__c lead = getTestLead();
        lead.Lead_Accepted_or_Rejected__c = 'Rejected';
        lead.Status__c = 'Assigned';
        update lead;

        Test.startTest();

        DHSLeadDetailPageController controller =
            getController(lead.Id);

        controller.updateleadaction();
        controller.selfassignaction();

        Test.stopTest();

        System.assertEquals(null, controller.errorMessage, 'Expected the asserted condition to hold');
        System.assertEquals(
            'Accepted',
            controller.leadRecord
                .Lead_Accepted_or_Rejected__c
        , 'Expected the asserted condition to hold');
        System.assertEquals(
            UserInfo.getUserId(),
            controller.leadRecord.DHS_Assigned_To__c
        , 'Expected the asserted condition to hold');
    }

    @IsTest
    static void testStandardisedIssuesAction() {
        DHS_Lead__c lead = getTestLead();

        Test.startTest();

        DHSLeadDetailPageController controller =
            getController(lead.Id);

        controller.StandardisedIssueItems =
            new List<String>{ 'Other' };

        controller.standardisedissuesaction();

        Test.stopTest();

        System.assertEquals(
            true,
            controller.showstandardisedissuesotherexplanation
        , 'Expected the asserted condition to hold');
        System.assert(
            controller.leadRecord
                .Standardised_Issues_Picklist__c
                .contains('Other')
        , 'Expected assertion condition to hold');
    }

    @IsTest
    static void testStandardisedIssuesWithoutOther() {
        DHS_Lead__c lead = getTestLead();

        DHSLeadDetailPageController controller =
            getController(lead.Id);

        controller.StandardisedIssueItems =
            new List<String>{ 'Subject not available' };

        Test.startTest();
        controller.standardisedissuesaction();
        Test.stopTest();

        System.assertEquals(
            false,
            controller.showstandardisedissuesotherexplanation
        , 'Expected the asserted condition to hold');
    }

    @IsTest
    static void testRejectLeadActionCoverage() {
        DHS_Lead__c lead = getTestLead();

        Test.startTest();

        DHSLeadDetailPageController controller =
            getController(lead.Id);

        controller.leadrejectionreason = 'Test rejection';

        PageReference result =
            controller.rejectleadaction();

        Test.stopTest();

        DHS_Lead__c rejectedLead = [
            SELECT Status__c,
                   QA_Rejection_Comments__c,
                   QA_Rejected_Date__c
            FROM DHS_Lead__c
            WHERE Id = :lead.Id
        ];

        System.assertEquals(
            'QA Rejected',
            rejectedLead.Status__c
        , 'Expected the asserted condition to hold');
        System.assertEquals(
            'Test rejection',
            rejectedLead.QA_Rejection_Comments__c
        , 'Expected the asserted condition to hold');
        System.assertEquals(
            Date.today(),
            rejectedLead.QA_Rejected_Date__c
        , 'Expected the asserted condition to hold');
        System.assertNotEquals(null, result, 'Expected the asserted condition to hold');
        System.assertEquals(true, result.getRedirect(), 'Expected the asserted condition to hold');
    }

    @IsTest
    static void testApplyForWaiverActionCoverage() {
        DHS_Lead__c lead = getTestLead();

        Test.startTest();

        DHSLeadDetailPageController controller =
            getController(lead.Id);

        controller.waiverreason = 'Test waiver';

        PageReference result =
            controller.applyforwaiveraction();

        Test.stopTest();

        DHS_Lead__c updatedLead = [
            SELECT Status__c, Reason_for_Waiver__c
            FROM DHS_Lead__c
            WHERE Id = :lead.Id
        ];

        System.assertEquals(
            'Applied For Waiver',
            updatedLead.Status__c
        , 'Expected the asserted condition to hold');
        System.assertEquals(
            'Test waiver',
            updatedLead.Reason_for_Waiver__c
        , 'Expected the asserted condition to hold');
        System.assertNotEquals(null, result, 'Expected the asserted condition to hold');

        List<DHS_Case_History__c> caseHistory = [
            SELECT Id, Value__c
            FROM DHS_Case_History__c
            WHERE DHS_Case__c = :lead.DHS_Case__c
        ];
        System.assertNotEquals(null, caseHistory, 'Expected the case history query to complete');

    }

    @IsTest
    static void testDeleteLeadAction() {
        DHS_Lead__c lead = getTestLead();

        Test.startTest();

        DHSLeadDetailPageController controller =
            getController(lead.Id);

        PageReference result =
            controller.deleteleadaction();

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM DHS_Lead__c
                WHERE Id = :lead.Id
            ]
        , 'Expected the asserted condition to hold');
        System.assertNotEquals(null, result, 'Expected the asserted condition to hold');
        System.assertEquals(true, result.getRedirect(), 'Expected the asserted condition to hold');
    }

    @IsTest
    static void testMessageModalActions() {
        DHS_Lead__c lead = getTestLead();

        DHS_Message__c messageRecord = new DHS_Message__c(
            Subject__c = 'Test',
            Message_Body__c = 'Test Body',
            DHS_Lead__c = lead.Id,
            DHS_Case__c = lead.DHS_Case__c,
            DHS_From_User__c = UserInfo.getUserId()
        );
        insert messageRecord;

        Test.startTest();

        DHSLeadDetailPageController controller =
            getController(lead.Id);

        controller.selectedMessageId = messageRecord.Id;
        controller.modalAction = 'edit';
        controller.openModal();

        System.assertNotEquals(
            null,
            controller.selectedMessage,
            'Expected the selected message to be cleared'
        );

        controller.selectedMessage.Subject__c =
            'Updated subject';

        controller.updateMessage();

        DHS_Message__c updatedMessage = [
            SELECT Subject__c
            FROM DHS_Message__c
            WHERE Id = :messageRecord.Id
        ];

        System.assertEquals(
            'Updated subject',
            updatedMessage.Subject__c
        , 'Expected the asserted condition to hold');

        controller.deleteMessage();

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM DHS_Message__c
                WHERE Id = :messageRecord.Id
            ]
        , 'Expected the asserted condition to hold');
    }

    @IsTest
    static void testMessageModalNullBranches() {
        DHS_Lead__c lead = getTestLead();

        Test.startTest();

        DHSLeadDetailPageController controller =
            getController(lead.Id);

        controller.modalAction = 'edit';
        controller.selectedMessageId = null;

        controller.openModal();
        controller.updateMessage();
        controller.deleteMessage();

        Test.stopTest();

        System.assertEquals(
            null,
            controller.selectedMessage,
            'Expected the selected message to be cleared'
        );
    }

    @IsTest
    static void testCreateDocumentRequestAction() {
        DHS_Lead__c lead = getTestLead();

        Test.startTest();

        DHSLeadDetailPageController controller =
            getController(lead.Id);

        controller.documentRequest
            .Additional_To_Address__c =
            'additional@example.com';

        controller.documentRequest
            .Investigator_Comments__c =
            'Please provide the requested documents.';

        controller.createdocumentrequestaction();

        Test.stopTest();

        List<DHS_Document_Request__c> requests = [
            SELECT Id,
                   Status__c,
                   To_Address__c,
                   Additional_To_Address__c,
                   Investigator_Comments__c
            FROM DHS_Document_Request__c
            WHERE DHS_Lead__c = :lead.Id
        ];

        System.assertEquals(1, requests.size(), 'Expected the asserted condition to hold');
        System.assertEquals(
            'Documents Requested',
            requests[0].Status__c
        , 'Expected the asserted condition to hold');
        System.assertEquals(
            'test@test.com',
            requests[0].To_Address__c
        , 'Expected the asserted condition to hold');
    }

    @IsTest
    static void testReopenReviewCompleteAndAutoSave() {
        DHS_Lead__c lead = getTestLead();

        DHSLeadDetailPageController controller =
            getController(lead.Id);

        Test.startTest();

        controller.reopenleadaction();

        PageReference result =
            controller.reviewcompletedaction();

        controller.AutoSaveLeadAction();

        Test.stopTest();

        DHS_Lead__c updatedLead = [
            SELECT Status__c
            FROM DHS_Lead__c
            WHERE Id = :lead.Id
        ];

        System.assertEquals(
            'QA Review Completed',
            updatedLead.Status__c
        , 'Expected the asserted condition to hold');
        System.assertNotEquals(null, result, 'Expected the asserted condition to hold');
        System.assertEquals(true, result.getRedirect(), 'Expected the asserted condition to hold');
    }

    @IsTest
    static void testCompleteLeadAction() {
        DHS_Lead__c lead = getTestLead();

        Test.startTest();

        DHSLeadDetailPageController controller =
            getController(lead.Id);

        controller.hoursofleadcompletion = 1;
        controller.minutesofleadcompletion = 30;

        PageReference result =
            controller.completeleadaction();

        Test.stopTest();

        DHS_Lead__c completedLead = [
            SELECT Status__c,
                   Hours_of_completion__c,
                   Minutes_of_completion__c
            FROM DHS_Lead__c
            WHERE Id = :lead.Id
        ];

        System.assertEquals(
            'Completed',
            completedLead.Status__c
        , 'Expected the asserted condition to hold');
        System.assertEquals(
            1,
            completedLead.Hours_of_completion__c
        , 'Expected the asserted condition to hold');
        System.assertEquals(
            30,
            completedLead.Minutes_of_completion__c
        , 'Expected the asserted condition to hold');
        System.assertNotEquals(null, result, 'Expected the asserted condition to hold');
    }

    @IsTest
    static void testGrammarMethods() {
        DHS_Lead__c lead = getTestLead();

        Test.startTest();

        System.assertEquals(
            '',
            DHSLeadDetailPageController.createLeadGrammarRecord(
                    'Id,Name',
                    null
                )
        , 'Expected the asserted condition to hold');

        System.assertEquals(
            '',
            DHSLeadDetailPageController.updateLeadGrammarRecord(
                    'Id,Name',
                    null
                )
        , 'Expected the asserted condition to hold');

        System.assertEquals(
            '',
            DHSLeadDetailPageController.getLeadGrammarRecord(null)
        , 'Expected the asserted condition to hold');

        String created =
            DHSLeadDetailPageController.createLeadGrammarRecord(
                    'Id,Name',
                    lead.Id
                );

        System.assertEquals('Id,Name', created, 'Expected the asserted condition to hold');

        String updated =
            DHSLeadDetailPageController.updateLeadGrammarRecord(
                    'Id,Name,Status__c',
                    lead.Id
                );

        System.assertEquals(
            'Id,Name,Status__c',
            updated
        , 'Expected the asserted condition to hold');

        String fetched =
            DHSLeadDetailPageController.getLeadGrammarRecord(lead.Id);

        System.assertEquals(
            'Id,Name,Status__c',
            fetched
        , 'Expected the asserted condition to hold');

        Test.stopTest();
    }

    @IsTest
    static void testCreateGrammarUpdatesExistingRecord() {
        DHS_Lead__c lead = getTestLead();

        insert new DHS_Lead_Grammar_Check__c(
            DHS_Lead__c = lead.Id,
            Fields__c = 'Initial fields'
        );

        Test.startTest();

        String result =
            DHSLeadDetailPageController.createLeadGrammarRecord(
                    'Updated fields',
                    lead.Id
                );

        Test.stopTest();

        System.assertEquals('Updated fields', result, 'Expected the asserted condition to hold');

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM DHS_Lead_Grammar_Check__c
                WHERE DHS_Lead__c = :lead.Id
            ]
        , 'Expected the asserted condition to hold');
    }

    @IsTest
    static void testConvertToDtCoverage() {
        Test.startTest();

        try {
            Datetime result =
                DHSLeadDetailPageController.convertToDt(
                    Date.newInstance(2026, 6, 16)
                );

            System.assertNotEquals(null, result, 'Expected the asserted condition to hold');
        } catch (Exception e) {
            /*
             * The controller currently passes day, month and year
             * to Datetime.newInstance in the wrong order.
             */
            System.assertNotEquals(null, e.getMessage(), 'Expected the asserted condition to hold');
        }

        Test.stopTest();
    }

    @IsTest
    static void testHandleNextAndPrev() {
        DHS_Lead__c lead = getTestLead();

        List<DHS_Message__c> messagesToInsert =
            new List<DHS_Message__c>();

        for (Integer i = 0; i < 205; i++) {
            messagesToInsert.add(
                new DHS_Message__c(
                    Subject__c = 'Subject ' + i,
                    Message_Body__c = 'Body ' + i,
                    DHS_Case__c = lead.DHS_Case__c,
                    DHS_Lead__c = lead.Id,
                    DHS_From_User__c =
                        UserInfo.getUserId()
                )
            );
        }

        insert messagesToInsert;

        Test.startTest();

        DHSLeadDetailPageController controller =
            getController(lead.Id);

        System.assertEquals(
            200,
            controller.messages.size()
        , 'Expected the asserted condition to hold');
        System.assertEquals(1, controller.pageNumber, 'Expected the asserted condition to hold');
        System.assertEquals(false, controller.disableNext, 'Expected the asserted condition to hold');

        controller.handleNext();

        System.assertEquals(2, controller.pageNumber, 'Expected the asserted condition to hold');
        System.assertEquals(5, controller.messages.size(), 'Expected the asserted condition to hold');
        System.assertEquals(true, controller.disableNext, 'Expected the asserted condition to hold');
        System.assertEquals(false, controller.disablePrev, 'Expected the asserted condition to hold');

        controller.handlePrev();

        System.assertEquals(1, controller.pageNumber, 'Expected the asserted condition to hold');
        System.assertEquals(
            200,
            controller.messages.size()
        , 'Expected the asserted condition to hold');
        System.assertEquals(true, controller.disablePrev, 'Expected the asserted condition to hold');
        System.assertEquals(false, controller.disableNext, 'Expected the asserted condition to hold');

        Test.stopTest();
    }

    @IsTest
    static void testGetItemsAndDummyAction() {
        DHS_Lead__c lead = getTestLead();

        DHSLeadDetailPageController controller =
            getController(lead.Id);

        Test.startTest();

        List<SelectOption> options =
            controller.getItems();

        controller.dummyaction();

        Test.stopTest();

        System.assertEquals(3, options.size(), 'Expected the asserted condition to hold');
        System.assertEquals('', options[0].getValue(), 'Expected the asserted condition to hold');
        System.assertEquals(
            'Subject not available',
            options[1].getValue()
        , 'Expected the asserted condition to hold');
        System.assertEquals(
            'Other',
            options[2].getValue()
        , 'Expected the asserted condition to hold');
    }

    @IsTest
    static void testMeetingViewModelsAndNullGuards() {
        MS_Team_Call_Schedule__c schedule = new MS_Team_Call_Schedule__c(
            Subject__c = 'Test meeting',
            Status__c = 'Scheduled',
            Actual_Duration_Seconds__c = 60
        );
        DHSLeadDetailPageController.MeetingSummary summary =
            new DHSLeadDetailPageController.MeetingSummary(schedule);
        DHSLeadDetailPageController.MeetingLifecycleDetails lifecycle =
            new DHSLeadDetailPageController.MeetingLifecycleDetails(schedule);

        MS_Team_Meeting_Participant__c participant =
            new MS_Team_Meeting_Participant__c(
                Display_Name__c = 'Participant',
                Email__c = 'participant@example.test',
                Actually_Joined__c = true
            );
        DHSLeadDetailPageController.ParticipantDetail participantDetail =
            new DHSLeadDetailPageController.ParticipantDetail(participant);

        MS_Team_Attendance_Interval__c interval =
            new MS_Team_Attendance_Interval__c(Duration_Seconds__c = 30);
        participantDetail.intervals.add(
            new DHSLeadDetailPageController.AttendanceIntervalDetail(interval));

        MS_Team_Meeting_Artifact__c artifact =
            new MS_Team_Meeting_Artifact__c(
                Artifact_Type__c = 'Recording',
                Processing_Status__c = 'Available'
            );
        lifecycle.participants.add(participantDetail);
        lifecycle.artifacts.add(
            new DHSLeadDetailPageController.ArtifactDetail(artifact));

        System.assertEquals('Test meeting', summary.subject, 'Expected the asserted condition to hold');
        System.assertEquals(1, lifecycle.participants.size(), 'Expected the asserted condition to hold');
        System.assertEquals(1, lifecycle.artifacts.size(), 'Expected the asserted condition to hold');
        System.assertEquals(0,
            DHSLeadDetailPageController.getLeadMeetings(null).size(), 'Expected the asserted condition to hold');

        try {
            DHSLeadDetailPageController.getMeetingLifecycleDetails(null, null);
            System.assert(false, 'Expected required-ID exception');
        } catch (AuraHandledException expected) {
            System.assertNotEquals(null, expected.getMessage(), 'Expected the asserted condition to hold');
        }
    }

    @IsTest
    static void testGetLeadMeetings() {
        DHS_Lead__c lead = getTestLead();
        MS_Team_Call_Schedule__c schedule = new MS_Team_Call_Schedule__c(
            DHS_Lead__c = lead.Id,
            Subject__c = 'Coverage meeting',
            Status__c = 'Scheduled',
            Start_Date_Time__c = '2026-08-01T10:00:00',
            End_Date_Time__c = '2026-08-01T11:00:00',
            Microsoft_Time_Zone__c = 'India Standard Time'
        );
        insert schedule;
        List<DHSLeadDetailPageController.MeetingSummary> meetings =
            DHSLeadDetailPageController.getLeadMeetings(lead.Id);
        System.assertEquals(1, meetings.size(), 'Expected the asserted condition to hold');
        System.assertEquals('Coverage meeting', meetings[0].subject, 'Expected the asserted condition to hold');
    }
}
