/** Visualforce controller for contract settings. */
@SuppressWarnings('PMD.MethodNamingConventions, PMD.ApexSOQLInjection')
public with sharing class ContractSettingsController {
    /** Contract setting displayed by the page. */
    public Contract_Setting__c contractSetting{get;set;}
    /** Loads the current contract setting for the page. */
    public ContractSettingsController(){
        contractSetting = new Contract_Setting__c();
    	FetchContractSettings();    
    }
    /** Loads the first available contract setting. */
    public void FetchContractSettings(){
    	list<Contract_Setting__c> contractSettings = new list<Contract_Setting__c>();
        List<string> contractSettingFields = new List<string>();
        contractSettingFields = ApexUtil.FetchFields('Contract_Setting__c');
        String query = 'Select '+string.join(contractSettingFields, ',') + ' From Contract_Setting__c ';
        contractSettings = database.query(query, AccessLevel.SYSTEM_MODE);
        if(!contractSettings.isEmpty()){
        	contractSetting = contractSettings[0];        
        }
    }
    
    /** Saves the contract setting using the current user's permissions. */
    public void UpdateContractSettings(){
        upsert as user contractSetting;
    }
}