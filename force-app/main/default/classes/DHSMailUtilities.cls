/**
 * @description Retains the existing DHSMailUtilities integration and application behavior.
 */
@SuppressWarnings('PMD.ApexSharingViolations,PMD.ExcessiveParameterList,PMD.UnusedMethod')
public class DHSMailUtilities {

    private static Id getNoReplyOrgWideEmailId() {
        List<OrgWideEmailAddress> oweaList = [
            SELECT Id
            FROM OrgWideEmailAddress
            WHERE Address = 'noreply@isncorp.com'
             WITH USER_MODE LIMIT 1
        ];

        if (oweaList.isEmpty()) {
            return null;
        }

        return oweaList[0].Id;
    }

    /**
     * @description Provides this DHS API member.
     * @param targetObjectId Method parameter.
     * @param emailSubject Method parameter.
     * @param htmlBody Method parameter.
     * @param ccRecipients Method parameter.
     */
    public static void sendHTMLEmailWithTargetObjectId(String targetObjectId, String emailSubject, String htmlBody, List<String> ccRecipients) { 
        sendMailWithTargetObjectId(targetObjectId, emailSubject, htmlBody, true, null, ccRecipients);
    }

    private static void sendMailWithTargetObjectId(String targetObjectId, String emailSubject, String body, Boolean useHTML, List<Messaging.EmailFileAttachment> fileAttachments, List<String> ccRecipients) {
        if (targetObjectId == null) {
            return;
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        Id orgWideEmailId = getNoReplyOrgWideEmailId();
        if (orgWideEmailId != null) {
            mail.setOrgWideEmailAddressId(orgWideEmailId);
        }

        mail.setSaveAsActivity(false);
        mail.setTargetObjectId(targetObjectId);
        mail.setCCAddresses(ccRecipients);
        mail.setSubject(emailSubject);
        mail.setBccSender(false);
        mail.setUseSignature(false);

        if (useHTML) {
            mail.setHtmlBody(body);
        } else {
            mail.setPlainTextBody(body);
        }

        if (fileAttachments != null && fileAttachments.size() > 0) {
            mail.setFileAttachments(fileAttachments);
        }

        //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   
    } 

    /**
     * @description Provides this DHS API member.
     * @param recipients Method parameter.
     * @param emailSubject Method parameter.
     * @param htmlBody Method parameter.
     * @param ccRecipients Method parameter.
     */
    public static void sendHTMLEmail(List<String> recipients, String emailSubject, String htmlBody, List<String> ccRecipients) { 
        sendMail(recipients, emailSubject, htmlBody, true, null, ccRecipients);
    }

    private static void sendMail(List<String> recipients, String emailSubject, String body, Boolean useHTML, List<Messaging.EmailFileAttachment> fileAttachments, List<String> ccRecipients) {
        if (recipients == null || recipients.size() == 0) {
            return;
        }

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        Id orgWideEmailId = getNoReplyOrgWideEmailId();
        if (orgWideEmailId != null) {
            mail.setOrgWideEmailAddressId(orgWideEmailId);
        }

        mail.setSaveAsActivity(false);
        mail.setToAddresses(recipients);
        mail.setCCAddresses(ccRecipients);
        mail.setSubject(emailSubject);
        mail.setBccSender(false);
        mail.setUseSignature(false);

        if (useHTML) {
            mail.setHtmlBody(body);
        } else {
            mail.setPlainTextBody(body);
        }

        if (fileAttachments != null && fileAttachments.size() > 0) {
            mail.setFileAttachments(fileAttachments);
        }

        //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   
    } 

    /**
     * @description Provides this DHS API member.
     * @param recipients Method parameter.
     * @param emailSubject Method parameter.
     * @param htmlBody Method parameter.
     * @param ccRecipients Method parameter.
     * @param emailTemplateName Method parameter.
     * @param whatId Method parameter.
     */
    public static void sendHTMLEmail(List<String> recipients, String emailSubject, String htmlBody, List<String> ccRecipients, String emailTemplateName, String whatId) { 
        sendMail(recipients, emailSubject, htmlBody, true, null, ccRecipients, emailTemplateName, whatId);
    }

    private static void sendMail(List<String> recipients, String emailSubject, String body, Boolean useHTML, List<Messaging.EmailFileAttachment> fileAttachments, List<String> ccRecipients, String emailTemplateName, String whatId) {
        if (recipients == null || recipients.size() == 0) {
            return;
        }
        if (emailTemplateName == null) {
            return;
        }

        List<EmailTemplate> emailTemplates = [
            SELECT Id, Name
            FROM EmailTemplate
            WHERE Name = :emailTemplateName
             WITH USER_MODE LIMIT 1
        ];

        if (emailTemplates.isEmpty()) {
            return;
        }

        User currentUser = [
            SELECT Id, ContactId
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

        Id orgWideEmailId = getNoReplyOrgWideEmailId();
        if (orgWideEmailId != null) {
            mail.setOrgWideEmailAddressId(orgWideEmailId);
        }

        if (currentUser.ContactId != null) {
            mail.setTargetObjectId(currentUser.ContactId); 
        } else {
            mail.setTargetObjectId([SELECT Id FROM Contact LIMIT 1].Id);
        }

        mail.setTemplateId(emailTemplates[0].Id); 
        mail.setWhatId(whatId); 
        mail.setBccSender(false); 
        mail.setSubject(emailSubject);
        mail.setUseSignature(false); 
        mail.setSaveAsActivity(false); 
        mail.setCCAddresses(ccRecipients);

        if (fileAttachments != null && fileAttachments.size() > 0) {
            mail.setFileAttachments(fileAttachments);
        }

        //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });   
    } 

    /**
     * @description Provides this DHS API member.
     * @param subject Method parameter.
     * @param body Method parameter.
     * @param sendingTo Method parameter.
     * @param sendingToBccAdd Method parameter.
     * @param sendingToccAdd Method parameter.
     */
    public static void sendBIEmail(String subject, String body, List<String> sendingTo, List<String> sendingToBccAdd, List<String> sendingToccAdd) {
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();

        Id orgWideEmailId = getNoReplyOrgWideEmailId();
        if (orgWideEmailId != null) {
            semail.setOrgWideEmailAddressId(orgWideEmailId);
        }

        semail.setToAddresses(sendingTo);

        if (sendingToBccAdd != null) {
            semail.setBccAddresses(sendingToBccAdd);
        }

        semail.setCcAddresses(sendingToccAdd);
        semail.setSubject(subject);
        semail.setHtmlBody(body);
        semail.setSaveAsActivity(true);

        //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { semail });
    }

    /**
     * @description Provides this DHS API member.
     * @param subject Method parameter.
     * @param body Method parameter.
     * @param targetObjectId Method parameter.
     * @param sendingToBccAdd Method parameter.
     * @param sendingToccAdd Method parameter.
     */
    public static void sendBIEmailWithSetTargetObjectId(String subject, String body, String targetObjectId, List<String> sendingToBccAdd, List<String> sendingToccAdd) {
        Messaging.SingleEmailMessage semail = new Messaging.SingleEmailMessage();

        Id orgWideEmailId = getNoReplyOrgWideEmailId();
        if (orgWideEmailId != null) {
            semail.setOrgWideEmailAddressId(orgWideEmailId);
        }

        semail.setTargetObjectId(targetObjectId);

        if (sendingToBccAdd != null) {
            semail.setBccAddresses(sendingToBccAdd);
        }

        semail.setCcAddresses(sendingToccAdd);
        semail.setSubject(subject);
        semail.setHtmlBody(body);
        semail.setSaveAsActivity(false);

        //Messaging.sendEmail(new Messaging.SingleEmailMessage[] { semail });
    }
}
