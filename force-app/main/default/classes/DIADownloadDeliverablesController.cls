Public with sharing class DIADownloadDeliverablesController{
    public string caseNumberToSearch {get;set;}
    public date fromDate {get;set;}
    public date toDate {get;set;}
    public DIA_Case__c caseRecord {get;set;}
    public List<documents> downloadDocuments {Get;set;}
    public string errorMessage {get;set;}
    public DIADownloadDeliverablesController(){
        errorMessage = Null;
        showTable = false;
       
    }
    public boolean showTable{get;set;}
    public void SearchAction(){
        if(String.isNotBlank(caseNumberToSearch)){
            caseRecord = Null;
            downloadDocuments = New List<documents>();
            FetchCaseInformation(caseNumberToSearch);  
        }    
    }
    public void FetchCaseInformation(string caseNumber){
    showTable = false;
        List<string> caseFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        caseFields = ApexUtil.FetchFields('DIA_Case__c');
        caseFields.add('contact__r.First_Name__c');
        caseFields.add('contact__r.Last_Name__c');
        caseFields.add('contact__r.Email__c');
        caseFields.add('Assigned_to__r.FirstName');
        caseFields.add('Assigned_to__r.LastName');
        caseFields.add('Assigned_to__r.Email');
        caseFields.add('owner.email');
        
        String query = 'Select '+string.join(caseFields, ',') + ' From DIA_Case__c ';
        
        if(String.isNotBlank(caseNumber)){
            whereCriteria.add(new ApexUtil.Criteria('case_Number__c',caseNumber,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED'; 
        System.debug('query...'+query);
        list<DIA_Case__c> cases = database.query(query);
        if(!cases.isEmpty()){
            caseRecord = cases[0];
            FetchDocumentInformation(caseRecord.Id,caseRecord); 
            showTable = true;  
        } else{
            errorMessage = 'No records found for the search criteria';
        } 
          
    }
    public void FetchDocumentInformation(string caseId,dia_case__c caseRecord){
        List<string> documentFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        documentFields = ApexUtil.FetchFields('DIA_Document__c');      
        String query = 'Select '+string.join(documentFields, ',') + ' From DIA_Document__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new ApexUtil.Criteria('case__c',caseId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED' ; 
        
        list<DIA_Document__c> documentsOfCase = database.query(query);
        List<string> documentIds = new List<string>();
        for(DIA_Document__c doc: documentsOfCase){
            documentIds.add(doc.id);
        }
        downloadDocuments = New List<documents>();
        List<contentdocumentlink> cdls = [select id,contentDocumentId,contentDocument.title,LinkedEntityId from contentdocumentlink where LinkedEntityId IN: documentIds];
        for(contentdocumentlink cdl : cdls){
            documents doc = New documents();
            doc.caseNumber = caseRecord.case_number__c;
            doc.caseDueDate = caseRecord.Case_Due_Date__c;
            doc.DocName = cdl.contentDocument.title;
            doc.DocumentId = cdl.contentDocumentId;
            downloadDocuments.add(doc);
        }
    }
    public class documents{
        public string caseNumber {get;set;}
        public date caseDueDate {get;set;}
        public string DocName {get;set;}
        public string DocumentId {get;set;}
    }
}