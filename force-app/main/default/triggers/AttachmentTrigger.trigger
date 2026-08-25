trigger AttachmentTrigger on Attachment (before insert, after insert) {
     if(trigger.isInsert && trigger.isAfter){
          //AttachmentTriggerHandler.CreditReportToCase(Trigger.New);
          //AttachmentTriggerHandler.ConvertAttachmentToFile(Trigger.New);
     }
}