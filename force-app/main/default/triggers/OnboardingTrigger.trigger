trigger OnboardingTrigger on Onboarding__c (before insert, after insert, before update, after update) { // NOPMD
    if(trigger.isInsert && trigger.isAfter){
    	OnboardingTriggerHandler.OnInsertAction(Trigger.New);		    
    }
    if(trigger.isUpdate && trigger.isAfter && !OnboardingTriggerHandler.OnboardingTriggerRunOnce){
    	OnboardingTriggerHandler.OnUpdateAction(Trigger.New, Trigger.oldMap);    
    }
}