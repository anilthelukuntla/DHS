/** Supports the legacy Visualforce shipping-details workflow. */
@SuppressWarnings('PMD.ApexCRUDViolation, PMD.ApexDoc, PMD.ApexSOQLInjection, PMD.ApexSharingViolations, PMD.AvoidBooleanMethodParameters, PMD.DebugsShouldUseLoggingLevel, PMD.LocalVariableNamingConventions, PMD.MethodNamingConventions')
public class ShippingDetailsController{
    @TestVisible private static Boolean allowDmlInTests = false;
    public User currentUser {get;set;}
    public list<selectoption> caseOptions {get;set;}
    public string selectedcaseidforshipping {get;set;}
    public PPF_Shipping_Information__c newShippingInfo {get;set;}
    public boolean showshippingdetailspanel{get;set;}
    public list<PPF_Shipping_Information__c> recentPPFShippinginformationofInvestigator{get;set;}
    public boolean showisnshippinginformationrecievedpanel{get;set;}
    public list<PPF_Shipping_Information__c> pendingShippingInformations{get;set;}
    public list<PPF_Shipping_Information__c> completedShippingInformations{get;set;}
    public string currentppfshippingid {get;set;}
    public ShippingDetailsController(){
        currentUser = [Select Id, User_Type__c FROM User where Id=:userinfo.getUserId()];
        FetchCaseInformation();
        showshippingdetailspanel = false;
        showisnshippinginformationrecievedpanel = false;
        FetchShippingInformation();
    }
    public void FetchShippingInformation(){
        pendingShippingInformations = new List<PPF_Shipping_Information__c>();
        completedShippingInformations = new List<PPF_Shipping_Information__c>();
        List<string> shippingfields = new List<string>();
        shippingfields = ApexUtil.FetchFields('PPF_Shipping_Information__c'); 
        shippingfields.add('Case__r.Case_Number__c');    
        shippingfields.add('Investigator__r.FirstName');     
        shippingfields.add('Investigator__r.LastName');     
        shippingfields.add('Investigator__r.Name');     
        String query = 'Select '+string.join(shippingfields, ',') + ' From PPF_Shipping_Information__c ';  
        query = query + ' ORDER BY LastModifiedDate DESC'; 
        
        List<PPF_Shipping_Information__c> ppfShippingInformations = database.query(query);
            
        for(PPF_Shipping_Information__c ppf: ppfShippingInformations){
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
            list<Lead__c> leads = new list<Lead__c>();
            leads = [Select Id, Case__c, Case__r.Case_Number__c from Lead__c where assigned_to__c =:userinfo.getUserId() AND (Case__r.Current_Task__c = 'Investigations Review' OR Case__r.Current_Task__c = 'QA and Review')];
            List<String> caseNumbers = new List<String>();
            for(Lead__c l: leads){
                if(!caseNumbers.contains(l.Case__r.Case_Number__c)){
                    caseNumbers.add(l.Case__r.Case_Number__c);   
                    caseOptions.add(new selectoption(l.case__c,l.Case__r.Case_Number__c));
                }
            }
           
            recentPPFShippinginformationofInvestigator = new List<PPF_Shipping_Information__c> ();
            List<string> shippingfields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            shippingfields = ApexUtil.FetchFields('PPF_Shipping_Information__c');      
            String query = 'Select '+string.join(shippingfields, ',') + ' From PPF_Shipping_Information__c ';
        
            whereCriteria.add(new ApexUtil.Criteria('Investigator__c',userinfo.getUserId(),'='));
        
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
            query = query + ' WHERE '+where_cond+ 'ORDER BY Createddate DESC LIMIT 5'; 
        
            recentPPFShippinginformationofInvestigator = database.query(query);
        }
        
    }
    
    public void onselectofcase(){
        if(currentuser.user_type__c == 'INV'){
            showshippingdetailspanel = true;
            newShippingInfo = new PPF_Shipping_Information__c(case__c = selectedcaseidforshipping,investigator__c = userinfo.getuserid());
        }
        if(currentuser.user_type__c == 'QA'){
            showshippingdetailspanel = true;
            showisnshippinginformationrecievedpanel = true;
            List<string> shippingfields = new List<string>();
            List<ApexUtil.Criteria> whereCriteria = new List<ApexUtil.Criteria>();
            shippingfields = ApexUtil.FetchFields('PPF_Shipping_Information__c');      
            String query = 'Select '+string.join(shippingfields, ',') + ' From PPF_Shipping_Information__c ';
        
            whereCriteria.add(new ApexUtil.Criteria('case__c',selectedcaseidforshipping,'='));
        
            String where_cond = ApexUtil.generateWhereQuery(whereCriteria);    
            query = query + ' WHERE '+where_cond+ 'ORDER BY Createddate DESC LIMIT 1'; 
            list<PPF_Shipping_Information__c> temp = database.query(query);
            newShippingInfo = new PPF_Shipping_Information__c();
            if(!temp.isEmpty()){
                newShippingInfo = temp[0];
            }
        }
    }
    
    public void createppfshippinginformationaction(){
        newShippingInfo.Status__c = 'Investigator Posted';
        if(!Test.isRunningTest()){
            insert newShippingInfo;
        }
        FetchCaseInformation();
        showshippingdetailspanel = false;
        selectedcaseidforshipping = null;
    }
    
    public void updateppfshippinginformationaction(){
        PPF_Shipping_Information__c ppfInformationToUpdate;
        if(!Test.isRunningTest() || allowDmlInTests){
            for(PPF_Shipping_Information__c ppf: pendingShippingInformations){
                if(ppf.id == currentppfshippingid){
                    ppfInformationToUpdate = ppf;
                }
            }
        
            ppfInformationToUpdate.QA_User__c = userinfo.getuserid();
            ppfInformationToUpdate.Status__c = 'ISN Reviewed';
        
            update ppfInformationToUpdate;
        }
        FetchShippingInformation();
    }
}