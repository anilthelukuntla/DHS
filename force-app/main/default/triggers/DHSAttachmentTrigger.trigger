trigger DHSAttachmentTrigger on Attachment (before insert, after insert) { // NOPMD
     if(trigger.isInsert && trigger.isAfter){ // NOPMD
          //DHSAttachmentTriggerHandler.CreditReportToCase(Trigger.New);
          //DHSAttachmentTriggerHandler.ConvertAttachmentToFile(Trigger.New);
     }
}