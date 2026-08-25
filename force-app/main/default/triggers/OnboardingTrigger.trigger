trigger OnboardingTrigger on Onboarding__c (before insert, after insert, before update, after update) {
    OnboardingTriggerHandler.run();
}