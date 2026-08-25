public class DIAShippingDetailsController{
    public User currentUser {get;set;}
    public list<selectoption> caseOptions {get;set;}
    public string selectedcaseidforshipping {get;set;}
    public DIA_PPF_Shipping_Information__c newShippingInfo {get;set;}
    public boolean showshippingdetailspanel{get;set;}
    public list<DIA_PPF_Shipping_Information__c> recentPPFShippinginformationofInvestigator{get;set;}
    public boolean showisnshippinginformationrecievedpanel{get;set;}
    public list<DIA_PPF_Shipping_Information__c> pendingShippingInformations{get;set;}
    public list<DIA_PPF_Shipping_Information__c> completedShippingInformations{get;set;}
    public string currentppfshippingid {get;set;}
    public DIAShippingDetailsController(){
        currentUser = [Select Id, User_Type__c FROM User where Id=:userinfo.getUserId() WITH SECURITY_ENFORCED];
        FetchCaseInformation();
        showshippingdetailspanel = false;
        showisnshippinginformationrecievedpanel = false;
        FetchShippingInformation();
    }
    public void FetchShippingInformation(){
        pendingShippingInformations = new List<DIA_PPF_Shipping_Information__c>();
        completedShippingInformations = new List<DIA_PPF_Shipping_Information__c>();
        List<string> shippingfields = new List<string>();
        List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
        shippingfields = ApexUtil.FetchFields('DIA_PPF_Shipping_Information__c'); 
        shippingfields.add('Case__r.Case_Number__c');    
        shippingfields.add('Investigator__r.FirstName');     
        shippingfields.add('Investigator__r.LastName');     
        shippingfields.add('Investigator__r.Name');     
        String query = 'Select '+string.join(shippingfields, ',') + ' From DIA_PPF_Shipping_Information__c ';  
        query = query + ' ORDER BY LastModifiedDate DESC '; 
        
        List<DIA_PPF_Shipping_Information__c> ppfShippingInformations = database.query(query);
            
        List<String> caseNumbers = new List<String>();
        for(DIA_PPF_Shipping_Information__c ppf: ppfShippingInformations){
            if(ppf.status__c == 'Investigator Posted'){
                pendingShippingInformations.add(ppf);    
            }
            if(ppf.status__c == 'ISN Reviewed'){
                completedShippingInformations.add(ppf);
            }
        }
    }
    public void FetchCaseInformation(){
        caseOptions = new list<selectoption>();
        caseOptions.add(new selectoption('','--None--'));
       
        if(currentUser.User_Type__c == 'INV'){
            list<DIA_Lead__c> leads = new list<DIA_Lead__c>();
            leads = [Select Id, Case__c, Case__r.Case_Number__c from DIA_Lead__c where assigned_to__c =:userinfo.getUserId() AND (Case__r.Current_Task__c = 'Investigations Review' OR Case__r.Current_Task__c = 'QA and Review')];
            List<String> caseNumbers = new List<String>();
            for(DIA_Lead__c l: leads){
                if(!caseNumbers.contains(l.Case__r.Case_Number__c)){
                    caseNumbers.add(l.Case__r.Case_Number__c);   
                    caseOptions.add(new selectoption(l.case__c,l.Case__r.Case_Number__c));
                }
            }
           
            recentPPFShippinginformationofInvestigator = new List<DIA_PPF_Shipping_Information__c> ();
            List<string> shippingfields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            shippingfields = ApexUtil.FetchFields('DIA_PPF_Shipping_Information__c');      
            String query = 'Select '+string.join(shippingfields, ',') + ' From DIA_PPF_Shipping_Information__c ';
        
            whereCriteria.add(new ApexUtil.Criteria('Investigator__c',userinfo.getUserId(),'='));
        
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
            query = query + ' WHERE '+where_cond+ ' ORDER BY Createddate DESC LIMIT 5 '; 
        
            recentPPFShippinginformationofInvestigator = database.query(query);
        }
        
    }
    
    public void onselectofcase(){
        if(currentuser.user_type__c == 'INV'){
            showshippingdetailspanel = true;
            newShippingInfo = new DIA_PPF_Shipping_Information__c(case__c = selectedcaseidforshipping,investigator__c = userinfo.getuserid());
        }
        if(currentuser.user_type__c == 'QA'){
            showshippingdetailspanel = true;
            showisnshippinginformationrecievedpanel = true;
            System.debug('selectedcaseidforshipping..'+selectedcaseidforshipping);
            List<string> shippingfields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            shippingfields = ApexUtil.FetchFields('DIA_PPF_Shipping_Information__c');      
            String query = 'Select '+string.join(shippingfields, ',') + ' From DIA_PPF_Shipping_Information__c ';
        
            whereCriteria.add(new ApexUtil.Criteria('case__c',selectedcaseidforshipping,'='));
        
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
            query = query + ' WHERE '+where_cond+ ' ORDER BY Createddate DESC LIMIT 1 '; 
            list<DIA_PPF_Shipping_Information__c> temp = database.query(query);
            newShippingInfo = new DIA_PPF_Shipping_Information__c();
            if(!temp.isEmpty()){
                newShippingInfo = temp[0];
            }
        }
    }
    
    public void createppfshippinginformationaction(){
        newShippingInfo.Status__c = 'Investigator Posted';
        if(!test.isrunningtest()){
            Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_PPF_Shipping_Information__c');

            if(Schema.SobjectType.DIA_PPF_Shipping_Information__c.iscreateable() && 
                fields.get('Status__c').getDescribe().isAccessible()){

                Database.SaveResult dsr = database.insert(newShippingInfo, false, AccessLevel.USER_MODE);
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create PPF Shipping Information'));
            }
        }
        FetchCaseInformation();
        showshippingdetailspanel = false;
        selectedcaseidforshipping = null;
    }
    
    public void updateppfshippinginformationaction(){
        DIA_PPF_Shipping_Information__c ppfInformationToUpdate;
        System.debug('currentppfshippingid..'+currentppfshippingid);
        if(!test.isrunningtest()){
            for(DIA_PPF_Shipping_Information__c ppf: pendingShippingInformations){
                if(ppf.id == currentppfshippingid){
                    System.debug('ppf...'+ppf);
                    ppfInformationToUpdate = ppf;
                }
            }
        
            ppfInformationToUpdate.QA_User__c = userinfo.getuserid();
            ppfInformationToUpdate.Status__c = 'ISN Reviewed';
            Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_PPF_Shipping_Information__c');
            if(Schema.SobjectType.DIA_PPF_Shipping_Information__c.isUpdateable() && 
                fields.get('QA_User__c').getDescribe().isAccessible() &&
                fields.get('Status__c').getDescribe().isAccessible()){

                Database.SaveResult dsr = database.update(ppfInformationToUpdate, false, AccessLevel.USER_MODE);
            }else{
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to update User'));
            }
        }
        FetchShippingInformation();
    }
}