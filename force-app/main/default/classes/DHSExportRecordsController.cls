/** Starts the asynchronous DHS record export process. */
@SuppressWarnings('PMD.UnusedMethod')
public with sharing class DHSExportRecordsController {
    @TestVisible
    private static Boolean forceFailure = false;

    /**
     * Starts the export batch and returns an exception when startup fails.
     * @return Null on success, otherwise the exception raised during startup.
     */
    Public static object startBatch(){
        try{
            if (Test.isRunningTest() && forceFailure) {
                throw new ExportRecordsControllerException('Forced test failure');
            }
            DHSExportRecordsBatch exportRecordsBatch = New DHSExportRecordsBatch();
	        	database.executeBatch(exportRecordsBatch,2000);
            return null;
        }catch(exception e){
            return e;
        }
        
    }

    private class ExportRecordsControllerException extends Exception {}
}
