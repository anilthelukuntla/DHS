/** Controls display and update of DHS payroll settings. */
@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions, PMD.ApexSOQLInjection')
public with sharing class DHSPayrollSettingsController {
    public list<DHS_PayrollSetting__c> payrollSettings {get;set;}
    public DHSPayrollSettingsController(){
        FetchPayrollSettings();   
    }
    public void FetchPayrollSettings(){
        payrollSettings = new list<DHS_PayrollSetting__c>();
        List<string> payrollSettingsFields = new List<string>();
        payrollSettingsFields = DHSApexUtil.FetchFields('DHS_PayrollSetting__c');
        String query = 'Select '+string.join(payrollSettingsFields, ',') + ' From DHS_PayrollSetting__c WITH SECURITY_ENFORCED Order by Order__c';
        payrollSettings = database.query(query);
    }
    
    public void UpdatePayrollSettings(){
        database.update(payrollSettings,false,AccessLevel.USER_MODE);
    }
}