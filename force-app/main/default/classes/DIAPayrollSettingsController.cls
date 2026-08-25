public class DIAPayrollSettingsController {
    public list<DIA_PayrollSetting__c> payrollSettings {get;set;}
    public DIAPayrollSettingsController(){
        FetchPayrollSettings();   
    }
    public void FetchPayrollSettings(){
        payrollSettings = new list<DIA_PayrollSetting__c>();
        List<string> payrollSettingsFields = new List<string>();
        payrollSettingsFields = ApexUtil.FetchFields('DIA_PayrollSetting__c');
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        String query = 'Select '+string.join(payrollSettingsFields, ',') + ' From DIA_PayrollSetting__c WITH SECURITY_ENFORCED Order by Order__c ';
        System.debug('query...'+query);
        payrollSettings = database.query(query);
        System.debug('payrollSettings...'+payrollSettings);
    }
    
    public void UpdatePayrollSettings(){
        update payrollSettings;
    }
}