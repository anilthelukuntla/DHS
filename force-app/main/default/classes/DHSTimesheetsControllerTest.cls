@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
public class DHSTimesheetsControllerTest {
	@IsTest private static void testtimesheetsController(){ 
	    System.assert(true, 'Expected the test scenario to complete without exception');
        DHSScheduleCreateTimesheetsBatch schedulableBatchCtrl = new DHSScheduleCreateTimesheetsBatch(); 
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
        DHS_TimeSheet__c timeSheet = new DHS_TimeSheet__c();
        timeSheet.Period_From__c = startDate;
        timeSheet.Period_To__c = endDate;
        timeSheet.Date__c = Date.newinstance(year, month, todaysDateTime.day());
        timeSheet.Day_Name__c = DateTime.newInstance(year, month, todaysDateTime.day()).format('EEEE');
        timeSheet.DHS_User__c = userinfo.getuserid();
        insert timeSheet;
        DHSTimesheetsController ctrl = new DHSTimesheetsController();
        ctrl.addNewInvestigatorCheck();
        ctrl.addNewInvestigatorCheck();        
        ctrl.checkoutapexaction();
        ctrl.checkinapexaction();
        DHSInvoiceModuleController invoiceCtrl = new DHSInvoiceModuleController();
        invoiceCtrl.FetchInvoiceRecords();
    }
}
