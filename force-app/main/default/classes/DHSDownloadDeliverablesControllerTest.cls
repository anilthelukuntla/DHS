@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexAssertionsShouldIncludeMessage')
private class DHSDownloadDeliverablesControllerTest {
    @IsTest
    static void findsCaseDocuments() {
        DHS_Case__c parentCase =
            new DHS_Case__c(Case_Number__c = 'DOWNLOAD-TEST');
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
        System.assertEquals(true, controller.showTable);
    }
}
