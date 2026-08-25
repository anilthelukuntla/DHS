public class ContractSettingsController {
    public Contract_Setting__c contractSetting{get;set;}
    public ContractSettingsController(){
        contractSetting = new Contract_Setting__c();
    	FetchContractSettings();    
    }
    public void FetchContractSettings(){
    	list<Contract_Setting__c> contractSettings = new list<Contract_Setting__c>();
        List<string> contractSettingFields = new List<string>();
        contractSettingFields = ApexUtil.FetchFields('Contract_Setting__c');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(contractSettingFields, ',') + ' From Contract_Setting__c ';
        System.debug('query...'+query);
        contractSettings = database.query(query);
        if(!contractSettings.isEmpty()){
        	contractSetting = contractSettings[0];        
        }
    }
    
    public void UpdateContractSettings(){
        upsert contractSetting;
    }
}