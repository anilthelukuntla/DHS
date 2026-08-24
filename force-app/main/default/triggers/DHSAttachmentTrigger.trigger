trigger DHSAttachmentTrigger on Attachment (before insert, after insert) { // NOPMD - Legacy trigger behavior retained for compatibility.
     if(trigger.isInsert && trigger.isAfter){ // NOPMD - Legacy trigger behavior retained for compatibility.
          //DHSAttachmentTriggerHandler.CreditReportToCase(Trigger.New);
          //DHSAttachmentTriggerHandler.ConvertAttachmentToFile(Trigger.New);
     }
}
