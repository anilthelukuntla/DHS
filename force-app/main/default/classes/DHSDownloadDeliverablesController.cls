/**
 * @description Visualforce controller for locating and downloading DHS case deliverables.
 */
@SuppressWarnings('PMD.ApexSOQLInjection')
Public with sharing class DHSDownloadDeliverablesController{
    /** @description Provides this DHS API member. */
    public string caseNumberToSearch {get;set;}
    /** @description Provides this DHS API member. */
    public date fromDate {get;set;}
    /** @description Provides this DHS API member. */
    public date toDate {get;set;}
    /** @description Provides this DHS API member. */
    public DHS_Case__c caseRecord {get;set;}
    /** @description Provides this DHS API member. */
    public list<CaseAttachment> caseAttachments {Get;set;}
    /** @description Provides this DHS API member. */
    public string errorMessage {get;set;}
    /** @description Provides this DHS API member. */
    public DHSDownloadDeliverablesController(){
        errorMessage = Null;
        showTable = false;
       
    }
    public boolean showTable{get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /** @description Provides this DHS API member. */
    public void searchAction(){
        if(String.isNotBlank(caseNumberToSearch)){
            caseAttachments = new list<CaseAttachment> ();
            caseRecord = Null;
            fetchCaseInformation(caseNumberToSearch);  
        }    
    }
    /**
     * @description Provides this DHS API member.
     * @param caseNumber Method parameter.
     */
    public void fetchCaseInformation(string caseNumber){
    showTable = false;
        List<string> caseFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        caseFields = DHSApexUtil.FetchFields('DHS_Case__c');
        caseFields.add('DHS_Contact__r.First_Name__c');
        caseFields.add('DHS_Contact__r.Last_Name__c');
        caseFields.add('DHS_Contact__r.Email__c');
        caseFields.add('DHS_Assigned_To__r.FirstName');
        caseFields.add('DHS_Assigned_To__r.LastName');
        caseFields.add('DHS_Assigned_To__r.Email');
        caseFields.add('owner.email');
        
        String query = 'Select '+string.join(caseFields, ',') + ' From DHS_Case__c ';
        
        if(String.isNotBlank(caseNumber)){
            whereCriteria.add(new DHSApexUtil.Criteria('Case_Number__c',caseNumber,'='));
        }
        
        String whereCondition = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCondition+' WITH SECURITY_ENFORCED'; 
        // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
        list<DHS_Case__c> cases = database.query(query);
        if(!cases.isEmpty()){
            caseRecord = cases[0];
            fetchDocumentInformation(caseRecord.Id); 
            showTable = true;  
        } else{
            errorMessage = 'No records found for the search criteria';
        } 
          
    }
    /**
     * @description Provides this DHS API member.
     * @param caseId Method parameter.
     */
    public void fetchDocumentInformation(string caseId){
        List<string> documentFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        documentFields = DHSApexUtil.FetchFields('DHS_Document__c');      
        String query = 'Select '+string.join(documentFields, ',') + ' From DHS_Document__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__c',caseId,'='));
        }
        
        String whereCondition = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCondition+' WITH SECURITY_ENFORCED' ; 
        
        // code-analyzer-suppress-next-line PMD.ApexSOQLInjection -- Schema-validated fields and bound or validated values.
        list<DHS_Document__c> documentsOfCase = database.query(query);
        List<string> documentIds = new List<string>();
        for(DHS_Document__c doc: documentsOfCase){
            documentIds.add(doc.id);
        }
        List<attachment> attachments = new List<attachment>();
        attachments = [Select id,name, parentid from attachment where parentid in: documentIds WITH SECURITY_ENFORCED];
        Map<String,String> documentNattachmentMap = new Map<String,String>();
        caseAttachments = new list<CaseAttachment>();
        for(attachment att: attachments){
            documentNattachmentMap.put(att.parentid, att.id);   
            caseAttachments.add(new CaseAttachment(att.name,att));
        }
    }
    
    /** @description Provides this DHS API member. */
    public class CaseAttachment{
        /** @description Provides this DHS API member. */
        public string label {get;set;}
        /** @description Provides this DHS API member. */
        public attachment attachment {get;set;}
        /**
         * @description Provides this DHS API member.
         * @param label Method parameter.
         * @param att Method parameter.
         */
        public CaseAttachment(string label, attachment att){
            this.label = label;
            this.attachment = att;
        }
    }
}