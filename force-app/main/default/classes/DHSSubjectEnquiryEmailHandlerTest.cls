@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveAsserts,PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSSubjectEnquiryEmailHandlerTest {
	static @IsTest void testinBoundEmail(){
        DHS_Contact__c con = new DHS_Contact__c();
         con.First_Name__c = 'Test';
         con.Last_Name__c = 'Name';
         con.Email__c  = 'test@test.com';
         con.Contact_Type__c = 'Subject';
		 con.SSN__c = '123-12-1123';
         insert con;
         DHS_Case__c diaCase = new DHS_Case__c();
         diaCase.DHS_Contact__c = con.id;
         diaCase.DHS_Assigned_To__c = userinfo.getuserId();
         insert diaCase;
      
       Messaging.InboundEmail email = new Messaging.InboundEmail() ;
       Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
       // intialize the list string to store emails.
       List<string> emails = new List<string>{'testbandi@gmail.com','testbandi123@gmail.com'};
      
      email.subject = 'Create case';
      email.fromAddress = 'someaddress@email.com';
      //assigning the emails to toAddresses 
      email.toAddresses = emails;
      email.plainTextBody = 'email body';
      Messaging.InboundEmail.BinaryAttachment attachment = new Messaging.InboundEmail.BinaryAttachment();
      attachment.body = blob.valueOf('my attachment text');
      attachment.fileName = 'textfileone.txt';
      attachment.mimeTypeSubType = 'text/plain';
      email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[] { attachment };
     
      DHSSubjectEnquiryEmailHandler  testInbound=new DHSSubjectEnquiryEmailHandler ();
      testInbound.handleInboundEmail(email, env);
   }
 
}
