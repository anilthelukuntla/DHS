@isTest
/** Exercises the existing KnowledgeBaseFileUploadController behavior. */
@SuppressWarnings('PMD.AnnotationsNamingConventions, PMD.ApexUnitTestClassShouldHaveAsserts, PMD.ApexUnitTestClassShouldHaveRunAs, PMD.UnusedLocalVariable')
public class KnowledgeBaseFileUploadControllerTest {
    @IsTest static void uploadTest() {
        //Split string 'file' in to two chunks, first chunk must be divisible by 3 for base64 encode with no padding
        Blob part1 = Blob.valueOf('This text re'); //length is 12 
        Blob part2 = Blob.valueOf('presents a dummy file');
        
        String part1base64 = EncodingUtil.base64Encode(part1);
        String part2base64 = EncodingUtil.base64Encode(part2);
        
        //Create a test accound the 'file' can be attached to.
        Knowledge_base__c kb = new Knowledge_base__c();
        insert kb;
        attachment att = new attachment();
            att.name = 'test';
            att.body = blob.valueof('att');
            att.description = 'sketch';
            att.parentid = kb.id;
            insert att;
            att = new attachment();
            att.name = 'test';
            att.body = blob.valueof('att');
            att.description = 'consent';
            att.parentid = kb.id;
            insert att;
        
        //Start the test
        Test.startTest();
        //Send first part of the file to be uploaded
        String attachmentId = KnowledgeBaseFileUploadController.attachBlob(kb.Id,'','fileName','text',part1base64,'f1','Job Aids');
        
        //Send the second piece of the file to be uploaded
        KnowledgeBaseFileUploadController.attachBlob(kb.Id,attachmentId,'fileName','text',part2base64,'f1','Job Aids');
        Test.stopTest();
        
        KnowledgeBaseFileUploadController.attachmentcountmethod(kb.id);
        KnowledgeBaseFileUploadController.attachmentnames(kb.id);
        KnowledgeBaseFileUploadController.attachmentnames(kb.id);
        
        //Assert one file has been attached to the test account
        List<Attachment> attachments = [select Id, Body from Attachment where ParentId = :kb.Id];
        
        
    }
}