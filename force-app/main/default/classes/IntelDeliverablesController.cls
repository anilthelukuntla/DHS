/** Visualforce controller for generating Intel/PPF deliverable manifests. */
@SuppressWarnings('PMD.ApexDoc, PMD.MethodNamingConventions, PMD.ApexSOQLInjection, PMD.ApexCRUDViolation')
public without sharing class IntelDeliverablesController {
    public user currentUser{get;set;}
    public list<selectoption> caseOptions {get;set;}
    public list<selectoption> selectedcaseOptions {get;set;}
    public list<selectoption> versionOptions {get;set;}
    public string selectedVersion {get;set;}
    public IntelDeliverablesController(){
        caseOptions = new list<selectoption>();  
        versionOptions = new list<selectoption>(); 
        selectedcaseOptions = new list<selectoption>();
        //caseOptions.add(new selectoption('','--None--'));
        versionOptions.add(new selectoption('','--None--'));
        for(integer i=1;i<=20;i++){
            versionOptions.add(new selectoption(string.valueof(i),string.valueof(i)));    
        }
        FetchCaseList();
    }
    public void FetchCaseList(){
        List<string> caseFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        caseFields = ApexUtil.FetchFields('Case__c');
        
        String query = 'Select '+string.join(caseFields, ',') + ' From Case__c ';
        
        whereCriteria.add(new ApexUtil.Criteria('Current_Task__c','QA Review Completed','='));
        
        String whereCondition = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCondition; 
        list<case__c> cases = database.query(query);  
        for(Case__c c: cases){
            caseOptions.add(new selectoption(c.id,c.case_number__c));    
        }
    }
    public string manifestActionAttachmentId {get;set;}
    public void downloadmanifestaction(){
        List<string> caseIdsSelected = new List<string>();
        for (SelectOption so : selectedcaseOptions){
            caseIdsSelected.add(so.getValue());
        } 
        manifestActionAttachmentId = Null;
        string xmlBody = ManifestXMLGenerator.LoadReleasesXML(caseIdsSelected,selectedVersion); 
        List<Case__c> cases = new List<Case__c>();
        String caseList;
        cases = [Select Id, case_number__c FROM Case__c WHERE ID IN: caseIdsSelected];
        for(Case__c c: cases){
            if(String.isBlank(caseList)){
                caseList = c.case_number__c;
            }else{
                caseList = caseList + ';' + c.case_number__c;
            }
            
        }
        
        Intel_Deliverable__c doc = new Intel_Deliverable__c();
        doc.Requested_By__c = userinfo.getuserid();
        doc.Requested_Date_Time__c = System.now();
        doc.Case_List__c = caseList;
        doc.Version_Number__c = selectedVersion;
        insert doc;
        Attachment att = new attachment();
        att.ParentId = doc.id;
        att.body = blob.valueof(xmlBody);
        att.Name = 'isn_manifest_'+DateTime.now().format('yyyyMMddHHmmss')+'.xml';
        att.contentType = 'application/xml';
        insert att;
        manifestActionAttachmentId = att.id;
    }
    
}