public class MailUtilities {
    
    /*public static Boolean isValidEmailAddress(String emailAddress){
        if(emailAddress != null && emailAddress.trim() != null && emailAddress.trim().length() > 0){
            String[] split = emailAddress.split('@');
            if(split != null && split.size() == 2){
                split = split[1].split('\\.');
                if(split != null && split.size() >= 2){
                    return true;
                }
            }
        }
        return false;
    }
    
    public static void sendEmailWithStandardAttachments(List<String> recipients,String emailSubject,String body,Boolean useHTML,List<Id> attachmentIDs) {
        List<Attachment> stdAttachments = [SELECT id, name, body FROM Attachment WHERE Id IN:attachmentIDs];
        sendEmailWithStandardAttachments(recipients, emailSubject, body, useHTML, stdAttachments);
    }
    
    public static void sendEmailWithStandardAttachments(List<String> recipients,String emailSubject,String body,Boolean useHTML,List<Attachment> stdAttachments) {
        List<Messaging.EmailFileAttachment> fileAttachments = new List<Messaging.EmailFileAttachment>();
        
        for(Attachment attachment : stdAttachments) {
            Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
            fileAttachment.setFileName(attachment.Name);
            fileAttachment.setBody(attachment.Body);
            fileAttachments.add(fileAttachment);
        }
        sendMail(recipients, emailSubject, body, useHTML, fileAttachments);
    }
     
    public static void sendTextEmail(List<String> recipients,String emailSubject,String textBody) { 
        sendMail(recipients, emailSubject, textBody, false, null);
    }*/
    
    public static void sendHTMLEmailWithTargetObjectId(string targetObjectId,String emailSubject,String htmlBody,List<String> ccRecipients) { 
        sendMailWithTargetObjectId(targetObjectId, emailSubject, htmlBody, true, null,ccRecipients);
    }
    
    private static void sendMailWithTargetObjectId(string targetObjectId,String emailSubject,String body,Boolean useHTML,List<Messaging.EmailFileAttachment> fileAttachments,List<String> ccRecipients) {
        
        if(targetObjectId == null) return;
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();             
        mail.setSaveAsActivity(false);
        mail.setTargetObjectId(targetObjectId);
        mail.setCCAddresses(ccRecipients);
        //mail.setBCCAddresses(new list<String>{'isnbuy@yahoo.com'});
        mail.setSubject(emailSubject);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        if (useHTML) {
            mail.setHtmlBody(body);
        } else {
            mail.setPlainTextBody(body);
        }
        // Specify FileAttachments
        if(fileAttachments != null && fileAttachments.size() > 0) {
            mail.setFileAttachments(fileAttachments);
        }
        // Sends mail here
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   
        
    } 
    
    public static void sendHTMLEmail(List<String> recipients,String emailSubject,String htmlBody,List<String> ccRecipients) { 
        sendMail(recipients, emailSubject, htmlBody, true, null,ccRecipients);
    }
    
