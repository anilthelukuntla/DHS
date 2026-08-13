@IsTest
/** Verifies PPF deliverable selection and manifest generation. */
private class IntelDeliverablesControllerTest {
    @IsTest
    static void createsSelectedCaseManifest() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
            Contact__c subject = new Contact__c(
                First_Name__c = 'Manifest',
                Last_Name__c = 'Subject',
                Email__c = 'manifest-subject@example.com',
                SSN__c = '123-45-6789'
            );
            insert subject;
            Case__c caseRecord = new Case__c(
                Contact__c = subject.Id,
                Case_Number__c = 'MANIFEST-CASE',
                Current_Task__c = 'QA Review Completed',
                Subject_Type__c = 'Applicant',
                Assigned_To__c = UserInfo.getUserId()
            );
            insert caseRecord;
            Document__c documentRecord = new Document__c(
                Case__c = caseRecord.Id,
                Name__c = 'ROIReport'
            );
            insert documentRecord;
            insert new Attachment(
                ParentId = documentRecord.Id,
                Name = 'roi.pdf',
                Body = Blob.valueOf('manifest content')
            );

            IntelDeliverablesController controller =
                new IntelDeliverablesController();
            controller.selectedcaseOptions.add(
                new SelectOption(caseRecord.Id, caseRecord.Case_Number__c)
            );
            controller.selectedVersion = '1';
            controller.downloadmanifestaction();

            System.assertNotEquals(null, controller.manifestActionAttachmentId, 'Assertion failed in IntelDeliverablesControllerTest at source line 42');
            System.assertNotEquals(null, controller.caseOptions, 'Assertion failed in IntelDeliverablesControllerTest at source line 43');
            System.assertEquals(21, controller.versionOptions.size(), 'Assertion failed in IntelDeliverablesControllerTest at source line 44');
            System.assertEquals(
                1,
                [SELECT COUNT() FROM Intel_Deliverable__c]
            , 'Assertion failed in IntelDeliverablesControllerTest at source line 45');
        }
    }
}