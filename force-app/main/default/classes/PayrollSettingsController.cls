/** Supports the legacy Visualforce payroll-settings workflow. */
@SuppressWarnings('PMD.ApexSharingViolations, PMD.ApexDoc, PMD.MethodNamingConventions, PMD.DebugsShouldUseLoggingLevel, PMD.ApexSOQLInjection, PMD.ApexCRUDViolation')
public class PayrollSettingsController {
    public list<PayrollSetting__c> payrollSettings {get;set;}
    public PayrollSettingsController(){
        FetchPayrollSettings();   
    }
    public void FetchPayrollSettings(){
        payrollSettings = new list<PayrollSetting__c>();
        List<string> payrollSettingsFields = new List<string>();
        payrollSettingsFields = ApexUtil.FetchFields('PayrollSetting__c');
        String query = 'Select '+string.join(payrollSettingsFields, ',') + ' From PayrollSetting__c Order by Order__c';
        payrollSettings = database.query(query);
    }
    
    public void UpdatePayrollSettings(){
        update payrollSettings;
    }
}