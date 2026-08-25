public class getMetadata {
    @AuraEnabled
    public static Map<String, Object> getFieldMap(String reportType) {
    Map<String, Object> returnVal = new Map<String, Object>();
    Map<Integer, String> orderNLabel = new Map<Integer, String>();
    Map<Integer, String> orderNApiName = new Map<Integer, String>();
    List<String> labels = new List<String>();
    List<String> apinames = new List<String>();

    // Mapping of report types to their corresponding metadata retrieval methods
    Map<String, List<SObject>> reportTypeToMetadataMap = new Map<String, List<SObject>>{
        'CDRLCaseExport' => CDRL_Case_Export__mdt.getAll().values(),
        'CDRLCheckInCheckOut' => CDRL_Check_in_Check_out_Export__mdt.getAll().values(),
        'CDRLLeadExport' => CDRL_Lead_Export__mdt.getAll().values(),
        'CDRLMessageExport' => CDRL_Message_Export__mdt.getAll().values(),
        'CDRLWaiverExport' => CDRL_Waiver_Export__mdt.getAll().values(),
		'DIACDRLCaseExport' => DIA_CDRL_Case_Export__mdt.getAll().values(),
		'DIACDRLCheckInCheckOut' => DIA_CDRL_Check_in_Check_out_Export__mdt.getAll().values(),
		'DIACDRLLeadExport' => DIA_CDRL_Lead_Export__mdt.getAll().values(),
		'DIACDRLMessageExport' => DIA_CDRL_Message_Export__mdt.getAll().values(),
		'DIACDRLWaiverExport' => DIA_CDRL_Waiver_Export__mdt.getAll().values(),
        'pendingCasesByStatus' => Pending__mdt.getAll().values(),
        'PendingLeadsByStatus' => Pending_Leads_By_Status__mdt.getAll().values(),
        'PendingLeadsByType' => Pending_Leads_By_Type__mdt.getAll().values(),
        'CasesCompletedThisWeek' => Cases_Completed_This_Week__mdt.getAll().values(),
        'ICTimeSheet' => IC_TimeSheet__mdt.getAll().values(),
            'Workload' => CDRL_Workload_Export__mdt.getAll().values(),
            'LeadDashboardExport'=> Lead_Dashboard_Export__mdt.getAll().values()
    };

    if (reportTypeToMetadataMap.containsKey(reportType)) {
        for (SObject record : reportTypeToMetadataMap.get(reportType)) {
            Integer order = Integer.valueOf(record.get('Order__c'));
            orderNLabel.put(order, (String)record.get('Label'));
            orderNApiName.put(order, (String)record.get('API_Name__c'));
        }

        for (Integer i = 1; i <= orderNLabel.size(); i++) {
            labels.add(orderNLabel.get(i));
            apinames.add(orderNApiName.get(i));
        }

        returnVal.put('labels', labels);
        returnVal.put('apinames', apinames);
    }

    return returnVal;
}

}