/** Controls display and update of DHS payroll settings. */
@SuppressWarnings('PMD.ApexDoc')
public with sharing class DHSPayrollSettingsController {
    public list<DHS_PayrollSetting__c> payrollSettings {get;set;}
    public DHSPayrollSettingsController(){
        fetchPayrollSettings();   
    }
    public void fetchPayrollSettings(){
        payrollSettings = new list<DHS_PayrollSetting__c>();
        List<string> payrollSettingsFields = new List<string>();
        payrollSettingsFields = DHSApexUtil.FetchFields('DHS_PayrollSetting__c');
        String query = 'Select '+string.join(payrollSettingsFields, ',') + ' From DHS_PayrollSetting__c WITH USER_MODE Order by Order__c';
        payrollSettings = database.query(String.escapeSingleQuotes(query), AccessLevel.USER_MODE);
    }
    
    public void updatePayrollSettings(){
        database.update(payrollSettings,false,AccessLevel.USER_MODE);
    }
}
