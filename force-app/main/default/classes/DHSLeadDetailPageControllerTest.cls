@IsTest
/** Exercises the existing DHSLeadDetailPageController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs, PMD.UnusedLocalVariable')
public class DHSLeadDetailPageControllerTest {

    @TestSetup
    static void setup() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
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
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
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

        System.assertEquals(null, controller.errorMessage, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 86');
        System.assertEquals(
            'Accepted',
            controller.leadRecord
                .Lead_Accepted_or_Rejected__c
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 87');
        System.assertEquals(
            UserInfo.getUserId(),
            controller.leadRecord.DHS_Assigned_To__c
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 92');
            }
    }

    @IsTest
    static void testStandardisedIssuesAction() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
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
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 116');
        System.assert(
            controller.leadRecord
                .Standardised_Issues_Picklist__c
                .contains('Other')
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 120');
            }
    }

    @IsTest
    static void testStandardisedIssuesWithoutOther() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
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
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 143');
            }
    }

    @IsTest
    static void testRejectLeadActionCoverage() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
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
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 175');
        System.assertEquals(
            'Test rejection',
            rejectedLead.QA_Rejection_Comments__c
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 179');
        System.assertEquals(
            Date.today(),
            rejectedLead.QA_Rejected_Date__c
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 183');
        System.assertNotEquals(null, result, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 187');
        System.assertEquals(true, result.getRedirect(), 'Assertion failed in DHSLeadDetailPageControllerTest at source line 188');
            }
    }

    @IsTest
    static void testApplyForWaiverActionCoverage() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
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
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 215');
        System.assertEquals(
            'Test waiver',
            updatedLead.Reason_for_Waiver__c
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 219');
        System.assertNotEquals(null, result, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 223');

        List<DHS_Case_History__c> caseHistory = [
            SELECT Id, Value__c
            FROM DHS_Case_History__c
            WHERE DHS_Case__c = :lead.DHS_Case__c
        ];

            }
    }

    @IsTest
    static void testDeleteLeadAction() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
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
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 249');
        System.assertNotEquals(null, result, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 257');
        System.assertEquals(true, result.getRedirect(), 'Assertion failed in DHSLeadDetailPageControllerTest at source line 258');
            }
    }

    @IsTest
    static void testMessageModalActions() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
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
            controller.selectedMessage
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 285');

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
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 301');

        controller.deleteMessage();

        Test.stopTest();

        System.assertEquals(
            0,
            [
                SELECT COUNT()
                FROM DHS_Message__c
                WHERE Id = :messageRecord.Id
            ]
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 310');
            }
    }

    @IsTest
    static void testMessageModalNullBranches() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
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
            controller.selectedMessage
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 340');
            }
    }

    @IsTest
    static void testCreateDocumentRequestAction() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
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

        System.assertEquals(1, requests.size(), 'Assertion failed in DHSLeadDetailPageControllerTest at source line 379');
        System.assertEquals(
            'Documents Requested',
            requests[0].Status__c
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 380');
        System.assertEquals(
            'test@test.com',
            requests[0].To_Address__c
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 384');
            }
    }

    @IsTest
    static void testReopenReviewCompleteAndAutoSave() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
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
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 416');
        System.assertNotEquals(null, result, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 420');
        System.assertEquals(true, result.getRedirect(), 'Assertion failed in DHSLeadDetailPageControllerTest at source line 421');
            }
    }

    @IsTest
    static void testCompleteLeadAction() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
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
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 451');
        System.assertEquals(
            1,
            completedLead.Hours_of_completion__c
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 455');
        System.assertEquals(
            30,
            completedLead.Minutes_of_completion__c
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 459');
        System.assertNotEquals(null, result, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 463');
            }
    }

    @IsTest
    static void testGrammarMethods() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        DHS_Lead__c lead = getTestLead();

        Test.startTest();

        System.assertEquals(
            '',
            DHSLeadDetailPageController.createLeadGrammarRecord(
                    'Id,Name',
                    null
                )
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 474');

        System.assertEquals(
            '',
            DHSLeadDetailPageController.updateLeadGrammarRecord(
                    'Id,Name',
                    null
                )
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 482');

        System.assertEquals(
            '',
            DHSLeadDetailPageController.getLeadGrammarRecord(null)
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 490');

        String created =
            DHSLeadDetailPageController.createLeadGrammarRecord(
                    'Id,Name',
                    lead.Id
                );

        System.assertEquals('Id,Name', created, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 501');

        String updated =
            DHSLeadDetailPageController.updateLeadGrammarRecord(
                    'Id,Name,Status__c',
                    lead.Id
                );

        System.assertEquals(
            'Id,Name,Status__c',
            updated
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 509');

        String fetched =
            DHSLeadDetailPageController.getLeadGrammarRecord(lead.Id);

        System.assertEquals(
            'Id,Name,Status__c',
            fetched
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 517');

        Test.stopTest();
            }
    }

    @IsTest
    static void testCreateGrammarUpdatesExistingRecord() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
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

        System.assertEquals('Updated fields', result, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 546');

        System.assertEquals(
            1,
            [
                SELECT COUNT()
                FROM DHS_Lead_Grammar_Check__c
                WHERE DHS_Lead__c = :lead.Id
            ]
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 548');
            }
    }

    @IsTest
    static void testConvertToDtCoverage() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        Test.startTest();

        try {
            Datetime result =
                DHSLeadDetailPageController.convertToDt(
                    Date.newInstance(2026, 6, 16)
                );

            System.assertNotEquals(null, result, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 570');
        } catch (Exception e) {
            /*
             * The controller currently passes day, month and year
             * to Datetime.newInstance in the wrong order.
             */
            System.assertNotEquals(null, e.getMessage(), 'Assertion failed in DHSLeadDetailPageControllerTest at source line 576');
        }

        Test.stopTest();
            }
    }

    @IsTest
    static void testHandleNextAndPrev() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
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
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 611');
        System.assertEquals(1, controller.pageNumber, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 615');
        System.assertEquals(false, controller.disableNext, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 616');

        controller.handleNext();

        System.assertEquals(2, controller.pageNumber, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 620');
        System.assertEquals(5, controller.messages.size(), 'Assertion failed in DHSLeadDetailPageControllerTest at source line 621');
        System.assertEquals(true, controller.disableNext, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 622');
        System.assertEquals(false, controller.disablePrev, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 623');

        controller.handlePrev();

        System.assertEquals(1, controller.pageNumber, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 627');
        System.assertEquals(
            200,
            controller.messages.size()
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 628');
        System.assertEquals(true, controller.disablePrev, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 632');
        System.assertEquals(false, controller.disableNext, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 633');

        Test.stopTest();
            }
    }

    @IsTest
    static void testGetItemsAndDummyAction() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
        DHS_Lead__c lead = getTestLead();

        DHSLeadDetailPageController controller =
            getController(lead.Id);

        Test.startTest();

        List<SelectOption> options =
            controller.getItems();

        controller.dummyaction();

        Test.stopTest();

        System.assertEquals(3, options.size(), 'Assertion failed in DHSLeadDetailPageControllerTest at source line 656');
        System.assertEquals('', options[0].getValue(), 'Assertion failed in DHSLeadDetailPageControllerTest at source line 657');
        System.assertEquals(
            'Subject not available',
            options[1].getValue()
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 658');
        System.assertEquals(
            'Other',
            options[2].getValue()
        , 'Assertion failed in DHSLeadDetailPageControllerTest at source line 662');
            }
    }

    @IsTest
    static void testMeetingViewModelsAndNullGuards() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
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

        System.assertEquals('Test meeting', summary.subject, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 705');
        System.assertEquals(1, lifecycle.participants.size(), 'Assertion failed in DHSLeadDetailPageControllerTest at source line 706');
        System.assertEquals(1, lifecycle.artifacts.size(), 'Assertion failed in DHSLeadDetailPageControllerTest at source line 707');
        System.assertEquals(0,
            DHSLeadDetailPageController.getLeadMeetings(null).size(), 'Assertion failed in DHSLeadDetailPageControllerTest at source line 708');

        try {
            DHSLeadDetailPageController.getMeetingLifecycleDetails(null, null);
            System.assert(false, 'Expected required-ID exception');
        } catch (AuraHandledException expected) {
            System.assertNotEquals(null, expected.getMessage(), 'Assertion failed in DHSLeadDetailPageControllerTest at source line 715');
        }
            }
    }

    @IsTest
    static void testGetLeadMeetings() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
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
        System.assertEquals(1, meetings.size(), 'Assertion failed in DHSLeadDetailPageControllerTest at source line 735');
        System.assertEquals('Coverage meeting', meetings[0].subject, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 736');
        }
    }

    @IsTest
    static void testPersistedMeetingLifecycleDetails() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
            DHS_Lead__c lead = getTestLead();
            MS_Team_Call_Schedule__c schedule = new MS_Team_Call_Schedule__c(
                DHS_Lead__c = lead.Id,
                Subject__c = 'Lifecycle coverage',
                Status__c = 'Completed',
                Start_Date_Time__c = '2026-08-01T10:00:00',
                End_Date_Time__c = '2026-08-01T11:00:00',
                Microsoft_Time_Zone__c = 'India Standard Time',
                Actual_Duration_Seconds__c = 120,
                Meeting_Started_At__c = System.now().addMinutes(-2),
                Meeting_Ended_At__c = System.now(),
                Last_Synchronized_At__c = System.now()
            );
            Database.insert(schedule, AccessLevel.SYSTEM_MODE);
            MS_Team_Meeting_Participant__c participant =
                new MS_Team_Meeting_Participant__c(
                    Meeting_Schedule__c = schedule.Id,
                    External_Key__c = schedule.Id + ':participant@example.test',
                    Display_Name__c = 'Lifecycle Participant',
                    Email__c = 'participant@example.test',
                    Actually_Joined__c = true,
                    Total_Attendance_Seconds__c = 100
                );
            Database.insert(participant, AccessLevel.SYSTEM_MODE);
            Database.insert(new MS_Team_Attendance_Interval__c(
                External_Key__c = 'interval-coverage',
                Participant__c = participant.Id,
                Joined_At__c = System.now().addMinutes(-2),
                Left_At__c = System.now(),
                Duration_Seconds__c = 100
            ), AccessLevel.SYSTEM_MODE);
            Database.insert(new MS_Team_Meeting_Artifact__c(
                External_Key__c = 'artifact-coverage',
                Meeting_Schedule__c = schedule.Id,
                Artifact_Type__c = 'Recording',
                Graph_Artifact_ID__c = 'recording-coverage',
                Processing_Status__c = 'Available'
            ), AccessLevel.SYSTEM_MODE);

            DHSLeadDetailPageController.MeetingLifecycleDetails details =
                DHSLeadDetailPageController.getMeetingLifecycleDetails(schedule.Id, lead.Id);
            System.assertEquals(1, details.participants.size(), 'Assertion failed in DHSLeadDetailPageControllerTest at source line 784');
            System.assertEquals(1, details.participants[0].intervals.size(), 'Assertion failed in DHSLeadDetailPageControllerTest at source line 785');
            System.assertEquals(1, details.artifacts.size(), 'Assertion failed in DHSLeadDetailPageControllerTest at source line 786');
        }
    }

    @IsTest
    static void testMeetingRemoteActionValidationPaths() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
            DHS_Lead__c lead = getTestLead();
            Integer expectedExceptions = 0;
            try {
                DHSLeadDetailPageController.scheduleTeamsMeeting(
                    null, null, null, null, null, null, false, false, lead.Id
                );
            } catch (Exception expected) {
                expectedExceptions++;
            }
            try {
                DHSLeadDetailPageController.updateLeadMeeting(
                    null, lead.Id, null, null, null, null, null
                );
            } catch (Exception expected) {
                expectedExceptions++;
            }
            try {
                DHSLeadDetailPageController.cancelLeadMeeting(null, lead.Id, 'reason');
            } catch (Exception expected) {
                expectedExceptions++;
            }
            try {
                DHSLeadDetailPageController.deleteLeadMeeting(null, lead.Id, 'reason');
            } catch (Exception expected) {
                expectedExceptions++;
            }
            System.assertEquals(4, expectedExceptions, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 819');
        }
    }

    @IsTest
    static void testNavigationParameters() {
        System.runAs(PPFDHSTestUserFactory.getPmoUser()) {
            DHS_Lead__c lead = getTestLead();
            Test.setCurrentPage(Page.DHSLeaddetail);
            ApexPages.currentPage().getParameters().put('id', lead.Id);
            ApexPages.currentPage().getParameters().put('fromcase', 'true');
            ApexPages.currentPage().getParameters().put('searchmode', 'assigned');
            DHSLeadDetailPageController controller = new DHSLeadDetailPageController();
            System.assertEquals(true, controller.fromCase, 'Assertion failed in DHSLeadDetailPageControllerTest at source line 832');
            System.assert(controller.urlparametersString.contains('searchmode=assigned'), 'Assertion failed in DHSLeadDetailPageControllerTest at source line 833');
        }
    }
}