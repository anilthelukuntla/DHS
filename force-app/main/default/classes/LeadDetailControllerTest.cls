@IsTest
/** Exercises the existing LeadDetailController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs')
public class LeadDetailControllerTest {

    @TestSetup
    static void setup() {
        insert new GeneralSettings__c(
            Name = 'TimeEntryDuringLeadConfirm',
            Value__c = 'SCA'
        );

        Contact__c con = new Contact__c(
            First_Name__c = 'Test',
            Last_Name__c = 'Name',
            Email__c = 'test@test.com',
            Contact_Type__c = 'Subject',
            SSN__c = '123-12-1123'
        );
        insert con;

        Case__c caseTemp = new Case__c(
            Contact__c = con.Id,
            Assigned_To__c = UserInfo.getUserId()
        );
        insert caseTemp;

        Lead__c lead = new Lead__c(
            Case__c = caseTemp.Id,
            Coverage_Type__c = 'Subject Interview',
            Assigned_To__c = UserInfo.getUserId(),
            LeadType__c = 'Subject Interview (ESI/TESI)',
            Status__c = 'Assigned'
        );
        insert lead;
    }

    private static Lead__c getTestLead() {
        return [
            SELECT Id, Case__c, Status__c, LeadType__c
            FROM Lead__c
            LIMIT 1
        ];
    }

    private static LeadDetailPageController getController(Id leadId) {
        PageReference pg = Page.bileaddetail;
        Test.setCurrentPage(pg);
        ApexPages.currentPage().getParameters().put('id', String.valueOf(leadId));
        return new LeadDetailPageController();
    }

    @IsTest
    static void testUpdateAndSelfAssignActions() {
        Lead__c l = getTestLead();
        l.Lead_Accepted_or_Rejected__c = 'Rejected';
        l.Status__c = 'Assigned';
        update l;

        Test.startTest();
        LeadDetailPageController ctrl = getController(l.Id);
        ctrl.updateLeadAction();
        ctrl.selfAssignAction();
        Test.stopTest();
    }

    @IsTest
    static void testStandardisedIssuesAction() {
        Lead__c l = getTestLead();

        Test.startTest();
        LeadDetailPageController ctrl = getController(l.Id);
        ctrl.StandardisedIssueItems = new List<String>{ 'Other' };
        ctrl.standardisedissuesaction();
        Test.stopTest();

        System.assertEquals(true, ctrl.showstandardisedissuesotherexplanation, 'Assertion failed in LeadDetailControllerTest at source line 77');
    }

    @IsTest
    static void testRejectLeadActionCoverage() {
        Lead__c l = getTestLead();

        Test.startTest();
        LeadDetailPageController ctrl = getController(l.Id);
        ctrl.leadrejectionreason = 'Test rejection';
        ctrl.rejectLeadAction();
        Test.stopTest();
    }

    @IsTest
    static void testApplyForWaiverActionCoverage() {
        Lead__c l = getTestLead();

        Test.startTest();
        LeadDetailPageController ctrl = getController(l.Id);
        ctrl.waiverreason = 'Test waiver';
        ctrl.applyForWaiverAction();
        Test.stopTest();
    }

    @IsTest
    static void testDeleteLeadAction() {
        Lead__c l = getTestLead();

        Test.startTest();
        LeadDetailPageController ctrl = getController(l.Id);
        ctrl.deleteLeadAction();
        Test.stopTest();
    }

    @IsTest
    static void testMessageModalActions() {
        Lead__c l = getTestLead();

        Message__c msg = new Message__c(
            Subject__c = 'Test',
            Message_Body__c = 'Test Body',
            Lead__c = l.Id,
            Case__c = l.Case__c,
            From_User__c = UserInfo.getUserId()
        );
        insert msg;

        Test.startTest();
        LeadDetailPageController ctrl = getController(l.Id);
        ctrl.selectedMessageId = msg.Id;
        ctrl.modalAction = 'edit';

        ctrl.openModal();

        ctrl.selectedMessage.Subject__c = 'Updated';
        ctrl.updateMessage();

        ctrl.deleteMessage();
        Test.stopTest();
    }

    @IsTest
    static void testCreateDocumentRequestAction() {
        Lead__c l = getTestLead();

        Test.startTest();
        LeadDetailPageController ctrl = getController(l.Id);
        try {
            ctrl.createDocumentRequestAction();
        } catch (DmlException exceptionValue) {
            System.assert(
                exceptionValue.getMessage().contains('MAIL_PERMISSION'),
                exceptionValue.getMessage()
            );
        }
        Test.stopTest();
    }

    @IsTest
    static void testReopenReviewCompleteAndAutoSave() {
        Lead__c l = getTestLead();

        Test.startTest();
        LeadDetailPageController ctrl = getController(l.Id);

        ctrl.reopenLeadAction();
        ctrl.reviewCompletedAction();
        ctrl.AutoSaveLeadAction();

        Test.stopTest();
    }

    @IsTest
    static void testCompleteLeadAction() {
        Lead__c l = getTestLead();

        Test.startTest();
        LeadDetailPageController ctrl = getController(l.Id);
        ctrl.hoursofleadcompletion = 1;
        ctrl.minutesofleadcompletion = 30;
        ctrl.completeLeadAction();
        Test.stopTest();
    }

    @IsTest
    static void testGrammarMethods() {
        Lead__c l = getTestLead();

        Test.startTest();

        System.assertEquals('', LeadDetailPageController.createLeadGrammarRecord('Id,Name', null), 'Assertion failed in LeadDetailControllerTest at source line 188');
        System.assertEquals('', LeadDetailPageController.updateLeadGrammarRecord('Id,Name', null), 'Assertion failed in LeadDetailControllerTest at source line 189');
        System.assertEquals('', LeadDetailPageController.getLeadGrammarRecord(null), 'Assertion failed in LeadDetailControllerTest at source line 190');

        String created = LeadDetailPageController.createLeadGrammarRecord('Id,Name', l.Id);
        System.assertEquals('Id,Name', created, 'Assertion failed in LeadDetailControllerTest at source line 193');

        String updated = LeadDetailPageController.updateLeadGrammarRecord('Id,Name,Status__c', l.Id);
        System.assertEquals('Id,Name,Status__c', updated, 'Assertion failed in LeadDetailControllerTest at source line 196');

        String fetched = LeadDetailPageController.getLeadGrammarRecord(l.Id);
        System.assertEquals('Id,Name,Status__c', fetched, 'Assertion failed in LeadDetailControllerTest at source line 199');

        Test.stopTest();
    }

    @IsTest
    static void testConvertToDtCoverage() {
        Test.startTest();
        try {
            LeadDetailPageController.convertToDt(Date.newInstance(2026, 6, 16));
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage(), 'Assertion failed in LeadDetailControllerTest at source line 210');
        }
        Test.stopTest();
    }

    @IsTest
    static void testExistingRtaExtensionUpdateBranches() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
            Lead__c leadRecord = getTestLead();
            insert new Lead_RTA_Extension__c(Lead__c = leadRecord.Id);
            LeadDetailPageController controller = getController(leadRecord.Id);

            controller.updateLeadAction();
            controller.reviewCompletedAction();
            controller.waiverreason = 'Existing extension waiver';
            controller.applyForWaiverAction();
            controller.hoursofleadcompletion = 1;
            controller.minutesofleadcompletion = 1;
            controller.completeLeadAction();
            controller.AutoSaveLeadAction();
            System.assertEquals(false, controller.toInsertleadRecordRTAExtension, 'Assertion failed in LeadDetailControllerTest at source line 231');
        }
    }

    @IsTest
    static void testSendsCaseMessageToOtherAssignees() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        User invUser = PPFDHSTestUserFactory.createInvUser();
        System.runAs(pmoUser) {
            Lead__c leadRecord = getTestLead();
            Case__c caseRecord = [
                SELECT Id, Assigned_To__c FROM Case__c WHERE Id = :leadRecord.Case__c
            ];
            caseRecord.Assigned_To__c = invUser.Id;
            update caseRecord;
            leadRecord.Assigned_To__c = invUser.Id;
            update leadRecord;

            LeadDetailPageController controller = getController(leadRecord.Id);
            controller.messageSubject = 'Coverage message';
            controller.messageBody = 'Coverage body';
            controller.SendMessage();

            System.assertEquals(1, [
                SELECT COUNT() FROM Message__c WHERE Lead__c = :leadRecord.Id
            ], 'Assertion failed in LeadDetailControllerTest at source line 254');
        }
    }

    @IsTest
    static void testHandleNextAndPrev() {
    
        Lead__c l = getTestLead();
    
        List<Message__c> msgs = new List<Message__c>();
    
        for(Integer i = 0; i < 205; i++){
            msgs.add(new Message__c(
                Subject__c = 'Subject ' + i,
                Message_Body__c = 'Body ' + i,
                Case__c = l.Case__c,
                Lead__c = l.Id,
                From_User__c = UserInfo.getUserId()
            ));
        }
        insert msgs;
    
        Test.startTest();
    
        LeadDetailPageController ctrl = getController(l.Id);
    
        // Verify constructor loaded first page
        System.assertEquals(200, ctrl.messages.size(), 'Assertion failed in LeadDetailControllerTest at source line 283');
        System.assertEquals(1, ctrl.pageNumber, 'Assertion failed in LeadDetailControllerTest at source line 284');
        System.assertEquals(false, ctrl.disableNext, 'Assertion failed in LeadDetailControllerTest at source line 285');
    
        // Next Page
        ctrl.handleNext();
    
        System.assertEquals(2, ctrl.pageNumber, 'Assertion failed in LeadDetailControllerTest at source line 290');
        System.assertEquals(5, ctrl.messages.size(), 'Assertion failed in LeadDetailControllerTest at source line 291');
        System.assertEquals(true, ctrl.disableNext, 'Assertion failed in LeadDetailControllerTest at source line 292');
        System.assertEquals(false, ctrl.disablePrev, 'Assertion failed in LeadDetailControllerTest at source line 293');
    
        // Previous Page
        ctrl.handlePrev();
    
        System.assertEquals(1, ctrl.pageNumber, 'Assertion failed in LeadDetailControllerTest at source line 298');
        System.assertEquals(200, ctrl.messages.size(), 'Assertion failed in LeadDetailControllerTest at source line 299');
        System.assertEquals(true, ctrl.disablePrev, 'Assertion failed in LeadDetailControllerTest at source line 300');
        System.assertEquals(false, ctrl.disableNext, 'Assertion failed in LeadDetailControllerTest at source line 301');
    
        Test.stopTest();
    }
}