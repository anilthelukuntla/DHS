@IsTest
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

        System.assertEquals(true, ctrl.showstandardisedissuesotherexplanation);
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
        ctrl.createDocumentRequestAction();
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

        System.assertEquals('', LeadDetailPageController.createLeadGrammarRecord('Id,Name', null));
        System.assertEquals('', LeadDetailPageController.updateLeadGrammarRecord('Id,Name', null));
        System.assertEquals('', LeadDetailPageController.getLeadGrammarRecord(null));

        String created = LeadDetailPageController.createLeadGrammarRecord('Id,Name', l.Id);
        System.assertEquals('Id,Name', created);

        String updated = LeadDetailPageController.updateLeadGrammarRecord('Id,Name,Status__c', l.Id);
        System.assertEquals('Id,Name,Status__c', updated);

        String fetched = LeadDetailPageController.getLeadGrammarRecord(l.Id);
        System.assertEquals('Id,Name,Status__c', fetched);

        Test.stopTest();
    }

    @IsTest
    static void testConvertToDtCoverage() {
        Test.startTest();
        try {
            LeadDetailPageController.convertToDt(Date.newInstance(2026, 6, 16));
        } catch (Exception e) {
            System.assertNotEquals(null, e.getMessage());
        }
        Test.stopTest();
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
        System.assertEquals(200, ctrl.messages.size());
        System.assertEquals(1, ctrl.pageNumber);
        System.assertEquals(false, ctrl.disableNext);
    
        // Next Page
        ctrl.handleNext();
    
        System.assertEquals(2, ctrl.pageNumber);
        System.assertEquals(5, ctrl.messages.size());
        System.assertEquals(true, ctrl.disableNext);
        System.assertEquals(false, ctrl.disablePrev);
    
        // Previous Page
        ctrl.handlePrev();
    
        System.assertEquals(1, ctrl.pageNumber);
        System.assertEquals(200, ctrl.messages.size());
        System.assertEquals(true, ctrl.disablePrev);
        System.assertEquals(false, ctrl.disableNext);
    
        Test.stopTest();
    }
}