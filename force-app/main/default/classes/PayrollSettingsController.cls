public class PayrollSettingsController {
    public list<PayrollSetting__c> payrollSettings {get;set;}
    public PayrollSettingsController(){
        FetchPayrollSettings();   
    }
    public void FetchPayrollSettings(){
        payrollSettings = new list<PayrollSetting__c>();
        List<string> payrollSettingsFields = new List<string>();
        payrollSettingsFields = ApexUtil.FetchFields('PayrollSetting__c');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(payrollSettingsFields, ',') + ' From PayrollSetting__c Order by Order__c';
        System.debug('query...'+query);
        payrollSettings = database.query(query);
        System.debug('payrollSettings...'+payrollSettings);
    }
    
    public void UpdatePayrollSettings(){
        update payrollSettings;
    }
}