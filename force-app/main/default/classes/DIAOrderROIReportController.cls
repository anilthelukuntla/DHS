public with sharing class DIAOrderROIReportController {
    public string caseId {get;set;}
    public DIA_Case__c caseRecord {get;set;}
    public List<LeadRecord> leadRecords {get;set;}
    public list<selectoption> orderOptions {get;set;}
    public string type{get;set;}
    public DIAOrderROIReportController(){
        caseId = apexpages.currentpage().getparameters().get('id');
        type= apexpages.currentpage().getparameters().get('type');
        orderOptions = new list<selectoption>();
        FetchCaseInformation();
        FetchLeadInformation();
        showroireport = false;
        showimprovisedroireport = false;
        
    }
    public void FetchCaseInformation(){
        List<string> caseFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        caseFields = ApexUtil.FetchFields('DIA_Case__c');
        caseFields.add('contact__r.First_Name__c');
        caseFields.add('contact__r.Last_Name__c');
        caseFields.add('contact__r.Email__c');
        caseFields.add('contact__r.Address__c');
        caseFields.add('contact__r.City__c');
        caseFields.add('contact__r.State__c');
        caseFields.add('contact__r.Zip__c');
        caseFields.add('contact__r.SSN__c');
        String query = 'Select '+string.join(caseFields, ',') + ' From DIA_Case__c ';
        
        if(String.isNotBlank(caseId)){
            whereCriteria.add(new ApexUtil.Criteria('Id',caseId,'='));
        }
        
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria); 
        if(!Test.isrunningTest()){
            query = query + ' WHERE '+where_cond+' WITH SECURITY_ENFORCED'; 
        }
        
        System.debug('query...'+query);
        list<DIA_Case__c> cases = database.query(query);
        if(!cases.isEmpty()){
            caseRecord = cases[0]; 
        }    
    }
    
    public void FetchLeadInformation(){
        orderOptions.add(new selectoption('','--None--'));
        leadRecords = new list<LeadRecord>();
        list<DIA_lead__c> leads = new List<DIA_lead__c> ();
        List<string> leadFields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        leadFields = ApexUtil.FetchFields('DIA_lead__c');  
        leadFields.add('contact__r.First_Name__c');    
        leadFields.add('contact__r.Last_Name__c');   
        String query = 'Select '+string.join(leadFields, ',') + ' From DIA_lead__c ';
        
        if(String.isNotBlank(string.valueof(caseId))){
            whereCriteria.add(new ApexUtil.Criteria('Case__c',caseId,'='));
        }
        whereCriteria.add(new ApexUtil.Criteria('Status__c','Cancelled','!='));
        String where_cond = ApexUtil.generateWhereQuery(whereCriteria);
        if(!Test.isrunningTest()){
			query = query + ' WHERE '+where_cond+ ' WITH SECURITY_ENFORCED ORDER BY Item_Number__c ASC '; 
        }
        
        leads = database.query(query);
        System.debug('leadquery...'+query);
        Integer i = 1;
        for(DIA_lead__c l: leads){
            leadRecords.add(new leadRecord(l,null));    
            orderOptions.add(new selectoption(string.valueof(i),string.valueof(i)));
            i++;
        }
    }
    
    public class LeadRecord{
        public DIA_lead__c lead{get;set;}
        public integer leadNumber {get;set;}
        public LeadRecord(DIA_lead__c l, integer  ln){
            this.lead = l;
           
            this.leadnumber = ln;
        }
    }
    public string roiOrderId {get;set;}
    public PageReference GenerateROIReport(){
        DIA_ROI_Report_Order__c roiOrder = new DIA_ROI_Report_Order__c();
        roiOrder.case__c = caseRecord.id;
        
        String order;
        //leadRecords.sort();
       map<double,DIA_lead__c> orderNLeadMap = new map<double,DIA_lead__c>();
       list<integer> leadNumbers = new list<integer>();
        for(LeadRecord lr: leadRecords){  
            if(lr.leadNumber != Null){
                System.debug('lr...'+lr.leadNumber);
                orderNLeadMap.put(lr.leadNumber,lr.lead);
                leadNumbers.add(lr.leadNumber);
            }    
        }
        
        
        leadNumbers.sort();
        System.debug('leadnumbers...'+leadnumbers);
        String leaditemnumbers;
        for(integer ln:leadNumbers){
            if(leaditemnumbers == Null){
                leaditemnumbers = String.valueof(orderNLeadMap.get(ln).item_number__c);     
                    } else{
                        leaditemnumbers = leaditemnumbers + ','+String.valueof(orderNLeadMap.get(ln).item_number__c);           
                    } 
        }
        System.debug('leaditemnumbers...'+leaditemnumbers);
        roiOrder.ROI_Report_Order__c = leaditemnumbers;

        Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_ROI_Report_Order__c');

        if(Schema.SobjectType.DIA_ROI_Report_Order__c.iscreateable() && 
            fields.get('ROI_Report_Order__c').getDescribe().isAccessible() && 
            fields.get('case__c').getDescribe().isAccessible()){

            Database.SaveResult dsr = database.insert(roiOrder, false, AccessLevel.USER_MODE);
            if(dsr.isSuccess()){
                roiOrderId = dsr.getId();
                PageReference redirectPage = Page.BIROIReportV2;
                redirectPage.setRedirect(true);
                redirectPage.getParameters().put('id',caseRecord.id);
                redirectPage.getParameters().put('sequenceid',dsr.getId());
                return redirectPage;
            }else{
                return null;
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to generate ROI Report Order'));
            return null;
        }
    }
    
    public PageReference GenerateNattachROIReport(){
     DIA_ROI_Report_Order__c roiOrder = new DIA_ROI_Report_Order__c();
        roiOrder.case__c = caseRecord.id;
        
        String order;
        //leadRecords.sort();
       map<double,DIA_lead__c> orderNLeadMap = new map<double,DIA_lead__c>();
       list<integer> leadNumbers = new list<integer>();
        for(LeadRecord lr: leadRecords){  
            if(lr.leadNumber != Null){
                System.debug('lr...'+lr.leadNumber);
                orderNLeadMap.put(lr.leadNumber,lr.lead);
                leadNumbers.add(lr.leadNumber);
            }    
        }
        
        
        leadNumbers.sort();
        System.debug('leadnumbers...'+leadnumbers);
        String leaditemnumbers;
        for(integer ln:leadNumbers){
            if(leaditemnumbers == Null){
                leaditemnumbers = String.valueof(orderNLeadMap.get(ln).item_number__c);     
                    } else{
                        leaditemnumbers = leaditemnumbers + ','+String.valueof(orderNLeadMap.get(ln).item_number__c);           
                    } 
        }
        System.debug('leaditemnumbers...'+leaditemnumbers);
        roiOrder.ROI_Report_Order__c = leaditemnumbers;

        Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_ROI_Report_Order__c');

        if(Schema.SobjectType.DIA_ROI_Report_Order__c.iscreateable() && 
            fields.get('ROI_Report_Order__c').getDescribe().isAccessible() && 
            fields.get('case__c').getDescribe().isAccessible()){

            Database.SaveResult dsr = database.insert(roiOrder, false, AccessLevel.USER_MODE);
            if(dsr.isSuccess()){
                myFutureMethod(caseRecord.id,dsr.getId());
                PageReference redirectPage = Page.BICaseDetail;
                redirectPage.setRedirect(true);
                redirectPage.getParameters().put('id',caseRecord.id);
                return redirectPage;
            }else{
                return null;
            }
        }else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to generate ROI Report Order'));
            return null;
        }
       /* Document__c doc = new Document__c();
        doc.Name__c = 'ROIReport';
        doc.case__c = caseRecord.id;
        doc.Added_By__c = UserInfo.getFirstName() + ' '+ UserInfo.getLastName();
        insert doc;
        
        string applicantType;
        string ssnFormatted;
        if(caseRecord.Subject_Type__c == 'Applicant'){
            applicantType = 'A';
        }
        if(caseRecord.Subject_Type__c == 'Contractor'){
            applicantType = 'C';
        }
        if(caseRecord.Contact__r.SSN__c != Null){
            ssnFormatted = caseRecord.Contact__r.SSN__c.replaceAll('-','');
        }
        PageReference pr= Page.BIROIReportV2;
        pr.getParameters().put('sequenceid',roiOrder.id);
        pr.getParameters().put('id',caseRecord.Id);
           
       
        Attachment att = new attachment();
        att.ParentId = doc.id;
        att.Name = applicantType + ssnFormatted + 'Rev00.pdf';
        if(!test.isRunningTest()){
            att.Body = pr.getContentAsPDF();    
        }else{
            att.body = blob.valueof('temp');
        }
        
        att.ContentType = 'application/pdf';
        insert att;*/
        
    }
    
    @future(callout=true)
    public static void myFutureMethod(string caseId, string sequenceId)
    {   
        DIA_Document__c doc = new DIA_Document__c();
        doc.Name__c = 'ROIReport';
        doc.case__c = caseId;
        doc.Added_By__c = UserInfo.getFirstName() + ' '+ UserInfo.getLastName();

        Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_Document__c');
        if(Schema.SobjectType.DIA_Document__c.iscreateable() && 
                fields.get('Name__c').getDescribe().isAccessible() && 
                fields.get('case__c').getDescribe().isAccessible() &&
                fields.get('Added_By__c').getDescribe().isAccessible()){
                Database.SaveResult dsr = database.insert(doc, false, AccessLevel.USER_MODE);
                if(dsr.isSuccess()){
                    DIA_Case__c caseRecord = [select Subject_Type__c,Contact__r.SSN__c from DIA_Case__c where id=:caseId WITH SECURITY_ENFORCED limit 1 ];
                    string applicantType;
                    string ssnFormatted;
                    if(caseRecord.Subject_Type__c == 'Applicant'){
                        applicantType = 'A';
                    }
                    if(caseRecord.Subject_Type__c == 'Contractor'){
                        applicantType = 'C';
                    }
                    if(caseRecord.Contact__r.SSN__c != Null){
                        ssnFormatted = caseRecord.Contact__r.SSN__c.replaceAll('-','');
                    }
                    PageReference pr= Page.BIROIReportV2;
                    pr.getParameters().put('sequenceid',sequenceId);
                    pr.getParameters().put('id',caseId);
                    
                
                    Attachment att = new attachment();
                    att.ParentId = dsr.getId();
                    att.Name = applicantType + ssnFormatted + 'Rev00.pdf';
                    if(!test.isRunningTest()){
                        att.Body = pr.getContentAsPDF();    
                    }else{
                        att.body = blob.valueof('temp');
                    }
                    
                    att.ContentType = 'application/pdf';
                    Map<String, Schema.SObjectField> attFields = ApexUtil.getObjectFieldsDescribe('Attachment');
                    if(Schema.SobjectType.Attachment.iscreateable() && 
                        attFields.get('ParentId').getDescribe().isAccessible() && 
                        attFields.get('Name').getDescribe().isAccessible() &&
                        attFields.get('Body').getDescribe().isAccessible()){
                            Database.SaveResult dsra = database.insert(att, false, AccessLevel.USER_MODE);
                            
                            dia_case__c cs = [select id,Is_ROI_Report_Generated__c from dia_case__c where id =: caseId];
                            cs.Is_ROI_Report_Generated__c = true;
                            update cs;
                        }else{
                            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Attachment'));
                        }
                }
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Document'));
                
            }
        
    }
    public string currentsequenceid {get;set;}
    public void GenerateROIDraft(){
         String order;    
         map<double,DIA_lead__c> orderNLeadMap = new map<double,DIA_lead__c>();
         list<integer> leadNumbers = new list<integer>();
          String leaditemnumbers;
        for(LeadRecord lr: leadRecords){  
           if(leaditemnumbers == Null){
               leaditemnumbers = String.valueof(lr.lead.item_number__c);
           }else{
               leaditemnumbers = leaditemnumbers+ ','+String.valueof(lr.lead.item_number__c);
           }
        }
        
        
       
        System.debug('leaditemnumbers...'+leaditemnumbers);
        if(currentsequenceid != Null){
            list<DIA_ROI_Report_Order__c> roiOrder = [Select Id, ROI_Report_Order__c, case__C from DIA_ROI_Report_Order__c WHERE Id=:currentsequenceid WITH SECURITY_ENFORCED];
            if(!roiOrder.isEmpty()){
                
                 roiOrder[0].ROI_Report_Order__c = leaditemnumbers;
                 Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_ROI_Report_Order__c');

                if(Schema.SobjectType.DIA_ROI_Report_Order__c.isUpdateable() && 
                    fields.get('ROI_Report_Order__c').getDescribe().isAccessible()){

                    List<Database.SaveResult> dsr = database.update(roiOrder, false, AccessLevel.USER_MODE);
                }else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update ROI Report Order'));
                }
            }
        }else{
            DIA_ROI_Report_Order__c roiOrder = new DIA_ROI_Report_Order__c();
            roiOrder.case__c = caseRecord.id;
            roiOrder.ROI_Report_Order__c = leaditemnumbers;
            Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_ROI_Report_Order__c');

                if(Schema.SobjectType.DIA_ROI_Report_Order__c.iscreateable() && 
                    fields.get('ROI_Report_Order__c').getDescribe().isAccessible() && 
                    fields.get('case__c').getDescribe().isAccessible()){
                    Database.SaveResult dsr = database.insert(roiOrder, false, AccessLevel.USER_MODE);
                    if(dsr.isSuccess()){
                        currentsequenceid = dsr.getId();  
                    }
                }else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update ROI Report Order'));
                }
        }
        showroireport = true;
        showimprovisedroireport = false;
    }
    
    public void GenerateImprovisedROIDraft(){
         String order;    
         map<double,DIA_lead__c> orderNLeadMap = new map<double,DIA_lead__c>();
         list<integer> leadNumbers = new list<integer>();
          String leaditemnumbers;
        for(LeadRecord lr: leadRecords){  
           if(leaditemnumbers == Null){
               leaditemnumbers = String.valueof(lr.lead.item_number__c);
           }else{
               leaditemnumbers = leaditemnumbers+ ','+String.valueof(lr.lead.item_number__c);
           }
        }
        
        
       
        System.debug('leaditemnumbers...'+leaditemnumbers);
        if(currentsequenceid != Null){
            list<DIA_ROI_Report_Order__c> roiOrder = [Select Id, ROI_Report_Order__c, case__C from DIA_ROI_Report_Order__c WHERE Id=:currentsequenceid WITH SECURITY_ENFORCED];
            if(!roiOrder.isEmpty()){
                
                 roiOrder[0].ROI_Report_Order__c = leaditemnumbers;
                 Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_ROI_Report_Order__c');

                if(Schema.SobjectType.DIA_ROI_Report_Order__c.isUpdateable() && 
                    fields.get('ROI_Report_Order__c').getDescribe().isAccessible()){

                    List<Database.SaveResult> dsr = database.update(roiOrder, false, AccessLevel.USER_MODE);
                }else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update ROI Report Order'));
                }
            }
        }else{
            DIA_ROI_Report_Order__c roiOrder = new DIA_ROI_Report_Order__c();
            roiOrder.case__c = caseRecord.id;
            roiOrder.ROI_Report_Order__c = leaditemnumbers;
            Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_ROI_Report_Order__c');

                if(Schema.SobjectType.DIA_ROI_Report_Order__c.iscreateable() && 
                    fields.get('ROI_Report_Order__c').getDescribe().isAccessible() && 
                    fields.get('case__c').getDescribe().isAccessible()){
                    Database.SaveResult dsr = database.insert(roiOrder, false, AccessLevel.USER_MODE);
                    if(dsr.isSuccess()){
                        currentsequenceid = dsr.getId();  
                    }
                }else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update ROI Report Order'));
                }
        }
        showimprovisedroireport = true;
        showroireport = false;
    }
    
    public boolean showroireport {get;set;}
    public boolean showimprovisedroireport {get;set;}
}