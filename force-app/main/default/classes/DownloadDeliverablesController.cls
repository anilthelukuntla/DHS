/** Controls PPF case deliverable search and attachment display. */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.ApexDoc, PMD.ApexSOQLInjection, PMD.AvoidBooleanMethodParameters, PMD.ClassNamingConventions, PMD.MethodNamingConventions')
Public without sharing class DownloadDeliverablesController{
    public string caseNumberToSearch {get;set;}
    public date fromDate {get;set;}
    public date toDate {get;set;}
    public case__c caseRecord {get;set;}
    public list<caseAttachment> caseAttachments {Get;set;}
    public string errorMessage {get;set;}
    public DownloadDeliverablesController(){
        errorMessage = Null;
        showTable = false;
       
    }
    public boolean showTable{get;set;}
    public void SearchAction(){
        if(String.isNotBlank(caseNumberToSearch)){
            caseAttachments = new list<caseAttachment> ();
            caseRecord = Null;
            FetchCaseInformation(caseNumberToSearch);  
        }    
    }
    public void FetchCaseInformation(string caseNumber){
    showTable = false;
        List<string> caseFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        caseFields = ApexUtil.FetchFields('Case__c');
        caseFields.add('contact__r.First_Name__c');
        caseFields.add('contact__r.Last_Name__c');
        caseFields.add('contact__r.Email__c');
        caseFields.add('Assigned_to__r.FirstName');
        caseFields.add('Assigned_to__r.LastName');
        caseFields.add('Assigned_to__r.Email');
        caseFields.add('owner.email');
        
        String query = 'Select '+string.join(caseFields, ',') + ' From Case__c ';
        
        if(String.isNotBlank(caseNumber)){
            whereCriteria.add(new ApexUtil.Criteria('case_Number__c',caseNumber,'='));
        }
        
        String whereCondition = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCondition; 
        list<case__c> cases = database.query(query);
        if(!cases.isEmpty()){
            caseRecord = cases[0];
            FetchDocumentInformation(caseRecord.Id); 
            showTable = true;  
        } else{
            errorMessage = 'No records found for the search criteria';
        } 
          
    }
    public void FetchDocumentInformation(string caseId){
        List<string> documentFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        documentFields = ApexUtil.FetchFields('document__c');      
        String query = 'Select '+string.join(documentFields, ',') + ' From document__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new ApexUtil.Criteria('case__c',caseId,'='));
        }
        
        String whereCondition = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCondition ; 
        
        list<document__c> documentsOfCase = database.query(query);
        List<string> documentIds = new List<string>();
        for(document__c doc: documentsOfCase){
            documentIds.add(doc.id);
        }
        List<attachment> attachments = new List<attachment>();
        attachments = [Select id,name, parentid from attachment where parentid in: documentIds];
        Map<String,String> documentNattachmentMap = new Map<String,String>();
        caseAttachments = new list<caseAttachment>();
        for(attachment att: attachments){
            documentNattachmentMap.put(att.parentid, att.id);   
            caseAttachments.add(new caseAttachment(att.name,att));
        }
    }
    
    public class caseAttachment{
        public string label {get;set;}
        public attachment attachment {get;set;}
        public caseAttachment(string label, attachment att){
            this.label = label;
            this.attachment = att;
        }
    }
}