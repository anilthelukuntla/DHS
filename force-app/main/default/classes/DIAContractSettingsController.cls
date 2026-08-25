public with sharing class DIAContractSettingsController {
    public DIA_Contract_Setting__c contractSetting{get;set;}
    public DIAContractSettingsController(){
        contractSetting = new DIA_Contract_Setting__c();
    	FetchContractSettings();    
    }
    public void FetchContractSettings(){
    	list<DIA_Contract_Setting__c> contractSettings = new list<DIA_Contract_Setting__c>();
        List<string> contractSettingFields = new List<string>();
        contractSettingFields = ApexUtil.FetchFields('DIA_Contract_Setting__c');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(contractSettingFields, ',') + ' From DIA_Contract_Setting__c WITH SECURITY_ENFORCED';
        System.debug('query...'+query);
        contractSettings = database.query(query);
        if(!contractSettings.isEmpty()){
        	contractSetting = contractSettings[0];        
        }
    }
    
    public void UpdateContractSettings(){
        if(Schema.SobjectType.DIA_Contract_Setting__c.iscreateable()){
            Database.upsertResult ure = database.upsert(contractSetting,false,AccessLevel.USER_MODE);
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to upsert Contract Setting'));
        }
    }
}