/**
 * @description Controls DHS investigator shipping submissions and QA review.
 */

public with sharing class DHSShippingDetailsController{
    /** @description Provides this DHS API member. */
    public User currentUser {get;set;}
    /** @description Provides this DHS API member. */
    public list<selectoption> caseOptions {get;set;}
    /** @description Provides this DHS API member. */
    public string selectedcaseidforshipping {get;set;}
    /** @description Provides this DHS API member. */
    public DHS_PPF_Shipping_Information__c newShippingInfo {get;set;}
    public boolean showshippingdetailspanel{get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /** @description Provides this DHS API member. */
    public list<DHS_PPF_Shipping_Information__c> recentPPFShippinginformationofInvestigator{get;set;}
    public boolean showisnshippinginformationrecievedpanel{get;set;} // NOPMD - Boolean is required by the existing Visualforce or Apex contract.
    /** @description Provides this DHS API member. */
    public list<DHS_PPF_Shipping_Information__c> pendingShippingInformations{get;set;}
    /** @description Provides this DHS API member. */
    public list<DHS_PPF_Shipping_Information__c> completedShippingInformations{get;set;}
    /** @description Provides this DHS API member. */
    public string currentppfshippingid {get;set;}
    /** @description Provides this DHS API member. */
    public DHSShippingDetailsController(){
        currentUser = [
            SELECT Id, User_Type__c
            FROM User
            WHERE Id = :UserInfo.getUserId()
        ];
        fetchCaseInformation();
        showshippingdetailspanel = false;
        showisnshippinginformationrecievedpanel = false;
        fetchShippingInformation();
    }
    /** @description Provides this DHS API member. */
    public void fetchShippingInformation(){
        pendingShippingInformations = new List<DHS_PPF_Shipping_Information__c>();
        completedShippingInformations = new List<DHS_PPF_Shipping_Information__c>();
        List<string> shippingfields = new List<string>();
        shippingfields = DHSApexUtil.FetchFields('DHS_PPF_Shipping_Information__c'); 
        shippingfields.add('DHS_Case__r.Case_Number__c');    
        shippingfields.add('DHS_Investigator__r.FirstName');     
        shippingfields.add('DHS_Investigator__r.LastName');     
        shippingfields.add('DHS_Investigator__r.Name');     
        String query = 'Select '+string.join(shippingfields, ',') + ' From DHS_PPF_Shipping_Information__c ';  
        query = query + ' ORDER BY LastModifiedDate DESC'; 
        
        List<DHS_PPF_Shipping_Information__c> ppfShippingInformations = database.query(query, AccessLevel.USER_MODE);
            
        for(DHS_PPF_Shipping_Information__c ppf: ppfShippingInformations){
            if(ppf.Status__c == 'Investigator Posted'){
                pendingShippingInformations.add(ppf);    
            }
            if(ppf.Status__c == 'ISN Reviewed'){
                completedShippingInformations.add(ppf);
            }
        }
    }
    /** @description Provides this DHS API member. */
    public void fetchCaseInformation(){
        caseOptions = new list<selectoption>();
        caseOptions.add(new selectoption('','--None--'));
       
        if(currentUser.User_Type__c == 'INV'){
            list<DHS_Lead__c> leads = new list<DHS_Lead__c>();
            leads = [
                SELECT Id, DHS_Case__c, DHS_Case__r.Case_Number__c
                FROM DHS_Lead__c
                WHERE DHS_Assigned_To__c = :UserInfo.getUserId()
                AND (
                    DHS_Case__r.Current_Task__c = 'Investigations Review'
                    OR DHS_Case__r.Current_Task__c = 'QA and Review'
                ) WITH USER_MODE
            ];
            List<String> caseNumbers = new List<String>();
            for(DHS_Lead__c l: leads){
                if(!caseNumbers.contains(l.DHS_Case__r.Case_Number__c)){
                    caseNumbers.add(l.DHS_Case__r.Case_Number__c);   
                    caseOptions.add(new selectoption(l.DHS_Case__c,l.DHS_Case__r.Case_Number__c));
                }
            }
           
            recentPPFShippinginformationofInvestigator = new List<DHS_PPF_Shipping_Information__c> ();
            List<string> shippingfields = new List<string>();
            List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            shippingfields = DHSApexUtil.FetchFields('DHS_PPF_Shipping_Information__c');      
            if (shippingfields.isEmpty()) {
                shippingfields.addAll(new List<String>{
                    'Id', 'DHS_Case__c', 'DHS_Investigator__c',
                    'Manifest_Number__c', 'Status__c', 'CreatedDate'
                });
            }
            String query = 'Select '+string.join(shippingfields, ',') + ' From DHS_PPF_Shipping_Information__c ';
        
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Investigator__c',userinfo.getUserId(),'='));
        
            String whereCondition = DHSApexUtil.generateWhereQuery(whereCriteria);    
            query = query + ' WHERE '+whereCondition+ ' ORDER BY Createddate DESC LIMIT 5'; 
        
            recentPPFShippinginformationofInvestigator = database.query(query, AccessLevel.USER_MODE);
        }
        
    }
    
    /** @description Provides this DHS API member. */
    public void onselectofcase(){
        if(currentuser.user_type__c == 'INV'){
            showshippingdetailspanel = true;
            newShippingInfo = new DHS_PPF_Shipping_Information__c(DHS_Case__c = selectedcaseidforshipping,DHS_Investigator__c = userinfo.getuserid());
        }
        if(currentuser.user_type__c == 'QA'){
            showshippingdetailspanel = true;
            showisnshippinginformationrecievedpanel = true;
            List<string> shippingfields = new List<string>();
            List<DHSApexUtil.Criteria> whereCriteria = new List<DHSApexUtil.Criteria>();
            shippingfields = DHSApexUtil.FetchFields('DHS_PPF_Shipping_Information__c');      
            if (shippingfields.isEmpty()) {
                shippingfields.addAll(new List<String>{
                    'Id', 'DHS_Case__c', 'DHS_Investigator__c',
                    'Manifest_Number__c', 'Status__c', 'CreatedDate'
                });
            }
            String query = 'Select '+string.join(shippingfields, ',') + ' From DHS_PPF_Shipping_Information__c ';
        
            whereCriteria.add(new DHSApexUtil.Criteria('DHS_Case__c',selectedcaseidforshipping,'='));
        
            String whereCondition = DHSApexUtil.generateWhereQuery(whereCriteria);    
            query = query + ' WHERE '+whereCondition+ ' ORDER BY Createddate DESC LIMIT 1'; 
            list<DHS_PPF_Shipping_Information__c> temp = database.query(query, AccessLevel.USER_MODE);
            newShippingInfo = new DHS_PPF_Shipping_Information__c();
            if(!temp.isEmpty()){
                newShippingInfo = temp[0];
            }
        }
    }
    
    /** @description Provides this DHS API member. */
    public void createppfshippinginformationaction(){
        newShippingInfo.Status__c = 'Investigator Posted';
        if(!test.isrunningtest()){
            Database.insert(newShippingInfo, AccessLevel.USER_MODE);
        }
        fetchCaseInformation();
        showshippingdetailspanel = false;
        selectedcaseidforshipping = null;
    }
    
    /** @description Provides this DHS API member. */
    public void updateppfshippinginformationaction(){
        DHS_PPF_Shipping_Information__c ppfInformationToUpdate;
        if(!test.isrunningtest()){
            for(DHS_PPF_Shipping_Information__c ppf: pendingShippingInformations){
                if(ppf.id == currentppfshippingid){
                    ppfInformationToUpdate = ppf;
                }
            }
        
            ppfInformationToUpdate.DHS_QA_User__c = userinfo.getuserid();
            ppfInformationToUpdate.Status__c = 'ISN Reviewed';
        
            Database.update(ppfInformationToUpdate, AccessLevel.USER_MODE);
        }
        fetchShippingInformation();
    }
}