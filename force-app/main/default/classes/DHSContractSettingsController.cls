/**
 * @description Visualforce controller for DHS contract settings.
 */
@SuppressWarnings('PMD.UnusedMethod')
public with sharing class DHSContractSettingsController {
    /** @description Provides this DHS API member. */
    public DHS_Contract_Setting__c contractSetting{get;set;}
    /** @description Provides this DHS API member. */
    public DHSContractSettingsController(){
        contractSetting = new DHS_Contract_Setting__c();
    	fetchContractSettings();    
    }
    /** @description Provides this DHS API member. */
    public void fetchContractSettings(){
    	list<DHS_Contract_Setting__c> contractSettings = new list<DHS_Contract_Setting__c>();
        List<string> contractSettingFields = new List<string>();
        contractSettingFields = DHSApexUtil.FetchFields('DHS_Contract_Setting__c');
        String query = 'Select '+string.join(contractSettingFields, ',') + ' From DHS_Contract_Setting__c';
        contractSettings = database.query(query, AccessLevel.USER_MODE);
        if(!contractSettings.isEmpty()){
        	contractSetting = contractSettings[0];        
        }
    }
    
    /** @description Provides this DHS API member. */
    public void updateContractSettings(){
        database.upsert(contractSetting,false,AccessLevel.USER_MODE);
    }
}