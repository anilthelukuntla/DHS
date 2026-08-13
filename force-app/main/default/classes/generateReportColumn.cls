/** Retains the existing generateReportColumn integration and application behavior. */
@SuppressWarnings('PMD.ApexSharingViolations, PMD.ClassNamingConventions, PMD.ApexDoc, PMD.ApexCRUDViolation')
public class generateReportColumn{
    public static void generateCDRLColumns(){
        Map<String, List<SObject>> reportTypeToMetadataMap = new Map<String, List<SObject>>{
        'Case__c' => CDRL_Case_Export__mdt.getAll().values(),
        'Investigator_Check__c' => CDRL_Check_in_Check_out_Export__mdt.getAll().values(),
        'Lead__c' => CDRL_Lead_Export__mdt.getAll().values(),
        'Message__c' => CDRL_Message_Export__mdt.getAll().values(),
        'Waiver_Information__c' => CDRL_Waiver_Export__mdt.getAll().values(),
		'DIA_Case__c' => DIA_CDRL_Case_Export__mdt.getAll().values(),
		'DIA_Investigator_Check__c' => DIA_CDRL_Check_in_Check_out_Export__mdt.getAll().values(),
		'DIA_Lead__c' => DIA_CDRL_Lead_Export__mdt.getAll().values(),
		'DIA_Message__c' => DIA_CDRL_Message_Export__mdt.getAll().values(),
		'DIA_Waiver_Information__c' => DIA_CDRL_Waiver_Export__mdt.getAll().values()
    };
        List<Report_Export__c> temp = New List<Report_Export__c>();
        for(string reportType : reportTypeToMetadataMap.keyset()){
            for (SObject record : reportTypeToMetadataMap.get(reportType)) {
                Report_Export__c re = New Report_Export__c();
                re.Label__c = (String)record.get('Label');
                re.Api_Name__c = (String)record.get('API_Name__c');
                re.Order__c = Integer.valueOf(record.get('Order__c'));
                string currentSystem = reportType.contains('DIA') ? 'BI' : 'Intel';
                re.System__c = currentSystem;
                re.Report_Type__c = reportType;
                temp.add(re);
            }
        }
        			insert temp;
	}
    public static void createROIColumns(){
        Map<String, String> fieldLabelToApiName = new Map<String, String>{
            'Subject First Name' => 'case__r.Contact__r.First_Name__c',
            'Subject Last Name' => 'case__r.Contact__r.Last_Name__c',
            'Case Number' => 'case__r.Case_Number__c',
            'Customer Case Number' => 'case__r.customer_Case_number__c',
            'Case Due Date' => 'case__r.Case_Due_Date__c',
            'Waiver Due Date' => 'case__r.Waiver_Due_Date__c',
            'Extension Due Date' => 'case__r.Extension_Due_Date__c',
            'Customer Delivery Date' => 'case__r.Customer_Delivery_Date__c',
            'Case Type' => 'case__r.Case_Type__c',
            'Case Status' => 'case__r.status__c',
            'Date Received' => 'case__r.Current_Task__c',
            'CMO' => 'case__r.Assigned_to__r.Name'
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
    
            List<Report_Export__c> temp = New List<Report_Export__c>();
        for(String currentSystem : new list<string>{'Intel','BI'}){
            for(string key : fieldLabelToApiName.keyset()){
                Report_Export__c re = New Report_Export__c();
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
        		insert temp;
    }
}