/** Visualforce controller for DHS contract settings. */
@SuppressWarnings('PMD.ApexDoc,PMD.UnusedMethod')
public with sharing class DHSContractSettingsController {
    public DHS_Contract_Setting__c contractSetting{get;set;}
    public DHSContractSettingsController(){
        contractSetting = new DHS_Contract_Setting__c();
    	fetchContractSettings();    
    }
    public void fetchContractSettings(){
    	list<DHS_Contract_Setting__c> contractSettings = new list<DHS_Contract_Setting__c>();
        List<string> contractSettingFields = new List<string>();
        contractSettingFields = DHSApexUtil.FetchFields('DHS_Contract_Setting__c');
        String query = 'Select '+string.join(contractSettingFields, ',') + ' From DHS_Contract_Setting__c   WITH USER_MODE';
        contractSettings = database.query(String.escapeSingleQuotes(query), AccessLevel.USER_MODE);
        if(!contractSettings.isEmpty()){
        	contractSetting = contractSettings[0];        
        }
    }
    
    public void updateContractSettings(){
        database.upsert(contractSetting,false,AccessLevel.USER_MODE);
    }
}
