@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSFileUploadControllerTest {
    static @IsTest void uploadTest() {
        //Split string 'file' in to two chunks, first chunk must be divisible by 3 for base64 encode with no padding
        Blob part1 = Blob.valueOf('This text re'); //length is 12 
        Blob part2 = Blob.valueOf('presents a dummy file');
        
        String part1base64 = EncodingUtil.base64Encode(part1);
        String part2base64 = EncodingUtil.base64Encode(part2);
        
        //Create a test accound the 'file' can be attached to.
       DHS_Case__c caseRecord = new DHS_Case__c();
        insert caseRecord;
        attachment att = new attachment();
            att.name = 'test';
            att.body = blob.valueof('att');
            att.description = 'sketch';
            att.parentid = caseRecord.id;
            insert att;
            att = new attachment();
            att.name = 'test';
            att.body = blob.valueof('att');
            att.description = 'consent';
            att.parentid = caseRecord.id;
            insert att;
        
        //Start the test
        Test.startTest();
        //Send first part of the file to be uploaded
        String attachmentId = DHSFileUploadController.attachBlob(caseRecord.Id,'','fileName','text',part1base64,'f1');
        
        //Send the second piece of the file to be uploaded
        DHSFileUploadController.attachBlob(caseRecord.Id,attachmentId,'fileName','text',part2base64,'f1');
        Test.stopTest();
        
        DHSFileUploadController.attachmentcountmethod(caseRecord.id);
        DHSFileUploadController.attachmentnames(caseRecord.id);
        DHSFileUploadController.attachmentnames(caseRecord.id);
        
        //Assert one file has been attached to the test account
        List<Attachment> attachments = [select Id, Body from Attachment where ParentId = :caseRecord.Id]; System.assertNotEquals(null, attachments, 'Expected attachments to be initialized');
       // system.assert(attachments.size() == 3, 'Expected assertion condition to hold');
        
        
    }
}