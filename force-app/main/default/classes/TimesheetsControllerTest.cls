@isTest
public class TimesheetsControllerTest {
	testMethod private static void TesttimesheetsController(){ 
        ScheduleCreateTimesheetsBatch schedulableBatchCtrl = new ScheduleCreateTimesheetsBatch(); 
        schedulableBatchCtrl.execute(null);
        DateTime todaysDateTime = System.now();
        Integer currentDayOfMonth = todaysDateTime.day();
        Integer month = Date.Today().Month();
        Integer year = Date.Today().Year();
        Integer numberDays = Date.daysInMonth(year, month);
        Date startDate;
        Date endDate;
        if(currentDayOfMonth >= 1 && currentDayOfMonth <= 15){
            startDate = Date.newinstance(year, month, 1);
            endDate = Date.newinstance(year, month, 15);
        }
        if(currentDayOfMonth >= 16){
            startDate = Date.newinstance(year, month, 16);
            endDate = Date.newinstance(year, month, numberDays);
        }
        TimeSheet__c timeSheet = new TimeSheet__c();
        timeSheet.Period_From__c = startDate;
        timeSheet.Period_to__c = endDate;
        timeSheet.Date__c = Date.newinstance(year, month, todaysDateTime.day());
        timeSheet.Day_Name__c = DateTime.newInstance(year, month, todaysDateTime.day()).format('EEEE');
        timeSheet.User__c = userinfo.getuserid();
        insert timeSheet;
        TimesheetsController ctrl = new TimesheetsController();
        ctrl.addNewInvestigatorCheck();
        ctrl.addNewInvestigatorCheck();        
        ctrl.checkoutapexaction();
        ctrl.checkinapexaction();
        InvoiceModuleController invoiceCtrl = new InvoiceModuleController();
        invoiceCtrl.FetchInvoiceRecords();
    }
}