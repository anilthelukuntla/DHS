Public with sharing Class DIALeadTriggerHandler {
    public static void UpdatePricingOnLead(List<DIA_Lead__c> newLeads, Map<Id,DIA_Lead__c> oldLeadsMap){
    	List<BI_Pricing__mdt> biPricingMatrix = new List<BI_Pricing__mdt>();
     	biPricingMatrix = [select id, Lead_Type__c, Coverage_Type__c,Contact_Method__c ,Unable_to_Complete__c ,Price__c
                           FROM BI_Pricing__mdt];
        map<string,list<BI_Pricing__mdt>> leadTypeNpricingMatrix = new map<string,list<BI_Pricing__mdt>>();
        for(BI_Pricing__mdt bp: biPricingMatrix ){
            if(!leadTypeNpricingMatrix.containsKey(bp.Lead_Type__c)){
                leadTypeNpricingMatrix.put(bp.lead_type__c,new list<BI_Pricing__mdt>{bp});	    
            }else{
            	list<BI_Pricing__mdt> temp = leadTypeNpricingMatrix.get(bp.lead_type__c);
                temp.add(bp);
                leadTypeNpricingMatrix.put(bp.lead_type__c,temp);	    
            }   
        }
        for(DIA_Lead__c diaLead: newLeads){
            if(diaLead.status__c == 'Completed' && oldLeadsMap.get(dialead.id).status__c != 'Completed'){
                list<BI_Pricing__mdt> biPricings = new list<BI_Pricing__mdt>();
                biPricings = leadTypeNpricingMatrix.get(diaLead.leadtype__c);
                System.debug('biPricings...'+biPricings);
                if(biPricings != Null){
                    for(BI_Pricing__mdt bp:biPricings ){
                        if(diaLead.coverage_type__c == bp.coverage_type__c){
                            System.debug('bp...'+bp);
                            if(bp.contact_method__c != Null && bp.contact_method__c == dialead.personal_contact_method__c){
                                diaLead.price__c = bp.price__c;	
                                System.debug('inside this..');
                            }
                            if(bp.contact_method__c == Null){
                                diaLead.price__c = bp.price__c;    
                            }
                        }    
                    }
                }
            }  
            System.debug('diaLead.price__c...'+diaLead.price__c);
        }
    }
    public static void LeadAuditMethod(List<DIA_Lead__c> leadOldIds , List<DIA_Lead__c> LeadNewIds){
        List< DIA_Lead_Status_History__c > LSHList = New List< DIA_Lead_Status_History__c >();

        try
        {
             lisT<string> newLeadIds = new list<String>();
             For(DIA_Lead__c LN : LeadNewIds){
                 newLeadIds.add(ln.id);
             }
            list<DIA_Lead_Status_History__c> statusHistories = new list<DIA_Lead_Status_History__c>();
            statusHistories = [Select Id,Completed_By__c,lead__c FROM DIA_Lead_Status_History__c WHERE lead__c=:newLeadIds order by createddate desc];
            map<string,list<DIA_Lead_Status_History__c>> leadNstatushistorymap = new map<string,list<DIA_Lead_Status_History__c>>();
            for(DIA_Lead_Status_History__c temp: statusHistories){
                if(!leadNstatushistorymap.containsKey(temp.lead__c)){
                    leadNstatushistorymap.put((string)temp.lead__c,new list<DIA_Lead_Status_History__c>{temp});
                }else{
                    list<DIA_Lead_Status_History__c> temp2= leadNstatushistorymap.get(temp.lead__c);
                    temp2.add(temp);
                    leadNstatushistorymap.put((string)temp.lead__c,temp2);
                }
            }
                        
            For(DIA_Lead__c LO : leadOldIds)
            {
                For(DIA_Lead__c LN : LeadNewIds)
                {
                    System.debug('---LO.Last_Status_Change__c---'+LO.Last_Status_Change__c);
                    System.debug('---LN.Last_Status_Change__c---'+LN.Last_Status_Change__c);

                    IF((LO.Id == LN.Id) && (LO.Last_Status_Change__c != LN.Last_Status_Change__c))
                    {
                        list<DIA_Lead_Status_History__c> temp = new list<DIA_Lead_Status_History__c>();
                        if(leadNstatushistorymap.containsKey(ln.id)){
                            temp = leadNstatushistorymap.get(ln.id);
                        }
                        DIA_Lead_Status_History__c CSHVal = New DIA_Lead_Status_History__c();
                        if(!temp.isEmpty()){
                            CSHVal.initiated_By__c = temp[0].Completed_By__c;    
                        }else{
                            CSHVal.initiated_By__c = ln.createdbyid;
                        }
                        CSHVal.Completed_By__c = userinfo.getuserid();
                        CSHVal.Lead__C = LO.Id;
                        CSHVal.Status_Name__c = LO.Status__C;
                        CSHVal.Status_Start_Time__c = LO.Last_Status_Change__c;
                        CSHVal.Status_End_Time__c = LN.Last_Status_Change__c;
                        Long dt1Long = LO.Last_Status_Change__c.getTime();
                        Long dt2Long = LN.Last_Status_Change__c.getTime();
                        Long milliseconds = dt2Long - dt1Long;
                        Long seconds = milliseconds / 1000;
                        Long minutes = seconds / 60;
                        Long hours = minutes / 60;
                        Long days = hours / 24;
                        Long Subhours = (minutes - (days * 24 * 60)) / 60 ;
                        Long Submin = ((minutes - (days * 24 * 60)) - (Subhours * 60)) ;
                        CSHVal.Status_Duration__c = days + ' Days /  ' + Subhours + ' Hrs /  ' + Submin + ' Mins ';
                        LSHList.add(CSHVal);
                    }
                }
            }

            if(!LSHList.isEmpty()){
                Map<String, Schema.SObjectField> fields = ApexUtil.getObjectFieldsDescribe('DIA_Lead_Status_History__c');

                if(Schema.SobjectType.DIA_Lead_Status_History__c.iscreateable() && 
                    fields.get('initiated_By__c').getDescribe().isAccessible() && 
                    fields.get('Completed_By__c').getDescribe().isAccessible() &&
                    fields.get('Lead__C').getDescribe().isAccessible() &&
                    fields.get('Status_Name__c').getDescribe().isAccessible() &&
                    fields.get('Status_Start_Time__c').getDescribe().isAccessible() && 
                    fields.get('Status_End_Time__c').getDescribe().isAccessible()
                    ){

                    List<Database.SaveResult> dsr = database.insert(LSHList, false, AccessLevel.USER_MODE);
                }else{
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Insufficient access to create Lead Status History'));
                }
            }
        } Catch(Exception e){
        
        }       
    }
}