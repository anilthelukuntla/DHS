/** Retains the existing DHSGenerateReportColumn integration and application behavior. */
@SuppressWarnings('PMD.ApexDoc,PMD.ApexSharingViolations')
public class DHSGenerateReportColumn{
    public static void generateCDRLColumns(){
        Map<String, List<SObject>> reportTypeToMetadataMap = new Map<String, List<SObject>>{
        'Case__c' => DHS_CDRL_Case_Export__mdt.getAll().values(),
        'Investigator_Check__c' => DHS_CDRL_Check_in_Check_out_Export__mdt.getAll().values(),
        'Lead__c' => DHS_CDRL_Lead_Export__mdt.getAll().values(),
        'Message__c' => DHS_CDRL_Message_Export__mdt.getAll().values(),
        'Waiver_Information__c' => DHS_CDRL_Waiver_Export__mdt.getAll().values(),
		'Case__c' => DIA_CDRL_Case_Export__mdt.getAll().values(),
		'DIA_Investigator_Check__c' => DIA_CDRL_Check_in_Check_out_Export__mdt.getAll().values(),
		'DIA_Lead__c' => DIA_CDRL_Lead_Export__mdt.getAll().values(),
		'DIA_Message__c' => DIA_CDRL_Message_Export__mdt.getAll().values(),
		'DIA_Waiver_Information__c' => DIA_CDRL_Waiver_Export__mdt.getAll().values()
    };
        List<DHS_Report_Export__c> temp = New List<DHS_Report_Export__c>();
        for(string reportType : reportTypeToMetadataMap.keyset()){
            for (SObject record : reportTypeToMetadataMap.get(reportType)) {
                DHS_Report_Export__c re = New DHS_Report_Export__c();
                re.Label__c = (String)record.get('Label');
                re.Api_Name__c = (String)record.get('Api_Name__c');
                re.Order__c = Integer.valueOf(record.get('Order__c'));
                string currentSystem = reportType.contains('DIA') ? 'BI' : 'Intel';
                re.System__c = currentSystem;
                re.Report_Type__c = reportType;
                temp.add(re);
            }
        }
        			Database.insert(temp, AccessLevel.USER_MODE);
	}
    public static void createROIColumns(){
        Map<String, String> fieldLabelToApiName = new Map<String, String>{
            'Subject First Name' => 'DHS_Case__r.DHS_Contact__r.First_Name__c',
            'Subject Last Name' => 'DHS_Case__r.DHS_Contact__r.Last_Name__c',
            'Case Number' => 'DHS_Case__r.Case_Number__c',
            'Customer Case Number' => 'DHS_Case__r.Customer_Case_Number__c',
            'Case Due Date' => 'DHS_Case__r.Case_Due_Date__c',
            'Waiver Due Date' => 'DHS_Case__r.Waiver_Due_Date__c',
            'Extension Due Date' => 'DHS_Case__r.Extension_Due_Date__c',
            'Customer Delivery Date' => 'DHS_Case__r.Customer_Delivery_Date__c',
            'Case Type' => 'DHS_Case__r.Case_Type__c',
            'Case Status' => 'DHS_Case__r.Status__c',
            'Date Received' => 'DHS_Case__r.Current_Task__c',
            'CMO' => 'DHS_Case__r.DHS_Assigned_To__r.Name'
        };
            Map<String, Integer> columnToIndexMap = new Map<String, Integer>{
    'Subject First Name' => 0,
    'Subject Last Name' => 1,
    'Case Number' => 2,
    'Customer Case Number' => 3,
    'Case Due Date' => 4,
    'Waiver Due Date' => 5,
    'Extension Due Date' => 6,
    'Customer Delivery Date' => 7,
    'Case Type' => 8,
    'Case Status' => 9,
    'Date Received' => 10,
    'CMO' => 11
};
    
            List<DHS_Report_Export__c> temp = New List<DHS_Report_Export__c>();
        for(String currentSystem : new list<string>{'Intel','BI'}){
            for(string key : fieldLabelToApiName.keyset()){
                DHS_Report_Export__c re = New DHS_Report_Export__c();
                re.Label__c = key;
                re.Api_Name__c = fieldLabelToApiName.get(key);
                re.Order__c = columnToIndexMap.get(key);
                re.System__c = currentSystem;
                if(currentSystem == 'Intel'){
                    re.Report_Type__c = 'Document__c';
                    if(key != 'Extension Due Date'){
                    	temp.add(re);
                	}
                }else{
                    re.Report_Type__c = 'DIA_Document__c';
                    temp.add(re);
                }
            }
        }
        		Database.insert(temp, AccessLevel.USER_MODE);
    }
}
