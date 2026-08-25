/**
 * @description Visualforce controller for generating DHS deliverable manifests.
 */
@SuppressWarnings('PMD.UnusedMethod')
public with sharing class DHSDeliverablesController {
    /** @description Provides this DHS API member. */
    public user currentUser{get;set;}
    /** @description Provides this DHS API member. */
    public list<selectoption> caseOptions {get;set;}
    /** @description Provides this DHS API member. */
    public list<selectoption> selectedcaseOptions {get;set;}
    /** @description Provides this DHS API member. */
    public list<selectoption> versionOptions {get;set;}
    /** @description Provides this DHS API member. */
    public string selectedVersion {get;set;}
    /** @description Provides this DHS API member. */
    public DHSDeliverablesController(){
        caseOptions = new list<selectoption>();  
        versionOptions = new list<selectoption>(); 
        selectedcaseOptions = new list<selectoption>();
        //caseOptions.add(new selectoption('','--None--'));
        versionOptions.add(new selectoption('','--None--'));
        for(integer i=1;i<=20;i++){
            versionOptions.add(new selectoption(string.valueof(i),string.valueof(i)));    
        }
        fetchCaseList();
    }
    /** @description Provides this DHS API member. */
    public void fetchCaseList(){
        List<string> caseFields = new List<string>();
        List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
        caseFields = DHSApexUtil.FetchFields('DHS_Case__c');
        
        String query = 'Select '+string.join(caseFields, ',') + ' From DHS_Case__c ';
        
        whereCriteria.add(new DHSApexUtil.Criteria('Current_Task__c','QA Review Completed','='));
        
        String whereCondition = DHSApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+whereCondition; 
        list<DHS_Case__c> cases = database.query(query, AccessLevel.USER_MODE);  
        for(DHS_Case__c c: cases){
            caseOptions.add(new selectoption(c.id,c.Case_Number__c));    
        }
    }
    /** @description Provides this DHS API member. */
    public string manifestActionAttachmentId {get;set;}
    /** @description Provides this DHS API member. */
    public void downloadmanifestaction(){
        List<string> caseIdsSelected = new List<string>();
        for (SelectOption so : selectedcaseOptions){
            caseIdsSelected.add(so.getValue());
        } 
        manifestActionAttachmentId = Null;
        string xmlBody = DHSManifestXMLGenerator.LoadReleasesXML(caseIdsSelected,selectedVersion); 
        List<DHS_Case__c> cases = new List<DHS_Case__c>();
        String caseList;
        cases = [Select Id, Case_Number__c FROM DHS_Case__c WHERE ID IN: caseIdsSelected WITH USER_MODE];
        for(DHS_Case__c c: cases){
            if(String.isBlank(caseList)){
                caseList = c.Case_Number__c;
            }else{
                caseList = caseList + ';' + c.Case_Number__c;
            }
            
        }
        
        DHS_Deliverable__c doc = new DHS_Deliverable__c();
        doc.DHS_Requested_By__c = userinfo.getuserid();
        doc.Requested_Date_Time__c = System.now();
        doc.Case_List__c = caseList;
        doc.Version_Number__c = selectedVersion;
        database.insert(doc,false,AccessLevel.USER_MODE);
        Attachment att = new attachment();
        att.ParentId = doc.id;
        att.body = blob.valueof(xmlBody);
        att.Name = 'isn_manifest_'+DateTime.now().format('yyyyMMddHHmmss')+'.xml';
        att.contentType = 'application/xml';
        database.insert(att,false,AccessLevel.USER_MODE);
        manifestActionAttachmentId = att.id;
    }
    
}