    private static void sendMail(
        List<String> recipients,
        String emailSubject,
        String body,
        Boolean useHTML,
        List<Messaging.EmailFileAttachment> fileAttachments,
        List<String> ccRecipients
    ) {
    
        if(recipients == null || recipients.isEmpty()) {
            return;
        }
    
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    
        mail.setSaveAsActivity(false);
        mail.setToAddresses(recipients);
    
        if(ccRecipients != null && !ccRecipients.isEmpty()) {
            mail.setCcAddresses(ccRecipients);
        }
    
        mail.setSubject(emailSubject);
        mail.setBccSender(false);
        mail.setUseSignature(false);
    
        Id orgWideEmailId = getNoReplyOrgWideEmailId();
        if(orgWideEmailId != null) {
            mail.setOrgWideEmailAddressId(orgWideEmailId);
        }
    
        if(useHTML) {
            mail.setHtmlBody(body);
        } else {
            mail.setPlainTextBody(body);
        }
    
        if(fileAttachments != null && !fileAttachments.isEmpty()) {
            mail.setFileAttachments(fileAttachments);
        }
    
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    public static Id getNoReplyOrgWideEmailId() {
        List<OrgWideEmailAddress> oweaList = [
            SELECT Id
            FROM OrgWideEmailAddress
            WHERE Address = 'no-reply@isncorp.com'
            LIMIT 1
        ];
    
        return oweaList.isEmpty() ? null : oweaList[0].Id;
    }
    public static void sendHTMLEmail(List<String> recipients,String emailSubject,String htmlBody,List<String> ccRecipients,string emailTemplateName, string whatId) { 
        sendMail(recipients, emailSubject, htmlBody, true, null,ccRecipients,emailTemplateName,whatId);
    }
    
    private static void sendMail(List<String> recipients,String emailSubject,String body,Boolean useHTML,List<Messaging.EmailFileAttachment> fileAttachments,List<String> ccRecipients,string emailTemplateName, string whatId) {
        
        if(recipients == null) return;
        if(recipients.size() == 0) return;
        if(emailTemplateName == null) return;
        
        List<EmailTemplate> emailTemplates = [Select Id, Name from EmailTemplate WHERE Name =:emailTemplateName];
        user currentUser = [Select Id, ContactId from User WHERE id=:UserInfo.getUserId()];
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage(); 
        if(currentUser.contactId != Null){
            mail.setTargetObjectId(currentUser.contactId); 
        }else{
            mail.setTargetObjectId([Select Id from Contact LIMIT 1].id);
        }
        mail.setTemplateId(emailTemplates[0].id); 
        mail.setWhatId(whatId); 
        mail.setBccSender(false); 
        mail.setSubject(emailSubject);
        mail.setUseSignature(false); 
        mail.setSaveAsActivity(false); 
        mail.setCCAddresses(ccRecipients);
        
        // Specify FileAttachments
        if(fileAttachments != null && fileAttachments.size() > 0) {
            mail.setFileAttachments(fileAttachments);
        }
        // Sends mail here
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   
        
    } 
    public static void sendBIEmail(string subject,string body,List<string> sendingTo,List<string> sendingToBccAdd,List<string> sendingToccAdd){
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
		semail.setToAddresses(sendingTo);
        if(sendingToBccAdd != null){
            semail.setBccAddresses(sendingToBccAdd);
        }
		semail.setCcAddresses(sendingToccAdd);
		semail.setSubject(subject);
		semail.sethtmlBody(body);
        semail.setSaveAsActivity(true);
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] {semail});
    }
    public static void sendBIEmailWithSetTargetObjectId(string subject,string body,string targetObjectId,List<string> sendingToBccAdd,List<string> sendingToccAdd){
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();
		semail.setTargetObjectId(targetObjectId);
        if(sendingToBccAdd != null){
            semail.setBccAddresses(sendingToBccAdd);
        }
		semail.setCcAddresses(sendingToccAdd);
		semail.setSubject(subject);
		semail.sethtmlBody(body);
        semail.setSaveAsActivity(false);
		Messaging.sendEmail(new Messaging.SingleEmailMessage[] {semail});
    }
    /*private static void sendMail(List<String> recipients,String emailSubject,String body,Boolean useHTML,List<Messaging.EmailFileAttachment> fileAttachments) {
        
        if(recipients == null) return;
        if(recipients.size() == 0) return;
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();             
        mail.setSaveAsActivity(false);
        mail.setToAddresses(recipients);
        mail.setSubject(emailSubject);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        if (useHTML) {
            mail.setHtmlBody(body);
        } else {
            mail.setPlainTextBody(body);
        }
        // Specify FileAttachments
        if(fileAttachments != null && fileAttachments.size() > 0) {
            mail.setFileAttachments(fileAttachments);
        }
        // Sends mail here
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   
        
    }  */ 
}