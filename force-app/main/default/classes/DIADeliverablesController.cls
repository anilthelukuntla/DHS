public with sharing class DIADeliverablesController {
    public user currentUser{get;set;}
    public list<selectoption> caseOptions {get;set;}
    public list<selectoption> selectedcaseOptions {get;set;}
    public list<selectoption> versionOptions {get;set;}
    public string selectedVersion {get;set;}
    public DIADeliverablesController(){
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
        caseFields = ApexUtil.FetchFields('DIA_Case__c');
        
        String query = 'Select '+string.join(caseFields, ',') + ' From DIA_Case__c ';
        
        whereCriteria.add(new ApexUtil.Criteria('Current_Task__c','QA Review Completed','='));
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
        query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED'; 
        System.debug('query...'+query);
        list<DIA_Case__c> cases = database.query(query);  
        for(DIA_Case__c c: cases){
            caseOptions.add(new selectoption(c.id,c.case_number__c));    
        }
    }
    public string manifestActionAttachmentId {get;set;}
    public void downloadmanifestaction(){
        List<string> caseIdsSelected = new List<string>();
        for (SelectOption so : selectedcaseOptions){
            caseIdsSelected.add(so.getValue());
        } 
        System.debug('caseIdsSelected...'+caseIdsSelected);
        manifestActionAttachmentId = Null;
        string xmlBody = DIAManifestXMLGenerator.LoadReleasesXML(caseIdsSelected,selectedVersion); 
        List<DIA_Case__c> cases = new List<DIA_Case__c>();
        String caseList;
        cases = [Select Id, case_number__c FROM DIA_Case__c WHERE ID IN: caseIdsSelected WITH SECURITY_ENFORCED];
        for(DIA_Case__c c: cases){
            if(String.isBlank(caseList)){
                caseList = c.case_number__c;
            }else{
                caseList = caseList + ';' + c.case_number__c;
            }
            
        }
        
        DIA_Intel_Deliverable__c doc = new DIA_Intel_Deliverable__c();
        doc.Requested_By__c = userinfo.getuserid();
        doc.Requested_Date_Time__c = System.now();
        doc.Case_List__c = caseList;
        doc.Version_Number__c = selectedVersion;
        Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_Intel_Deliverable__c');
                if(Schema.SobjectType.DIA_Intel_Deliverable__c.iscreateable() && 
                    fields.get('Requested_By__c').getDescribe().isAccessible() &&
                    fields.get('Requested_Date_Time__c').getDescribe().isAccessible() &&
                    fields.get('Case_List__c').getDescribe().isAccessible() &&
                    fields.get('Version_Number__c').getDescribe().isAccessible()
                    ){
                        Database.SaveResult dsr = database.insert(doc, false, AccessLevel.USER_MODE);
                        if(dsr.isSuccess()){
                            Attachment att = new attachment();
                            att.ParentId = dsr.getid();
                            att.body = blob.valueof(xmlBody);
                            att.Name = 'isn_manifest_'+DateTime.now().format('yyyyMMddHHmmss')+'.xml';
                            att.contentType = 'application/xml';
                            Map<String, Schema.SObjectField> attFields = ApexUtil.getObjectFieldsDescribe('Attachment');
                            if(Schema.SobjectType.Attachment.iscreateable() && 
                                attFields.get('ParentId').getDescribe().isAccessible() &&
                                attFields.get('body').getDescribe().isAccessible() &&
                                attFields.get('Name').getDescribe().isAccessible() &&
                                attFields.get('contentType').getDescribe().isAccessible()
                            ){
                                Database.SaveResult dsra = database.insert(att, false, AccessLevel.USER_MODE);
                                if(dsra.isSuccess()){
                                    manifestActionAttachmentId = dsra.getid();  
                                }
                            }else{
                                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Attachment'));
                            }
                        }else{
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Deliverable'));
                        }
                    }
    }
    
}