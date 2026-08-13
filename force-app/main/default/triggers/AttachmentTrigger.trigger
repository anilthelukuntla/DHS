trigger AttachmentTrigger on Attachment (before insert, after insert) { // NOPMD
     if(trigger.isInsert && trigger.isAfter){ // NOPMD
          //AttachmentTriggerHandler.CreditReportToCase(Trigger.New);
          //AttachmentTriggerHandler.ConvertAttachmentToFile(Trigger.New);
     }
}