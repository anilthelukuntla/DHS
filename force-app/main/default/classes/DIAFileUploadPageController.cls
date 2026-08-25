public with sharing class DIAFileUploadPageController {
    public string caseid;
    public DIA_Case__c caseRecord {get;set;}
    public ApexPages.StandardController controller;
    public DIAFileUploadPageController (ApexPages.StandardController controller) {
        this.controller = controller;
        caseId = apexpages.currentpage().getparameters().get('caseid');
        List<DIA_Case__c> cases = [Select Subject_Type__c,Case_Number__c ,case_type__c, Contact__r.SSN__c from DIA_Case__c where Id=: caseId WITH SECURITY_ENFORCED];
        if(!cases.isEMpty()){
           caseRecord = cases[0];
        }
    } 
    public PageReference saveAndRedirect() {
         Attachment d = (Attachment) controller.getRecord();
         DIA_Document__c document = new DIA_Document__c();
         document.added_by__c = [Select Id,Name from user where id=:userinfo.getuserid() WITH SECURITY_ENFORCED].Name;
         document.case__c = caseId;
         document.Name__c = d.Name;
         Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_Document__c');

         if(Schema.SobjectType.DIA_Document__c.iscreateable() && 
            fields.get('added_by__c').getDescribe().isAccessible() && 
            fields.get('case__c').getDescribe().isAccessible() &&
            fields.get('Name__c').getDescribe().isAccessible()){

            Database.SaveResult dsr = database.insert(document, false, AccessLevel.USER_MODE);
            if(dsr.isSuccess()){
               String modifiedFileName;
               if(caseRecord.Subject_Type__c == 'Applicant'){
                  modifiedFileName = 'A'; 
               }else if(caseRecord.Subject_Type__c == 'Contractor'){
                  modifiedFileName = 'A'; 
               }
               modifiedFileName = modifiedFileName + caseRecord.Contact__r.SSN__c+'Att00_'+d.Name;
               d.name=modifiedFileName;
               d.parentid=dsr.getid();
      
              controller.save();
              PageReference redirect = new PageReference('/apex/bicasedetail?id='+caseId+'&tab=Documents');
              redirect.setRedirect(true);
              return redirect;
            }else{
               return null;
            }
         }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Document'));
            return null;
         }
         
    }
  
   }