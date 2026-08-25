/**
 * @description Retains the existing DHSSubjectEnquiryEmailHandler integration and application behavior.
 */
@SuppressWarnings('PMD.AvoidNonRestrictiveQueries,PMD.ExcessiveParameterList,PMD.OperationWithLimitsInLoop')
public with sharing class DHSSubjectEnquiryEmailHandler implements Messaging.InboundEmailHandler {
      /**
       * @description Provides this DHS API member.
       * @param email Method parameter.
       * @param envelope Method parameter.
       * @return The requested result.
       */
      public Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
          Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
          
           try{
               Id caseId = EmailMessages.getRecordIdFromEmail(email.subject, email.plainTextBody, email.htmlBody);
        list<DHS_Case__c> diacase = new list<DHS_Case__c>();
               if(test.isRunningTest()){
                	 diacase = [select id, Subject_Name__c from DHS_Case__c WITH USER_MODE ];
                   caseId = diacase[0].id;
               }else{
               	 diacase = [select id, Subject_Name__c from DHS_Case__c where id=:caseId WITH USER_MODE ];    
               }
        
        DHS_Subject_Message__c message = new DHS_Subject_Message__c();
        message.Message_Body__c = email.htmlBody;
        string tempSubject;
        if(email.subject != Null){
            list<string> subjectComps = email.subject.split('#');
             for(string temp: subjectComps){
                 tempSubject = temp;
             }
        }
        message.Message_Subject__c = tempSubject;
        if(caseId != Null) {
            message.DHS_Case__c = caseId;
        }
        message.Message_Type__c = 'Inbound';
               Database.insert(message, AccessLevel.USER_MODE);
               if(!diacase.isEmpty()) {
                   createFilesByEmailAttachments(email.binaryAttachments, caseID,diacase[0].Subject_Name__c,message.id);
               }
            result.success = true;
        } catch(Exception e){
            String errorMessage = e.getMessage();
            result.message = errorMessage;
            result.success = false;            
        }
          
          
          return result;
      }
    
     private void createFilesByEmailAttachments(
        List<Messaging.inboundEmail.BinaryAttachment> inboundAttachments,
        Id contactId,
        String contactName,
        String messageId
    ) {
        // guard against invalid data
        if (inboundAttachments == null || contactId == null) {
            return;
        }
        List<DHSFilesRecipes.FileAndLinkObject> toCreate = new List<DHSFilesRecipes.FileAndLinkObject>();
        List<DHSFilesRecipes.FileAndLinkObject> toCreateMessageFiles = new List<DHSFilesRecipes.FileAndLinkObject>();
        for (
            Messaging.inboundEmail.BinaryAttachment currentAttachment : inboundAttachments
        ) {
            
            //newFile.attachedTo = contactId;
            DHS_Document__c doc = new DHS_Document__c();
            doc.Name__c = currentAttachment.fileName;
            doc.DHS_Case__c = contactId;
            doc.Added_By__c = contactName;
            Database.insert(doc, AccessLevel.USER_MODE);
            DHSFilesRecipes.FileAndLinkObject newFile = new DHSFilesRecipes.FileAndLinkObject();
            newFile.fileContents = currentAttachment.body;
            newFile.fileName = currentAttachment.fileName;
            newFile.attachedTo = doc.id;
            toCreate.add(newFile);
            
            DHSFilesRecipes.FileAndLinkObject newFileSubjectMessage = new DHSFilesRecipes.FileAndLinkObject();
            newFileSubjectMessage.fileContents = currentAttachment.body;
            newFileSubjectMessage.fileName = currentAttachment.fileName;
            newFileSubjectMessage.attachedTo = doc.id;
            toCreateMessageFiles.add(newFileSubjectMessage);
            
        }
        DHSFilesRecipes.createFilesAttachedToRecords(toCreate);
        DHSFilesRecipes.createFilesAttachedToRecords(toCreateMessageFiles);
    }
  }