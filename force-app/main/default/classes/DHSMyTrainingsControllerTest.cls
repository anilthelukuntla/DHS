@IsTest
/** Exercises the existing DHSMyTrainingsController behavior. */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
private class DHSMyTrainingsControllerTest {
    @IsTest
    static void loadsAndDeletesCurrentUsersTraining() {
        DHS_Training__c training = new DHS_Training__c(
            DHS_User__c = UserInfo.getUserId(),
            Training_Name__c = 'DHS test training'
        );
        insert training;

        DHSMyTrainingsController controller = new DHSMyTrainingsController();
        controller.deleteTrainingID = training.Id;
        controller.DeleteTrainingAction();

        System.assertEquals(0, [
            SELECT COUNT() FROM DHS_Training__c WHERE Id = :training.Id
        ], 'Assertion failed in DHSMyTrainingsControllerTest at source line 17');
    }

    @IsTest
    static void submitsNewTraining() {
        DHSMyTrainingsController controller = new DHSMyTrainingsController();
        controller.newTraining.Training_Name__c = 'Submitted DHS training';

        controller.SubmitTraining();

        System.assertEquals(1, [
            SELECT COUNT()
            FROM DHS_Training__c
            WHERE Training_Name__c = 'Submitted DHS training'
        ], 'Assertion failed in DHSMyTrainingsControllerTest at source line 29');
    }
}