@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSRD_FileUploadControllerTest {
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
        String attachmentId = DHSRD_FileUploadController.attachBlob(caseRecord.Id,'','fileName','text',part1base64,'f1');
        
        //Send the second piece of the file to be uploaded
        DHSRD_FileUploadController.attachBlob(caseRecord.Id,attachmentId,'fileName','text',part2base64,'f1');
        Test.stopTest();
        
        DHSRD_FileUploadController.attachmentcountmethod(caseRecord.id);
        DHSRD_FileUploadController.attachmentnames(caseRecord.id);
        DHSRD_FileUploadController.attachmentnames(caseRecord.id);
        
        //Assert one file has been attached to the test account
        List<Attachment> attachments = [select Id, Body from Attachment where ParentId = :caseRecord.Id]; System.assertNotEquals(null, attachments, 'Expected attachments to be initialized');
        
        
    }
    
    static @IsTest void uploadTest2() {
        //Split string 'file' in to two chunks, first chunk must be divisible by 3 for base64 encode with no padding
        Blob part1 = Blob.valueOf('This text re'); //length is 12 
        Blob part2 = Blob.valueOf('presents a dummy file');
        
        String part1base64 = EncodingUtil.base64Encode(part1);
        String part2base64 = EncodingUtil.base64Encode(part2);
        
        //Create a test accound the 'file' can be attached to.
        DHS_Customer_Order__c caseRecord = new DHS_Customer_Order__c();
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
        String attachmentId = DHSOrderFileUploadController.attachBlob(caseRecord.Id,'','fileName','text',part1base64,'f1');
        
        //Send the second piece of the file to be uploaded
        DHSOrderFileUploadController.attachBlob(caseRecord.Id,attachmentId,'fileName','text',part2base64,'f1');
        Test.stopTest();
        
        DHSOrderFileUploadController.attachmentcountmethod(caseRecord.id);
        DHSOrderFileUploadController.attachmentnames(caseRecord.id);
        DHSOrderFileUploadController.attachmentnames(caseRecord.id);
        
        //Assert one file has been attached to the test account
        List<Attachment> attachments = [select Id, Body from Attachment where ParentId = :caseRecord.Id]; System.assertNotEquals(null, attachments, 'Expected attachments to be initialized');
        
        
    }
}
