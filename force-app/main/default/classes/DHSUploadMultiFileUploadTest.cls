@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs,PMD.ApexAssertionsShouldIncludeMessage')
@IsTest private class DHSUploadMultiFileUploadTest {
 @IsTest static void uploads(){DHS_Contact__c c=new DHS_Contact__c(First_Name__c='Test',Last_Name__c='Subject',Email__c='upload@test.com',Contact_Type__c='Subject');insert c;DHS_Case__c cs=new DHS_Case__c(DHS_Contact__c=c.Id);insert cs;Test.setCurrentPage(new PageReference('/apex/upload'));ApexPages.currentPage().getParameters().put('caseid',cs.Id);System.assertEquals(cs.Id,new DHSUploadMultiFileUpload().caseId);String id=DHSUploadMultiFileUpload.processUploadedFiles(cs.Id,'file.pdf');System.assertNotEquals(null,id);}
}
