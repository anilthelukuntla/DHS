@IsTest
/** Exercises the existing DHSDownloadDeliverablesController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSDownloadDeliverablesControllerTest {
    @IsTest
    static void findsCaseDocuments() {
        User pmoUser = PPFDHSTestUserFactory.createPmoUser();
        System.runAs(pmoUser) {
        DHS_Case__c parentCase =
            new DHS_Case__c(
                Case_Number__c = 'DOWNLOAD-TEST',
                DHS_Assigned_To__c = UserInfo.getUserId()
            );
        insert parentCase;
        DHS_Document__c document = new DHS_Document__c(
            DHS_Case__c = parentCase.Id, Name__c = 'ROIReport'
        );
        insert document;
        insert new Attachment(
            ParentId = document.Id, Name = 'report.pdf',
            Body = Blob.valueOf('test')
        );
        DHSDownloadDeliverablesController controller =
            new DHSDownloadDeliverablesController();
        controller.caseNumberToSearch = 'DOWNLOAD-TEST';
        controller.SearchAction();
        System.assertEquals(true, controller.showTable, 'Assertion failed in DHSDownloadDeliverablesControllerTest at source line 27');
        System.assertEquals(1, controller.caseAttachments.size(), 'Assertion failed in DHSDownloadDeliverablesControllerTest at source line 28');

        controller.caseNumberToSearch = 'DOES-NOT-EXIST';
        controller.SearchAction();
        System.assertEquals(false, controller.showTable, 'Assertion failed in DHSDownloadDeliverablesControllerTest at source line 32');
        System.assertNotEquals(null, controller.errorMessage, 'Assertion failed in DHSDownloadDeliverablesControllerTest at source line 33');

        controller.caseNumberToSearch = null;
        controller.SearchAction();
        DHSDownloadDeliverablesController.caseAttachment wrapperValue =
            new DHSDownloadDeliverablesController.caseAttachment(
                'test', new Attachment(Name = 'test.pdf')
            );
        System.assertEquals('test', wrapperValue.label, 'Assertion failed in DHSDownloadDeliverablesControllerTest at source line 41');
        }
    }
}