/** Visualforce controller for locating and downloading DHS case deliverables. */
@SuppressWarnings('PMD.ApexDoc, PMD.ApexSOQLInjection, PMD.AvoidBooleanMethodParameters, PMD.ClassNamingConventions, PMD.MethodNamingConventions')
Public with sharing class DHSDownloadDeliverablesController{
    public string caseNumberToSearch {get;set;}
    public date fromDate {get;set;}
    public date toDate {get;set;}
    public DHS_Case__c caseRecord {get;set;}
    public list<caseAttachment> caseAttachments {Get;set;}
    public string errorMessage {get;set;}
    public DHSDownloadDeliverablesController(){
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
        list<DHS_Case__c> cases = database.query(query);
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
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        documentFields = DHSApexUtil.FetchFields('DHS_Document__c');      
        String query = 'Select '+string.join(documentFields, ',') + ' From DHS_Document__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__c',caseId,'='));
        }
        
        String whereCondition = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCondition+' WITH SECURITY_ENFORCED' ; 
        
        list<DHS_Document__c> documentsOfCase = database.query(query);
        List<string> documentIds = new List<string>();
        for(DHS_Document__c doc: documentsOfCase){
            documentIds.add(doc.id);
        }
        List<attachment> attachments = new List<attachment>();
        attachments = [Select id,name, parentid from attachment where parentid in: documentIds WITH SECURITY_ENFORCED];
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