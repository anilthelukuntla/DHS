/** Visualforce controller for DHS contract settings. */
@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions, PMD.ApexSOQLInjection')
public with sharing class DHSContractSettingsController {
    public DHS_Contract_Setting__c contractSetting{get;set;}
    public DHSContractSettingsController(){
        contractSetting = new DHS_Contract_Setting__c();
    	FetchContractSettings();    
    }
    public void FetchContractSettings(){
    	list<DHS_Contract_Setting__c> contractSettings = new list<DHS_Contract_Setting__c>();
        List<string> contractSettingFields = new List<string>();
        contractSettingFields = DHSApexUtil.FetchFields('DHS_Contract_Setting__c');
        String query = 'Select '+string.join(contractSettingFields, ',') + ' From DHS_Contract_Setting__c   WITH SECURITY_ENFORCED';
        contractSettings = database.query(query);
        if(!contractSettings.isEmpty()){
        	contractSetting = contractSettings[0];        
        }
    }
    
    public void UpdateContractSettings(){
        database.upsert(contractSetting,false,AccessLevel.USER_MODE);
    }
}